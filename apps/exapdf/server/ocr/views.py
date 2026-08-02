"""앱이 부르는 REST API.

응답은 전부 JSON. 앱에는 **DB 접속정보를 절대 내려보내지 않는다** —
앱은 이 API 만 부른다 (CLAUDE.md §2 규칙 3 · §8).
"""

import functools
import hashlib

from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST

from ocr import engine
from ocr.models import Job, Page

MAX_UPLOAD = 500 * 1024 * 1024  # 500MB. 스캔본은 크다


def token_required(view):
    """`Authorization: Bearer <API_TOKEN>`.

    토큰이 비어 있으면 **모두 거부한다.** 설정을 빠뜨렸을 때 열린 채로
    도는 것이 가장 나쁘다.
    """

    @functools.wraps(view)
    def wrapped(request, *args, **kwargs):
        expected = settings.OCR_API_TOKEN
        if not expected:
            return _err('서버에 API_TOKEN 이 설정되지 않았습니다', 503)
        got = request.headers.get('Authorization', '')
        if not got.startswith('Bearer ') or got[7:] != expected:
            return _err('토큰이 올바르지 않습니다', 401)
        return view(request, *args, **kwargs)

    return wrapped


def _err(message, status=400):
    return JsonResponse({'ok': False, 'error': message}, status=status,
                        json_dumps_params={'ensure_ascii': False})


def _ok(data, status=200):
    return JsonResponse({'ok': True, **data}, status=status,
                        json_dumps_params={'ensure_ascii': False})


@require_GET
def health(request):
    """토큰 없이 부를 수 있다. 앱이 서버가 살아 있는지 먼저 보는 곳."""
    endpoint = settings.OCR_ENDPOINT
    model = settings.OCR_MODEL
    ok, message = engine.probe(endpoint, model) if endpoint else (False, 'OCR_ENDPOINT 미설정')
    return _ok({
        'service': 'exapdf-ocr',
        'ollama': {'ok': ok, 'message': message, 'model': model},
        'queued': Job.objects.filter(status__in=[Job.QUEUED, Job.RENDERING, Job.OCR]).count(),
    })


@csrf_exempt
@require_POST
@token_required
def create_job(request):
    """PDF 를 올려 일감을 만든다 (multipart, 필드 이름 `file`).

    같은 파일을 다시 올리면 **새 일감을 만들지 않는다.** 앱을 지웠다 깔아도
    두 시간을 다시 기다릴 이유가 없다.
    """
    upload = request.FILES.get('file')
    if upload is None:
        return _err('file 이 없습니다')
    if upload.size > MAX_UPLOAD:
        return _err(f'파일이 너무 큽니다 (최대 {MAX_UPLOAD // (1024 * 1024)}MB)', 413)

    settings.OCR_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    digest = hashlib.sha256()
    tmp = settings.OCR_UPLOAD_DIR / '.upload.part'
    with open(tmp, 'wb') as f:
        for chunk in upload.chunks():
            digest.update(chunk)
            f.write(chunk)
    checksum = digest.hexdigest()

    existing = Job.objects.filter(checksum=checksum).exclude(status=Job.FAILED).first()
    if existing is not None:
        tmp.unlink(missing_ok=True)
        return _ok({'job': existing.as_dict(), 'reused': True})

    split = request.POST.get('split', '').lower() in ('1', 'true', 'yes')
    job = Job.objects.create(
        checksum=checksum,
        filename=(upload.name or 'book.pdf')[:255],
        size_bytes=upload.size,
        endpoint=settings.OCR_ENDPOINT,
        model=settings.OCR_MODEL,
        split_pages=split,
    )
    tmp.replace(settings.OCR_UPLOAD_DIR / f'{job.uuid}.pdf')
    return _ok({'job': job.as_dict(), 'reused': False}, status=201)


@require_GET
@token_required
def job_detail(request, uuid):
    job = Job.objects.filter(uuid=uuid).first()
    if job is None:
        return _err('그런 일감이 없습니다', 404)
    return _ok({'job': job.as_dict()})


@require_GET
@token_required
def job_pages(request, uuid):
    """읽은 글자를 가져간다. `?since=N` 이면 N 쪽 **다음부터**.

    앱은 받은 쪽까지만 기억하고 다음에 그 뒤를 달라고 하면 된다 —
    전체를 매번 내려받으면 500쪽짜리에서 낭비가 크다.
    """
    job = Job.objects.filter(uuid=uuid).first()
    if job is None:
        return _err('그런 일감이 없습니다', 404)
    try:
        since = int(request.GET.get('since', 0))
        limit = min(int(request.GET.get('limit', 50)), 200)
    except ValueError:
        return _err('since·limit 은 숫자여야 합니다')

    pages = (job.pages.filter(status=Page.DONE, page_no__gt=since)
             .order_by('page_no')[:limit])
    return _ok({
        'status': job.status,
        'page_count': job.page_count,
        'done_pages': job.done_pages,
        'pages': [{'page_no': p.page_no, 'text': p.text} for p in pages],
    })


@csrf_exempt
@require_POST
@token_required
def cancel_job(request, uuid):
    """멈춘다. **이미 읽은 쪽은 그대로 남는다** — 다시 시작하면 이어 간다."""
    job = Job.objects.filter(uuid=uuid).first()
    if job is None:
        return _err('그런 일감이 없습니다', 404)
    if job.status in (Job.DONE, Job.FAILED):
        return _ok({'job': job.as_dict()})
    job.status = Job.CANCELLED
    job.save(update_fields=['status', 'updated_at'])
    return _ok({'job': job.as_dict()})


@csrf_exempt
@require_POST
@token_required
def resume_job(request, uuid):
    """멈춘 일감을 다시 큐에 넣는다."""
    job = Job.objects.filter(uuid=uuid).first()
    if job is None:
        return _err('그런 일감이 없습니다', 404)
    job.status = Job.QUEUED
    job.last_error = ''
    job.worker_id = ''
    job.lease_expires_at = None
    job.save(update_fields=['status', 'last_error', 'worker_id',
                            'lease_expires_at', 'updated_at'])
    return _ok({'job': job.as_dict()})

"""일감을 하나씩 집어 글자로 바꾸는 워커.

    python manage.py ocr_worker

**한 쪽 끝날 때마다 DB 에 적는다.** 중간에 죽으면 남은 쪽부터 이어 돈다
(CLAUDE.md §2 규칙 7 · §8 체크포인트).

워커를 여러 개 띄워도 된다. 임차(lease) 로 일감 하나를 한 워커만 잡는다.
"""

import os
import signal
import socket
import time
import traceback
from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

import json
import tempfile

from ocr import engine
from ocr.models import Job, Page

# 이 시간 동안 소식이 없으면 죽은 것으로 보고 일감을 놓아 준다.
# 쪽 하나가 30초 안팎이니 넉넉히 잡는다 — 살아 있는데 뺏기면 두 워커가 같은 쪽을 읽는다
LEASE_MINUTES = 15

# 한 쪽을 몇 번까지 다시 해 볼지. 계속 실패하는 쪽 하나 때문에
# 책 전체가 멈추면 안 된다
MAX_ATTEMPTS = 3


class Command(BaseCommand):
    help = '대기 중인 OCR 일감을 처리한다'

    def add_arguments(self, parser):
        parser.add_argument('--once', action='store_true', help='일감 하나만 처리하고 끝낸다')
        parser.add_argument('--poll', type=int, default=5, help='일감이 없을 때 쉬는 초 (기본 5)')

    def handle(self, *args, **opts):
        self.worker_id = f'{socket.gethostname()}:{os.getpid()}'
        self.stop = False

        # Ctrl+C 를 받으면 **지금 쪽을 마치고** 멈춘다.
        # 중간에 끊으면 그 쪽만 다시 하면 되지만, 곱게 끝내는 편이 낫다
        signal.signal(signal.SIGINT, self._ask_stop)
        signal.signal(signal.SIGTERM, self._ask_stop)

        self.stdout.write(f'워커 시작 {self.worker_id}')
        while not self.stop:
            job = self._claim()
            if job is None:
                if opts['once']:
                    self.stdout.write('할 일이 없습니다')
                    return
                time.sleep(opts['poll'])
                continue
            self._run(job)
            if opts['once']:
                return
        self._release()
        self.stdout.write('워커 멈춤')

    def _ask_stop(self, *_):
        if self.stop:  # 두 번 누르면 즉시
            self._release()
            raise SystemExit(1)
        self.stop = True
        self.stdout.write('\n이 쪽을 마치고 멈춥니다. 한 번 더 누르면 즉시 중단')

    def _release(self):
        """잡고 있던 일감을 놓아 준다.

        안 놓으면 임차가 만료될 때까지(15분) 아무도 못 집는다. 서비스를
        다시 시작할 때마다 15분씩 멈춰 있는 셈이라, 고쳐 놓고도 안 도는
        것처럼 보인다.
        """
        try:
            Job.objects.filter(worker_id=self.worker_id).update(
                worker_id='', lease_expires_at=None
            )
        except Exception:  # noqa: BLE001 — 끝나는 길목이라 무엇도 막으면 안 된다
            pass

    def _claim(self):
        """일감 하나를 잡는다. 죽은 워커가 잡고 있던 것도 시간이 지나면 가져온다."""
        with transaction.atomic():
            qs = (
                Job.objects.select_for_update(skip_locked=True)
                .filter(status__in=[Job.QUEUED, Job.RENDERING, Job.OCR])
                .filter(models_q_free())
                .order_by('created_at')
            )
            job = qs.first()
            if job is None:
                return None
            job.worker_id = self.worker_id
            job.lease_expires_at = timezone.now() + timedelta(minutes=LEASE_MINUTES)
            job.save(update_fields=['worker_id', 'lease_expires_at', 'updated_at'])
            return job

    def _renew(self, job):
        job.lease_expires_at = timezone.now() + timedelta(minutes=LEASE_MINUTES)
        job.save(update_fields=['lease_expires_at', 'updated_at'])

    def _run(self, job):
        path = settings.OCR_UPLOAD_DIR / f'{job.uuid}.pdf'
        if not path.exists():
            self._fail(job, '올린 파일을 찾을 수 없습니다')
            return

        try:
            # 1) 쪽을 세고 체크포인트를 깔아 둔다 (한 번만)
            if job.page_count == 0:
                job.status = Job.RENDERING
                job.save(update_fields=['status', 'updated_at'])
                job.page_count = engine.count_pages(str(path))
                Page.objects.bulk_create(
                    [Page(job=job, page_no=n) for n in range(1, job.page_count + 1)],
                    ignore_conflicts=True,
                )
                job.save(update_fields=['page_count', 'updated_at'])
                self.stdout.write(f'{job.filename}: {job.page_count}쪽')

            # 2) 서버가 살아 있는지 먼저 본다.
            #    두 시간짜리 일을 걸어 놓고 첫 쪽에서 주소 오타로 실패하면 허무하다
            ok, message = engine.probe(job.endpoint, job.model)
            if not ok:
                self._fail(job, message)
                return

            job.status = Job.OCR
            job.save(update_fields=['status', 'updated_at'])

            # 3) 남은 쪽만 돈다 — 이미 끝낸 쪽은 건드리지 않는다
            while not self.stop:
                job.refresh_from_db()
                if job.status == Job.CANCELLED:
                    self.stdout.write(f'{job.filename}: 멈춤 요청')
                    return
                page = (
                    job.pages.filter(status=Page.PENDING, attempts__lt=MAX_ATTEMPTS)
                    .order_by('page_no')
                    .first()
                )
                if page is None:
                    break
                self._ocr_one(job, page, str(path))
                self._renew(job)

            if self.stop:
                return

            # 4) 마무리. 계속 실패한 쪽이 있어도 나머지는 쓸 수 있어야 한다
            failed = job.pages.filter(status=Page.FAILED).count()
            done = job.pages.filter(status=Page.DONE).count()
            job.status = Job.DONE
            job.last_error = '' if failed == 0 else f'{failed}쪽을 읽지 못했습니다'
            job.worker_id = ''
            job.lease_expires_at = None
            job.save(update_fields=['status', 'last_error', 'worker_id',
                                    'lease_expires_at', 'updated_at'])
            self.stdout.write(self.style.SUCCESS(f'{job.filename}: 끝 ({done}/{job.page_count}쪽)'))

        except Exception as e:  # noqa: BLE001 — 무엇이 터지든 일감을 붙든 채 죽으면 안 된다
            self._fail(job, f'{e}\n{traceback.format_exc(limit=3)}')

    def _ocr_one(self, job, page, path):
        page.attempts += 1
        page.save(update_fields=['attempts', 'updated_at'])
        started = time.time()
        backend = settings.OCR_BACKEND
        try:
            text = ''
            boxes = ''
            # 좌표는 PaddleOCR 만 준다. 찾은 낱말을 쪽 위에 칠하려면 필요하다
            if backend in ('paddle', 'both'):
                lines, paddle_text = self._paddle(path, page.page_no, job.split_pages)
                boxes = json.dumps([l.as_dict() for l in lines], ensure_ascii=False)
                text = paddle_text
            # 글자 품질은 비전 모델이 낫다 — 띄어쓰기가 살아 있다.
            # both 면 글자는 이쪽 것을 쓰고 좌표만 위에서 얻은 것을 쓴다
            if backend in ('ollama', 'both'):
                text = engine.ocr_page(
                    job.endpoint, job.model, path, page.page_no, job.split_pages
                )
        except engine.OcrError as e:
            page.last_error = str(e)
            if page.attempts >= MAX_ATTEMPTS:
                page.status = Page.FAILED
            page.save(update_fields=['status', 'last_error', 'updated_at'])
            self.stdout.write(self.style.WARNING(f'  {page.page_no}쪽 실패: {e}'))
            return
        except Exception as e:  # noqa: BLE001 — PaddleOCR 이 무엇을 던질지 모른다
            page.last_error = f'{type(e).__name__}: {e}'
            if page.attempts >= MAX_ATTEMPTS:
                page.status = Page.FAILED
            page.save(update_fields=['status', 'last_error', 'updated_at'])
            self.stdout.write(self.style.WARNING(f'  {page.page_no}쪽 실패: {e}'))
            return
        page.text = text
        page.boxes = boxes
        page.status = Page.DONE
        page.last_error = ''
        page.save(update_fields=['text', 'boxes', 'status', 'last_error', 'updated_at'])
        self.stdout.write(
            f'  {page.page_no}/{job.page_count}쪽 · {len(text)}자 · {time.time() - started:.1f}초'
        )

    def _paddle(self, pdf_path, page_no, split):
        """PaddleOCR 로 줄과 좌표를 읽는다.

        반쪽이 둘이면 **오른쪽 반쪽의 x 를 0.5 만큼 밀어** 쪽 전체 기준으로
        맞춘다. 안 그러면 오른쪽 글자가 왼쪽에 칠해진다.
        """
        from ocr import paddle_engine

        all_lines = []
        texts = []
        with tempfile.TemporaryDirectory() as tmp:
            files = engine.page_image_files(pdf_path, page_no, split, tmp)
            for idx, (img_path, w, h) in enumerate(files):
                lines = paddle_engine.read_lines(
                    img_path, w, h, device=settings.OCR_PADDLE_DEVICE
                )
                if split:
                    for l in lines:
                        l.x0 = l.x0 / 2 + (0.5 if idx == 1 else 0)
                        l.x1 = l.x1 / 2 + (0.5 if idx == 1 else 0)
                all_lines.extend(lines)
                texts.append(paddle_engine.lines_to_text(lines))
        return all_lines, '\n\n'.join(t for t in texts if t)

    def _fail(self, job, message):
        job.status = Job.FAILED
        job.last_error = message[:2000]
        job.worker_id = ''
        job.lease_expires_at = None
        job.save(update_fields=['status', 'last_error', 'worker_id',
                                'lease_expires_at', 'updated_at'])
        self.stdout.write(self.style.ERROR(f'{job.filename}: 실패 — {message.splitlines()[0]}'))


def models_q_free():
    """아무도 안 잡았거나, 잡은 워커가 죽은 일감."""
    from django.db.models import Q

    return Q(worker_id='') | Q(lease_expires_at__lt=timezone.now()) | Q(lease_expires_at=None)

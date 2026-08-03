import uuid as uuid_lib

from django.db import models
from django.utils import timezone


class Job(models.Model):
    """스캔본 한 권을 글자로 바꾸는 일감.

    상태머신은 CLAUDE.md §8 이 정한 대로다. 단계마다 산출물을 남겨
    중간에 죽어도 그 단계부터 재개한다.

        QUEUED → RENDERING → OCR → DONE
                              └──→ FAILED
    """

    QUEUED = 'QUEUED'
    RENDERING = 'RENDERING'
    OCR = 'OCR'
    DONE = 'DONE'
    FAILED = 'FAILED'
    CANCELLED = 'CANCELLED'
    STATUS = [
        (QUEUED, '대기'),
        (RENDERING, '쪽 세는 중'),
        (OCR, '글자 읽는 중'),
        (DONE, '끝'),
        (FAILED, '실패'),
        (CANCELLED, '멈춤'),
    ]

    uuid = models.UUIDField(default=uuid_lib.uuid4, unique=True, editable=False)

    # 같은 책을 다시 올렸는지 판정하는 기준. 파일 이름은 믿을 수 없다 —
    # 사람이 바꾸고, 기기마다 다르다
    checksum = models.CharField(max_length=64, db_index=True)
    filename = models.CharField(max_length=255)
    size_bytes = models.BigIntegerField(default=0)

    page_count = models.IntegerField(default=0)
    status = models.CharField(max_length=12, choices=STATUS, default=QUEUED, db_index=True)
    last_error = models.TextField(blank=True, default='')

    # 어느 서버·모델로 읽었는지. 나중에 결과를 의심할 때 근거가 된다
    endpoint = models.CharField(max_length=255, blank=True, default='')
    model = models.CharField(max_length=100, blank=True, default='')

    # 한 장에 두 쪽이 들어 있는 책인가. 반쪽씩 보내야 제대로 읽는다
    split_pages = models.BooleanField(default=False)

    # 죽은 워커가 잡은 일감을 자동으로 풀어 주는 장치.
    # 사람이 손대야 풀리는 잠금은 결국 아무도 안 푼다
    worker_id = models.CharField(max_length=64, blank=True, default='')
    lease_expires_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.filename} [{self.status}]'

    @property
    def done_pages(self):
        return self.pages.filter(status=Page.DONE).count()

    @property
    def is_lease_expired(self):
        return self.lease_expires_at is not None and self.lease_expires_at < timezone.now()

    def as_dict(self):
        return {
            'uuid': str(self.uuid),
            'filename': self.filename,
            'status': self.status,
            'page_count': self.page_count,
            'done_pages': self.done_pages,
            'model': self.model,
            'last_error': self.last_error,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
        }


class Page(models.Model):
    """쪽 하나 = 체크포인트 하나.

    한 쪽을 마칠 때마다 여기에 적는다. 워커가 죽어도 PENDING 인 쪽만
    다시 돌면 된다 — 두 시간짜리 일을 처음부터 다시 돌리지 않는다.
    """

    PENDING = 'PENDING'
    DONE = 'DONE'
    FAILED = 'FAILED'
    STATUS = [(PENDING, '대기'), (DONE, '끝'), (FAILED, '실패')]

    job = models.ForeignKey(Job, related_name='pages', on_delete=models.CASCADE)
    page_no = models.IntegerField()  # 1부터
    status = models.CharField(max_length=8, choices=STATUS, default=PENDING, db_index=True)
    text = models.TextField(blank=True, default='')

    # 줄마다 글자와 사각형 (JSON). 찾은 낱말을 쪽 위에 칠하는 데 쓴다.
    # 비전 모델만 쓰면 좌표가 없어 비어 있다
    boxes = models.TextField(blank=True, default='')
    attempts = models.IntegerField(default=0)
    last_error = models.TextField(blank=True, default='')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [('job', 'page_no')]
        ordering = ['page_no']
        indexes = [models.Index(fields=['job', 'status'])]

    def __str__(self):
        return f'{self.job_id}#{self.page_no} [{self.status}]'

"""순수 로직 위주로 검증한다 (CLAUDE.md §9).

서버를 실제로 부르지 않는다 — 모델이 덧붙이는 말을 걸러 내는 규칙과,
API 의 인증·체크포인트 동작이 핵심이다.
"""

import json
import uuid as uuid_lib

from django.test import Client, TestCase, override_settings

from ocr.engine import clean
from ocr.models import Job, Page

TOKEN = 'test-token-please-ignore'


class CleanTest(TestCase):
    """모델이 글자만 내놓지 않을 때가 있다 — 그대로 색인하면 검색이 더러워진다."""

    def test_코드펜스를_버린다(self):
        self.assertEqual(clean('```\n본문입니다\n```'), '본문입니다')

    def test_설명하는_말을_버린다(self):
        raw = '제목\n\n이 그림은 한국어 책의 한 쪽입니다. 보이는 글자는 다음과 같습니다:\n\n```\n```'
        self.assertEqual(clean(raw), '제목')

    def test_본문의_다음과_같습니다는_남긴다(self):
        # 콜론으로 끝나지 않으면 본문이다. 이것까지 지우면 책 내용이 사라진다
        raw = '그 이유는 다음과 같습니다. 첫째로 사람은 혼자일 때 불안합니다.'
        self.assertEqual(clean(raw), raw)

    def test_앞뒤_빈줄을_턴다(self):
        self.assertEqual(clean('\n\n본문\n\n'), '본문')

    def test_빈_응답도_견딘다(self):
        self.assertEqual(clean(''), '')


@override_settings(OCR_API_TOKEN=TOKEN, OCR_ENDPOINT='', OCR_MODEL='m')
class ApiTest(TestCase):
    def setUp(self):
        self.c = Client()
        self.auth = {'HTTP_AUTHORIZATION': f'Bearer {TOKEN}'}
        self.job = Job.objects.create(
            checksum='abc', filename='책.pdf', page_count=3, status=Job.OCR,
        )
        Page.objects.create(job=self.job, page_no=1, status=Page.DONE, text='첫 쪽')
        Page.objects.create(job=self.job, page_no=2, status=Page.DONE, text='둘째 쪽')
        Page.objects.create(job=self.job, page_no=3, status=Page.PENDING)

    def test_토큰이_없으면_거부한다(self):
        res = self.c.get(f'/api/jobs/{self.job.uuid}')
        self.assertEqual(res.status_code, 401)

    def test_토큰이_틀리면_거부한다(self):
        res = self.c.get(f'/api/jobs/{self.job.uuid}', HTTP_AUTHORIZATION='Bearer 아님')
        self.assertEqual(res.status_code, 401)

    @override_settings(OCR_API_TOKEN='')
    def test_서버에_토큰이_없으면_전부_막는다(self):
        # 설정을 빠뜨렸을 때 열린 채로 도는 것이 가장 나쁘다
        res = self.c.get(f'/api/jobs/{self.job.uuid}', **self.auth)
        self.assertEqual(res.status_code, 503)

    def test_진행률을_돌려준다(self):
        res = self.c.get(f'/api/jobs/{self.job.uuid}', **self.auth)
        body = json.loads(res.content)
        self.assertTrue(body['ok'])
        self.assertEqual(body['job']['done_pages'], 2)
        self.assertEqual(body['job']['page_count'], 3)

    def test_읽은_쪽만_내려준다(self):
        res = self.c.get(f'/api/jobs/{self.job.uuid}/pages', **self.auth)
        pages = json.loads(res.content)['pages']
        self.assertEqual([p['page_no'] for p in pages], [1, 2])

    def test_since_다음부터_준다(self):
        # 앱은 받은 데까지만 기억하고 그 뒤를 달라고 한다. 500쪽을 매번 받으면 낭비다
        res = self.c.get(f'/api/jobs/{self.job.uuid}/pages?since=1', **self.auth)
        pages = json.loads(res.content)['pages']
        self.assertEqual([p['page_no'] for p in pages], [2])

    def test_없는_일감은_404(self):
        res = self.c.get(f'/api/jobs/{uuid_lib.uuid4()}', **self.auth)
        self.assertEqual(res.status_code, 404)

    def test_멈춰도_읽은_쪽은_남는다(self):
        res = self.c.post(f'/api/jobs/{self.job.uuid}/cancel', **self.auth)
        self.assertEqual(res.status_code, 200)
        self.job.refresh_from_db()
        self.assertEqual(self.job.status, Job.CANCELLED)
        self.assertEqual(self.job.done_pages, 2)

    def test_다시_시작하면_남은_쪽부터(self):
        self.c.post(f'/api/jobs/{self.job.uuid}/cancel', **self.auth)
        self.c.post(f'/api/jobs/{self.job.uuid}/resume', **self.auth)
        self.job.refresh_from_db()
        self.assertEqual(self.job.status, Job.QUEUED)
        # 이미 끝낸 쪽은 그대로다 — 두 시간을 다시 기다리지 않는다
        self.assertEqual(self.job.pages.filter(status=Page.PENDING).count(), 1)

    def test_health_는_토큰이_필요없다(self):
        res = self.c.get('/api/health')
        self.assertEqual(res.status_code, 200)
        self.assertTrue(json.loads(res.content)['ok'])

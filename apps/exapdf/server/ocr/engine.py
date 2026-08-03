"""쪽 그림을 만들고, 글자로 바꾼다.

여기 담긴 수치는 전부 실측에서 나왔다 — `docs/engine-verification.md` 의
"OCR 실측" 절. 짐작으로 고른 값이 하나도 없으니 바꿀 때도 재고 나서 바꾼다.
"""

import base64
import io
import json
import urllib.error
import urllib.request

import pypdfium2 as pdfium
from PIL import Image

# 보낼 그림의 폭(px).
# 1386px→900px 로 줄이자 87초가 34초가 되었고 **글자는 100% 같았다.**
# 700px 아래로는 모델의 타일 격자 때문에 더 빨라지지 않는다.
SEND_WIDTH = 900

# 반쪽 한 장에 넉넉한 값. 올리지 않으면 기본값에서 잘린다
MAX_TOKENS = 2500

# 그리는 배율. 72dpi 기준이라 2.0 이면 144dpi 쯤 — 줄이기 전 원본으로 충분하다
RENDER_SCALE = 2.0

PROMPT = (
    '이 그림은 한국어 책의 한 쪽입니다. 보이는 글자를 그대로 옮겨 적으세요. '
    '설명하거나 요약하지 말고 원문 글자만 출력합니다.'
)


class OcrError(Exception):
    pass


def page_images(pdf_path: str, page_no: int, split: bool) -> list[bytes]:
    """쪽 하나를 JPEG 로. [split] 이면 좌·우 반쪽 두 장으로 나눈다.

    나누는 이유 — 펼침면을 통째로 보냈더니 모델이 34자만 내놓고 멈췄다.
    반쪽으로 자르니 끝까지 정상으로 나왔다 (engine-verification 의 함정).
    """
    doc = pdfium.PdfDocument(pdf_path)
    try:
        page = doc[page_no - 1]
        pil = page.render(scale=RENDER_SCALE).to_pil().convert('RGB')
    finally:
        doc.close()

    parts = []
    if split:
        w, h = pil.size
        parts = [pil.crop((0, 0, w // 2, h)), pil.crop((w // 2, 0, w, h))]
    else:
        parts = [pil]

    out = []
    for part in parts:
        if part.width > SEND_WIDTH:
            ratio = SEND_WIDTH / part.width
            part = part.resize((SEND_WIDTH, int(part.height * ratio)), Image.LANCZOS)
        buf = io.BytesIO()
        part.save(buf, 'JPEG', quality=90)
        out.append(buf.getvalue())
    return out


# 모델이 글자만 내놓지 않고 말을 얹을 때가 있다 — 특히 표지처럼 글이 적은 쪽에서
# "보이는 글자는 다음과 같습니다:" 를 덧붙이거나 코드펜스로 감싼다.
# 실측에서 본문 쪽은 깨끗했지만 표지에서 걸렸다. 걸러 내지 않으면 검색 색인이 더러워진다
_CHATTER = (
    '보이는 글자',
    '다음과 같습니다',
    '이 그림은',
    '이미지에',
    '한국어 책의 한 쪽',
)


def clean(text: str) -> str:
    """모델이 덧붙인 말과 코드펜스를 걷어 낸다."""
    lines = []
    for raw in text.splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        # 코드펜스는 통째로 버린다. 원문에 ``` 가 있을 리 없다
        if stripped.startswith('```'):
            continue
        # 설명하는 말이면서 문장이 콜론으로 끝나면 거의 확실히 모델의 말이다.
        # 본문에도 "다음과 같습니다" 가 나올 수 있으므로 콜론 조건을 함께 본다
        if stripped.endswith((':', '：')) and any(c in stripped for c in _CHATTER):
            continue
        lines.append(line)
    # 앞뒤 빈 줄 정리
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return '\n'.join(lines)


def read_image(endpoint: str, model: str, jpeg: bytes, timeout: int = 600) -> str:
    """그림 한 장을 글자로. Ollama `/api/generate`."""
    payload = {
        'model': model,
        'prompt': PROMPT,
        'images': [base64.b64encode(jpeg).decode()],
        'stream': False,
        # 온도를 0 으로. 글자를 옮겨 적는 일에 창의성은 해롭다
        'options': {'temperature': 0, 'num_predict': MAX_TOKENS},
    }
    req = urllib.request.Request(
        f'{endpoint.rstrip("/")}/api/generate',
        data=json.dumps(payload).encode(),
        headers={'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            body = json.load(res)
    except urllib.error.HTTPError as e:
        raise OcrError(f'서버가 {e.code} 로 답했습니다: {e.read()[:200].decode(errors="replace")}')
    except OSError as e:
        raise OcrError(f'서버에 닿지 못했습니다: {e}')
    return clean((body.get('response') or '').strip())


def page_image_files(pdf_path: str, page_no: int, split: bool, out_dir) -> list[tuple[str, int, int]]:
    """쪽 그림을 파일로 떨어뜨린다. PaddleOCR 은 바이트가 아니라 경로를 받는다.

    돌려주는 것은 (경로, 폭, 높이) — 좌표를 0~1 로 정규화하려면 크기가 필요하다
    """
    out = []
    for i, jpeg in enumerate(page_images(pdf_path, page_no, split)):
        path = f'{out_dir}/p{page_no}_{i}.jpg'
        with open(path, 'wb') as f:
            f.write(jpeg)
        with Image.open(path) as im:
            out.append((path, im.width, im.height))
    return out


def ocr_page(endpoint: str, model: str, pdf_path: str, page_no: int, split: bool) -> str:
    """쪽 하나를 글자로. 반쪽이 둘이면 이어 붙인다."""
    parts = []
    for jpeg in page_images(pdf_path, page_no, split):
        text = read_image(endpoint, model, jpeg)
        if text:
            parts.append(text)
    # 반쪽 둘은 이어지는 글이지만, 쪽이 바뀌는 자리는 문단 경계로 보는 것이 안전하다
    return '\n\n'.join(parts)


def probe(endpoint: str, model: str) -> tuple[bool, str]:
    """서버가 살아 있고 그 모델이 있는지. 시작하기 전에 확인한다."""
    try:
        req = urllib.request.Request(f'{endpoint.rstrip("/")}/api/tags')
        with urllib.request.urlopen(req, timeout=8) as res:
            body = json.load(res)
    except OSError as e:
        return False, f'서버에 닿지 못했습니다: {e}'
    names = [m['name'] for m in body.get('models', [])]
    if not names:
        return False, '서버에 모델이 없습니다'
    if model not in names:
        return False, f'{model} 이(가) 없습니다. 있는 것: {", ".join(names)}'
    return True, f'모델 {len(names)}개'


def count_pages(pdf_path: str) -> int:
    doc = pdfium.PdfDocument(pdf_path)
    try:
        return len(doc)
    finally:
        doc.close()

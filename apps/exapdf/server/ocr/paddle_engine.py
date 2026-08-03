"""PaddleOCR — 글자와 **좌표**를 함께 읽는다.

비전 모델(Ollama)은 글자만 준다. 그래서 찾은 낱말을 쪽 위에 칠할 수가 없었다.
PaddleOCR 은 줄마다 사각형을 주므로 그 자리를 칠할 수 있다.

실측 (2026-08-03, 192.168.219.88 · 반쪽 1332×1434):

| 방식 | 걸린 시간 |
|---|---|
| CPU | 36.7초 |
| **GPU** | **0.8초** |
| 참고 — Ollama 비전 모델(GPU) | 6초 |

**GPU 가 아니면 쓸 이유가 없다.** CPU 로는 비전 모델보다 6배 느리다.

대가: 한국어 띄어쓰기가 뭉개진다 (`고통을 짐작할 수있습니다.죄를`).
검색은 어차피 띄어쓰기를 지우고 맞추므로 지장이 없지만(ADR-0003),
복사해서 쓸 때는 비전 모델 쪽이 낫다. 그래서 둘을 함께 쓰는 길을 남겨 둔다.

라이선스: PaddleOCR·PaddlePaddle 모두 Apache-2.0. AGPL 이 아니다
(앱 CLAUDE.md 절대 규칙 1).
"""

import threading

_lock = threading.Lock()
_ocr = None


def _engine(device: str = 'gpu'):
    """모델은 한 번만 올린다.

    올리는 데만 2초가 걸린다 — 쪽마다 올리면 인식(0.8초)보다 오래 걸린다.
    워커는 오래 사는 프로세스라 한 번 올려 두고 계속 쓴다.
    """
    global _ocr
    with _lock:
        if _ocr is None:
            from paddleocr import PaddleOCR

            _ocr = PaddleOCR(
                lang='korean',
                # 쪽을 통째로 넣는 것이 아니라 이미 반듯한 반쪽을 넣으므로
                # 방향 판정·휘어짐 보정은 필요 없다. 켜면 느려지기만 한다
                use_doc_orientation_classify=False,
                use_doc_unwarping=False,
                use_textline_orientation=False,
                # paddle 3.3.1 의 oneDNN 경로에서 예외가 난다
                enable_mkldnn=False,
                device=device,
            )
    return _ocr


class Line:
    """읽은 줄 하나와 그 자리.

    좌표는 **0~1 로 정규화**한다. 그림 크기가 달라져도 그대로 쓸 수 있고,
    앱이 어떤 배율로 그리든 곱하기만 하면 된다.
    """

    __slots__ = ('text', 'x0', 'y0', 'x1', 'y1', 'score')

    def __init__(self, text, x0, y0, x1, y1, score):
        self.text = text
        self.x0, self.y0, self.x1, self.y1 = x0, y0, x1, y1
        self.score = score

    def as_dict(self):
        return {
            'text': self.text,
            'box': [round(self.x0, 5), round(self.y0, 5),
                    round(self.x1, 5), round(self.y1, 5)],
            'score': round(self.score, 3),
        }


def read_lines(jpeg_path: str, width: int, height: int, device: str = 'gpu') -> list[Line]:
    """그림 한 장에서 줄과 좌표를 읽는다."""
    result = _engine(device).predict(jpeg_path)
    if not result:
        return []
    r = result[0]
    lines = []
    for text, score, poly in zip(r['rec_texts'], r['rec_scores'], r['rec_polys']):
        if not text.strip():
            continue
        xs = [float(p[0]) for p in poly]
        ys = [float(p[1]) for p in poly]
        lines.append(
            Line(
                text=text,
                x0=min(xs) / width,
                y0=min(ys) / height,
                x1=max(xs) / width,
                y1=max(ys) / height,
                score=float(score),
            )
        )
    return lines


def lines_to_text(lines: list[Line]) -> str:
    """줄들을 한 덩이 글로. 읽은 순서를 그대로 지킨다"""
    return '\n'.join(l.text for l in lines)

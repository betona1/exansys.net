#!/usr/bin/env python3
"""ExaPDF(ExaPDF) 앱 아이콘 생성 — 마스코트 비비(바브바브 1단계).

비비가 펼친 책 너머로 빼꼼 내다보는 구도. 작은 크기(48dp)에서도
'캐릭터 + 읽기'가 한눈에 읽히도록 요소를 셋(배경·얼굴·책)으로 제한한다.

원본 `vavevave/바브바브01.png` 에서 얼굴만 따낸다. 원본에는 생각풍선과
물음표가 함께 그려져 있는데, 아이콘에서는 잡음이라 잘라 낸다.

  design/icon.png             1024 풀블리드 (Play 스토어·데스크톱용)
  design/icon_foreground.png  안드로이드 어댑티브 전경 (세이프존 66%)
  design/icon_512.png         Play Console 등록용

4배 슈퍼샘플 후 축소로 안티앨리어싱.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, "apps", "exapdf", "design")
MASCOT_SRC = os.path.join(ROOT, "vavevave", "바브바브01.png")
SS = 4

# ExaPDF 색 — 사이트 브랜드(딥네이비 + 시안)를 따른다
NAVY_HI = (23, 62, 107)
NAVY_LO = (7, 15, 27)
CYAN = (34, 184, 255)
PAPER = (250, 252, 255)
PAPER_EDGE = (206, 222, 240)
PAPER_LINE = (198, 214, 234)

# 원본(1254px)에서 얼굴을 따낼 영역
FACE_BOX = (225, 150, 912, 706)   # 머리 + 귀 + 앞머리 (턱 아래는 책이 가린다)
HEAD_SEED = (560, 450)            # 머리 한가운데 — 여기서 연결된 덩어리만 남긴다


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size, c1, c2):
    """대각 그라데이션"""
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t_y = y / h
        for x in range(0, w, 4):
            c = lerp(c1, c2, (x / w + t_y) / 2)
            for dx in range(min(4, w - x)):
                px[x + dx, y] = c
    return img


def glow(size, center, radius, color, strength=1.0):
    """가운데가 밝은 원형 발광 (RGBA)"""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 26
    for i in range(steps, 0, -1):
        r = radius * i / steps
        a = int(255 * strength * (1 - i / steps) ** 2 * 0.5)
        d.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=color + (a,))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.08))


def keep_component(alpha, seed, threshold=150, feather=4):
    """seed 에서 이어진 덩어리만 남기고 나머지 알파를 0 으로 만든다.

    낮은 임계값으로 이으면 캐릭터 주변의 옅은 발광이 다리 역할을 해서
    말풍선까지 한 덩어리가 된다. 그래서 **진한 픽셀로만** 연결을 판정하고,
    구한 덩어리를 feather 만큼 부풀린 뒤 원래 알파와 곱해 부드러운
    가장자리(털 끝)를 되살린다.
    """
    w, h = alpha.size
    src = alpha.load()
    solid = Image.new("L", (w, h), 0)
    dst = solid.load()
    if src[seed] <= threshold:
        raise ValueError(f"씨앗 {seed} 가 배경이다 — 좌표를 확인할 것")

    stack = [seed]
    dst[seed] = 255
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and dst[nx, ny] == 0 and src[nx, ny] > threshold:
                dst[nx, ny] = 255
                stack.append((nx, ny))

    mask = solid.filter(ImageFilter.MaxFilter(feather * 2 + 1))
    return Image.composite(alpha, Image.new("L", (w, h), 0), mask)


def cutout_face():
    """원본에서 배경을 빼고 얼굴만 따낸다.

    후드(46,49,74)가 배경(41,49,71)과 색이 거의 같아 단순 임계값으로는 못 뗀다.
    행마다 좌우 가장자리에서 배경색을 추정한 뒤 거리로 알파를 만든다.
    """
    src = Image.open(MASCOT_SRC).convert("RGB")
    w, h = src.size
    px = src.load()
    edge = max(8, w // 50)

    alpha = Image.new("L", (w, h), 0)
    ap = alpha.load()
    for y in range(h):
        acc = [0, 0, 0]
        n = 0
        for x in list(range(edge)) + list(range(w - edge, w)):
            c = px[x, y]
            acc[0] += c[0]; acc[1] += c[1]; acc[2] += c[2]
            n += 1
        br, bg_, bb = (v / n for v in acc)
        for x in range(w):
            r, g, b = px[x, y]
            dist = math.sqrt((r - br) ** 2 + (g - bg_) ** 2 + (b - bb) ** 2)
            a = (dist - 12) / 20
            ap[x, y] = 0 if a <= 0 else (255 if a >= 1 else int(a * 255))

    # 생각풍선·물음표 지우기.
    #
    # 상자로 자르면 머리카락까지 물어 사각형 자국이 남는다. 이것들은 머리와
    # 떨어져 있는 별개 덩어리이므로, 머리에서 시작해 이어진 부분만 남긴다.
    alpha = keep_component(alpha, HEAD_SEED)
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))

    out = src.convert("RGBA")
    out.putalpha(alpha)
    return out.crop(FACE_BOX)


def draw_book(draw, N, cx, y_top, w, h):
    """펼친 책. 가운데 책등이 아래로 처지고 양쪽 페이지가 위로 벌어진 모양."""
    left, right = cx - w / 2, cx + w / 2
    spine_top = y_top + h * 0.16
    spine_bot = y_top + h * 0.90
    edge_top = y_top
    edge_bot = y_top + h * 0.74
    thick = h * 0.11

    for sign in (-1, 1):
        outer = cx + sign * w / 2
        draw.polygon([(cx, spine_top), (outer, edge_top), (outer, edge_bot), (cx, spine_bot)], fill=PAPER)
        draw.polygon(
            [(cx, spine_bot), (outer, edge_bot), (outer, edge_bot + thick), (cx, spine_bot + thick)],
            fill=PAPER_EDGE,
        )

    lw = max(2, int(N * 0.010))
    for i in range(4):
        t = 0.28 + i * 0.16
        y_in = spine_top + (spine_bot - spine_top) * t
        y_out = edge_top + (edge_bot - edge_top) * t
        inset = w * (0.06 + i * 0.010)
        for sign in (-1, 1):
            draw.line(
                [(cx + sign * w * 0.045, y_in), (cx + sign * (w / 2 - inset), y_out)],
                fill=PAPER_LINE, width=lw,
            )

    draw.line([(cx, spine_top), (cx, spine_bot + thick)], fill=PAPER_EDGE, width=max(2, int(N * 0.011)))
    _ = left, right


def place_face(layer, N, width_ratio, y_ratio):
    face = _face_cache.get("f")
    if face is None:
        face = cutout_face()
        _face_cache["f"] = face
    tw = int(N * width_ratio)
    scaled = face.resize((tw, int(face.height * tw / face.width)), Image.LANCZOS)
    layer.alpha_composite(scaled, ((N - tw) // 2, int(N * y_ratio)))


_face_cache = {}


def build(face_w, face_y, book_y, book_w, book_h, with_bg=True):
    """아이콘 한 장을 만든다. with_bg=False 면 어댑티브 전경용(투명)."""
    N = 1024 * SS
    if with_bg:
        img = gradient((N, N), NAVY_HI, NAVY_LO).convert("RGBA")
        img.alpha_composite(glow((N, N), (N * 0.5, N * 0.40), N * 0.50, CYAN, 0.7))
    else:
        img = Image.new("RGBA", (N, N), (0, 0, 0, 0))

    # 얼굴 뒤 은은한 시안 림라이트 — 흰 책과 흰 털이 붙어 보이지 않게 띄운다
    img.alpha_composite(glow((N, N), (N * 0.5, N * (face_y + 0.24)), N * 0.34, CYAN, 0.55))

    face_layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    place_face(face_layer, N, face_w, face_y)
    img.alpha_composite(face_layer)

    # 책 아래 그림자 → 책
    shadow = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse(
        [N * 0.12, N * (book_y + book_h * 0.75), N * 0.88, N * (book_y + book_h * 1.15)],
        fill=(0, 0, 0, 110),
    )
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(N * 0.018)))

    book_layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw_book(ImageDraw.Draw(book_layer), N, N / 2, N * book_y, N * book_w, N * book_h)
    img.alpha_composite(book_layer)
    return img


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)

    full = build(face_w=0.70, face_y=0.115, book_y=0.615, book_w=0.88, book_h=0.245)
    icon = full.convert("RGB").resize((1024, 1024), Image.LANCZOS)
    icon.save(os.path.join(OUT, "icon.png"))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon_512.png"))

    # 어댑티브 전경.
    #
    # flutter_launcher_icons 가 만든 ic_launcher.xml 은 전경에 16% 인셋을 붙인다
    # (내용이 0.68 배로 줄어든다). 그래서 여기서 미리 줄이면 두 번 줄어 작아진다.
    # 풀블리드와 같은 크기로 두고, 그 인셋이 곧 세이프존이 되게 맞춘다.
    fg = build(face_w=0.70, face_y=0.115, book_y=0.615, book_w=0.88, book_h=0.245, with_bg=False)
    fg.resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, "icon_foreground.png"))

    # 어댑티브 배경 — 단색 그라데이션만
    N = 1024 * SS
    bg = gradient((N, N), NAVY_HI, NAVY_LO).convert("RGBA")
    bg.alpha_composite(glow((N, N), (N * 0.5, N * 0.42), N * 0.55, CYAN, 0.7))
    bg.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, "icon_background.png"))

    print("아이콘 생성 완료:", OUT)

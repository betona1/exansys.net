#!/usr/bin/env python3
"""ExaPDF 앱 아이콘 — BRAND.md 의 캐릭터 EXA(ExaPDF 변형) 기준.

`assets/brand/svg/appicon-exapdf.svg` 를 그대로 래스터화한다. SVG 렌더러를
끌어오지 않고 BRAND.md §2.2 의 64×64 그리드 수치로 직접 그린다.
수치를 바꾸면 EXA 가 아니게 되므로(BRAND.md §8) 여기 상수는 임의로 손대지 않는다.

    바디(스퀘어클)   x=0  y=0   w=64 h=64  rx=14   ← 앱 타일(풀블리드)
    바이저(렌즈 슬롯) x=13 y=26  w=38 h=12  rx=6
    동공(신호)        cx=32 cy=32 r=4.5           ← ExaPDF는 앰버
    책 힌트          (20,46)-(32,41)-(44,46) + 책등 (32,41)-(32,47)

산출물 (design/brand/):
    icon.png              1024 풀블리드 (iOS·데스크톱·스토어)
    icon_512.png          Play Console 등록용
    icon_background.png   안드로이드 어댑티브 배경 — ink 단색 (BRAND.md §6.1)
    icon_foreground.png   안드로이드 어댑티브 전경 — 바이저+동공+책힌트

4배 슈퍼샘플 후 축소로 안티앨리어싱.
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, "apps", "exapdf", "design", "brand")
SS = 4
N = 1024 * SS

# BRAND.md §3 색 토큰
INK = (0x0D, 0x11, 0x17)
SLOT = (0x15, 0x1A, 0x22)
AMBER = (0xFF, 0xC2, 0x4B)

# flutter_launcher_icons 가 만드는 ic_launcher.xml 은 전경에 16% 인셋을 넣는다.
# 전경을 그리드 그대로 그리면 그만큼 작아지므로 미리 키워 두었다가 인셋으로 되돌린다.
FG_INSET = 0.16
FG_SCALE = 1 / (1 - FG_INSET * 2)


def grid(v):
    """64 그리드 좌표 → 픽셀"""
    return v * N / 64


def draw_visor_and_pupil(d, s=1.0, cx=32.0, cy=32.0):
    """바이저·동공. s 는 그리드 배율, (cx,cy) 는 확대 중심."""

    def P(x, y):
        return (grid(cx + (x - cx) * s), grid(cy + (y - cy) * s))

    # 바이저 — 모서리 rx=6 인 둥근 사각
    d.rounded_rectangle([P(13, 26), P(51, 38)], radius=grid(6 * s), fill=SLOT)
    # 동공 — 상태를 나타내는 유일한 요소 (idle = 정중앙)
    d.ellipse([P(32 - 4.5, 32 - 4.5), P(32 + 4.5, 32 + 4.5)], fill=AMBER)


def draw_book_hint(layer, s=1.0, cx=32.0, cy=32.0):
    """하단 펼친 책 실루엣 — ExaPDF 제품 변형의 글리프 (BRAND.md §2.4).

    앰버 55% 불투명이라 별도 레이어에 그린 뒤 합성한다.
    """
    d = ImageDraw.Draw(layer)

    def P(x, y):
        return (grid(cx + (x - cx) * s), grid(cy + (y - cy) * s))

    w = grid(2.6 * s)
    color = AMBER + (int(255 * 0.55),)
    for a, b in [((20, 46), (32, 41)), ((32, 41), (44, 46)), ((32, 41), (32, 47))]:
        d.line([P(*a), P(*b)], fill=color, width=round(w))
    # PIL 은 둥근 캡이 없다 — 끝점에 원을 얹어 흉내낸다
    for pt in [(20, 46), (32, 41), (44, 46), (32, 47)]:
        x, y = P(*pt)
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=color)


def full_bleed():
    """풀블리드 아이콘 — 바디 + 바이저 + 동공 + 책 힌트."""
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, N - 1, N - 1], radius=grid(14), fill=INK)
    draw_visor_and_pupil(d)
    hint = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw_book_hint(hint)
    img.alpha_composite(hint)
    return img


def adaptive_foreground():
    """어댑티브 전경 — 바디를 뺀 나머지. 인셋만큼 미리 키운다."""
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw_visor_and_pupil(ImageDraw.Draw(img), s=FG_SCALE)
    hint = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw_book_hint(hint, s=FG_SCALE)
    img.alpha_composite(hint)
    return img


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)

    icon = full_bleed().convert("RGB").resize((1024, 1024), Image.LANCZOS)
    icon.save(os.path.join(OUT, "icon.png"))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon_512.png"))

    adaptive_foreground().resize((1024, 1024), Image.LANCZOS).save(
        os.path.join(OUT, "icon_foreground.png")
    )
    # 배경은 ink 단색 — 그라데이션을 쓰지 않는다 (BRAND.md §8)
    Image.new("RGB", (1024, 1024), INK).save(os.path.join(OUT, "icon_background.png"))

    print("EXA 아이콘 생성 완료:", OUT)

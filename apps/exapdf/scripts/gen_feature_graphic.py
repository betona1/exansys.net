#!/usr/bin/env python3
"""Play Console 그래픽 이미지(1024x500) — 아이콘 v2 팔레트와 같은 결.

왼쪽에 워드마크·태그라인, 오른쪽에 아이콘 일러스트(라운드 마스크).
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(HERE)
SRC = os.path.join(BASE, "docs", "exapdf_vavevave_app_icon.png")
FONTS = os.path.join(BASE, "app", "assets", "fonts")
OUT = os.path.join(BASE, "store", "feature_graphic.png")

W, H = 1024, 500
SS = 2  # 슈퍼샘플
NAVY_LO = (2, 27, 82)    # AppTokens.vaveNavyLo
NAVY_HI = (10, 79, 192)  # AppTokens.vaveNavyHi
CYAN = (15, 205, 255)    # AppTokens.vaveCyan


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


if __name__ == "__main__":
    w, h = W * SS, H * SS
    img = Image.new("RGB", (w, h))
    px = img.load()
    # 좌상단 어두운 남색 → 우하단 밝은 블루 (아이콘 배경과 같은 흐름)
    for y in range(h):
        for x in range(0, w, 4):
            c = lerp(NAVY_LO, NAVY_HI, (x / w * 0.65 + y / h * 0.35))
            for dx in range(min(4, w - x)):
                px[x + dx, y] = c

    # 오른쪽 캐릭터 뒤 은은한 시안 발광
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy, r = int(w * 0.78), int(h * 0.5), int(h * 0.75)
    for i in range(20, 0, -1):
        a = int(70 * (1 - i / 20) ** 2)
        rr = r * i / 20
        gd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=CYAN + (a,))
    img = Image.alpha_composite(img.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(w * 0.01)))

    # 아이콘 일러스트를 라운드 마스크로 오른쪽에
    art_size = int(h * 0.78)
    art = Image.open(SRC).convert("RGBA").resize((art_size, art_size), Image.LANCZOS)
    mask = Image.new("L", (art_size, art_size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, art_size, art_size], radius=int(art_size * 0.22), fill=255)
    pos = (int(w * 0.78 - art_size / 2), int(h * 0.5 - art_size / 2))
    img.paste(art, pos, mask)

    d = ImageDraw.Draw(img)
    bold = ImageFont.truetype(os.path.join(FONTS, "Pretendard-Bold.otf"), int(h * 0.22))
    reg = ImageFont.truetype(os.path.join(FONTS, "Pretendard-Regular.otf"), int(h * 0.085))
    small = ImageFont.truetype(os.path.join(FONTS, "Pretendard-Bold.otf"), int(h * 0.055))

    x0 = int(w * 0.07)
    d.text((x0, int(h * 0.30)), "ExaPDF", font=bold, fill=(255, 255, 255))
    d.text((x0, int(h * 0.56)), "PDF를 책처럼 읽는 리더", font=reg, fill=(214, 228, 255))
    d.text((x0, int(h * 0.80)), "E X A N S Y S", font=small, fill=CYAN + (255,))

    img.convert("RGB").resize((W, H), Image.LANCZOS).save(OUT)
    print("생성:", OUT)

#!/usr/bin/env python3
"""VibeQuest 앱 아이콘·스토어 그래픽 생성 (디자인 킷 ANDROID ADAPTIVE ICON)
- icon.png: 1024 풀블리드 (퍼플 그라데이션 + 흰 비비 하단 정렬)
- icon_foreground.png: 어댑티브 전경 (투명 배경, 세이프존 중앙 배치)
- store/feature_graphic.png: 1024x500 (비비 + 타이틀)
4x 슈퍼샘플 후 축소로 안티앨리어싱.
"""
from PIL import Image, ImageDraw, ImageFont

APP = "apps/vibequest/app"
SS = 4  # supersample


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size, c1, c2):
    """대각 그라데이션"""
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        for x in range(0, w, 4):
            t = (x / w + y / h) / 2
            c = lerp(c1, c2, t)
            for dx in range(min(4, w - x)):
                px[x + dx, y] = c
    return img


def bez(p0, p1, p2, n=16):
    return [
        (
            (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t**2 * p2[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t**2 * p2[1],
        )
        for t in [i / n for i in range(n + 1)]
    ]


def draw_cat(draw, ox, oy, s, colors):
    """viewBox 200x216 좌표계 → (ox,oy) 오프셋, s 배율"""
    coat, coat_dark, inner, eye, muzzle = (
        colors["coat"], colors["coatDark"], colors["inner"], colors["eye"], colors["muzzle"],
    )

    def P(x, y):
        return (ox + x * s, oy + y * s)

    def poly(pts, fill):
        draw.polygon([P(x, y) for x, y in pts], fill=fill)

    def ell(cx, cy, rx, ry, fill):
        draw.ellipse([P(cx - rx, cy - ry), P(cx + rx, cy + ry)], fill=fill)

    # 귀
    poly([(50, 98), (38, 46), (94, 76)], coat_dark)
    poly([(150, 98), (162, 46), (106, 76)], coat_dark)
    poly([(57, 90), (49, 58), (84, 76)], inner)
    poly([(143, 90), (151, 58), (116, 76)], inner)
    # 머리
    ell(100, 120, 67, 60, coat)
    # 주둥이 (반투명 대신 혼합색)
    ell(100, 143, 35, 25, muzzle)
    # 볼터치
    blush = (255, 179, 197)
    ell(61, 136, 11, 11, blush)
    ell(139, 136, 11, 11, blush)
    # 눈
    ell(76, 118, 13, 16.5, eye)
    ell(124, 118, 13, 16.5, eye)
    ell(76, 120, 8.4, 12.6, (34, 27, 51))
    ell(124, 120, 8.4, 12.6, (34, 27, 51))
    ell(79.5, 114, 3.4, 3.4, (255, 255, 255))
    ell(127.5, 114, 3.4, 3.4, (255, 255, 255))
    # 코·입
    poly([(100, 134), (94, 139), (106, 139)], (240, 129, 154))
    w = max(2, int(3 * s))
    for pts in [bez((100, 139), (92, 147), (85, 141)), bez((100, 139), (108, 147), (115, 141))]:
        draw.line([P(x, y) for x, y in pts], fill=(91, 74, 99), width=w)
    # 수염
    ww = max(2, int(2.3 * s))
    wcol = (195, 205, 222)
    for pts in [
        bez((39, 124), (55, 121), (66, 126)), bez((37, 136), (55, 135), (66, 140)),
        bez((161, 124), (145, 121), (134, 126)), bez((163, 136), (145, 135), (134, 140)),
    ]:
        draw.line([P(x, y) for x, y in pts], fill=wcol, width=ww)


WHITE_CAT = {  # 아이콘용 흰 비비 (디자인 킷)
    "coat": (255, 255, 255), "coatDark": (227, 232, 242), "inner": (255, 214, 224),
    "eye": (91, 61, 245), "muzzle": (242, 245, 251),
}
BLUE_CAT = {  # 본래 비비
    "coat": (143, 160, 190), "coatDark": (110, 128, 166), "inner": (244, 196, 208),
    "eye": (121, 222, 90), "muzzle": (231, 236, 245),
}

PUR1, PUR2 = (123, 92, 255), (58, 34, 201)

# ── 1. 풀블리드 아이콘 1024 ──
N = 1024 * SS
img = gradient((N, N), PUR1, PUR2)
d = ImageDraw.Draw(img)
s = N / 200 * 1.12
draw_cat(d, (N - 200 * s) / 2, N - 178 * s, s, WHITE_CAT)  # 하단 정렬, 꽉 차게 (턱 크롭)
img = img.resize((1024, 1024), Image.LANCZOS)
img.save(f"{APP}/assets/icon/icon.png")

# ── 2. 어댑티브 전경 (세이프존: 중앙 66%) ──
fg = Image.new("RGBA", (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(fg)
s = N / 200 * 0.52
draw_cat(d, (N - 200 * s) / 2, (N - 216 * s) / 2 + 8 * s, s, WHITE_CAT)
fg = fg.resize((1024, 1024), Image.LANCZOS)
fg.save(f"{APP}/assets/icon/icon_foreground.png")

# ── 3. Play 피처 그래픽 1024x500 ──
W, H = 1024 * 2, 500 * 2
feat = gradient((W, H), PUR1, PUR2)
d = ImageDraw.Draw(feat)
s = H / 216 * 0.8
draw_cat(d, W * 0.66, H - 200 * s, s, BLUE_CAT)
try:
    font_big = ImageFont.truetype(f"{APP}/assets/fonts/Jua-Regular.ttf", 150)
    font_sm = ImageFont.truetype(f"{APP}/assets/fonts/GothicA1-Bold.ttf", 52)
    d.text((90, H // 2 - 160), "Vibe Quest", font=font_big, fill=(255, 255, 255))
    d.text((96, H // 2 + 30), "AI·코딩 용어, 3분 퀘스트로 클리어!", font=font_sm, fill=(215, 204, 255))
except OSError:
    pass
feat = feat.resize((1024, 500), Image.LANCZOS)
feat.save("apps/vibequest/store/feature_graphic.png")

# ── 4. Play 등록용 512 아이콘 ──
img.resize((512, 512), Image.LANCZOS).save("apps/vibequest/store/icon_512.png")
print("아이콘 4종 생성 완료")

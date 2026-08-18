#!/usr/bin/env python3
"""ExaPDF 앱 내 마스코트 자산 생성 — 바브바브(비비) 컷아웃.

앱 아이콘(gen_icon.py)과 같은 원본 `vavevave/바브바브01.png` 에서
배경·생각풍선·물음표를 걷어낸 투명 PNG 를 만든다. 앱 화면(스플래시·
빈 서재·오류)이 자체 배경 위에 캐릭터만 얹어 쓸 수 있게 하기 위함이다.

  app/assets/mascot/vave_full.png   전신 (스플래시·빈 서재용, 폭 900px)
  app/assets/mascot/vave_face.png   얼굴 (오류·앱바 장식용, 아이콘과 같은 크롭)

원본과 컷아웃 판정 로직은 gen_icon.py 와 동일해야 한다 — 아이콘과
앱 화면의 캐릭터가 다르게 잘리면 어색하다.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, "apps", "exapdf", "app", "assets", "mascot")
MASCOT_SRC = os.path.join(ROOT, "vavevave", "바브바브01.png")

# gen_icon.py 와 같은 값 — 얼굴 크롭과 연결 판정 씨앗
FACE_BOX = (225, 150, 912, 706)
HEAD_SEED = (560, 450)


def keep_component(alpha, seed, threshold=150, feather=4):
    """seed 에서 이어진 덩어리만 남긴다 (gen_icon.py 와 동일 로직)."""
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


def cutout():
    """배경을 빼고 캐릭터(머리에서 이어진 몸 전체)만 남긴다."""
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

    # 생각풍선·떠다니는 물음표는 몸과 떨어진 덩어리 — 머리에서 이어진 것만 남긴다
    alpha = keep_component(alpha, HEAD_SEED)
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))

    out = src.convert("RGBA")
    out.putalpha(alpha)
    return out


def crop_to_alpha(img, pad=24):
    """알파 바운딩박스 + 여백으로 잘라 파일을 가볍게 만든다."""
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("알파가 전부 0 — 컷아웃 실패")
    l, t, r, b = bbox
    return img.crop((max(0, l - pad), max(0, t - pad), min(img.width, r + pad), min(img.height, b + pad)))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    full = crop_to_alpha(cutout())

    # 전신 — 스플래시 히어로용. 폭 900 이면 어느 화면에서도 선명하다
    tw = 900
    full.resize((tw, int(full.height * tw / full.width)), Image.LANCZOS).save(
        os.path.join(OUT, "vave_full.png"))

    # 얼굴 — 아이콘과 같은 크롭. 오류 화면·앱바 장식용
    face = crop_to_alpha(cutout().crop(FACE_BOX), pad=8)
    fw = 480
    face.resize((fw, int(face.height * fw / face.width)), Image.LANCZOS).save(
        os.path.join(OUT, "vave_face.png"))

    print("마스코트 자산 생성 완료:", OUT)

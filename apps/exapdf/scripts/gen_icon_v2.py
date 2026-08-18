#!/usr/bin/env python3
"""ExaPDF 앱 아이콘 v2 — 바브바브가 PDF 를 안고 웃는 그림 (2026-08-18 교체).

원본: `docs/exapdf_vavevave_app_icon.png` (사용자가 준비한 완성 일러스트).
그림에 라운드 테두리 링과 검은 모서리가 박혀 있는데, 스토어·런처 모두
그림 반경(약 17.5%)보다 안쪽으로 마스킹하므로 그대로 써도 검은 모서리는
보이지 않는다. 어댑티브 전경은 flutter_launcher_icons 의 16% 인셋 + 기기
마스크가 링을 잘라내 캐릭터만 깔끔하게 남는다 (실기기 확인 완료).

  design/icon.png             1024 풀블리드 (Play·레거시 런처)
  design/icon_512.png         Play Console 등록용
  design/icon_foreground.png  어댑티브 전경 (원본 그대로)
  design/icon_background.png  어댑티브 배경 (아이콘 배경색 단색)

이전(빼꼼) 판은 gen_icon.py 로 언제든 되돌릴 수 있다.
"""
import os
import shutil

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(HERE)                       # apps/exapdf
SRC = os.path.join(BASE, "docs", "exapdf_vavevave_app_icon.png")
OUT = os.path.join(BASE, "design")
APP_ICON = os.path.join(BASE, "app", "assets", "icon")

BG = (2, 36, 95)  # 아이콘 배경 딥블루 (#02245F)

if __name__ == "__main__":
    src = Image.open(SRC).convert("RGB")

    icon = src.resize((1024, 1024), Image.LANCZOS)
    icon.save(os.path.join(OUT, "icon.png"))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon_512.png"))

    src.convert("RGBA").resize((1024, 1024), Image.LANCZOS).save(
        os.path.join(OUT, "icon_foreground.png"))
    Image.new("RGB", (1024, 1024), BG).save(os.path.join(OUT, "icon_background.png"))

    for name in ("icon.png", "icon_foreground.png", "icon_background.png"):
        shutil.copyfile(os.path.join(OUT, name), os.path.join(APP_ICON, name))

    print("아이콘 v2 생성 완료:", OUT, "→", APP_ICON)

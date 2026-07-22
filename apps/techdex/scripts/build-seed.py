#!/usr/bin/env python3
"""용어목록.md (편집용 마스터) → techdex-seed.json (배포 시드) 생성기.

사용법:
  python apps/techdex/scripts/build-seed.py [입력.md] [출력.json]
  기본: 입력 = apps/techdex/data/용어목록.md
        출력 = src/worker/resources/techdex-seed.json

MD 한 줄 형식:  용어 | 영문·부제 | 난이도 | 필수 | 정의
  - `## ... (컬렉션코드, N개)` 로 컬렉션(ai/app/vibe/user) 판별
  - `### 카테고리` 로 카테고리 판별
재시드: 배포 후 `POST /api/techdex/seed?force=1`(admin) 로 D1 전량 교체.
"""
import json
import re
import sys
import unicodedata

DIFF = {"초급": 1, "중급": 2, "고급": 3, "심화": 3}


def slugify(s: str) -> str:
    s = (s or "").strip().lower()
    s = s.replace(" ", "-")
    s = re.sub(r"[^a-z0-9가-힣\-]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    return s or "term"


def build(md_path: str, out_path: str) -> None:
    coll = None
    cat = None
    rows = []
    seen_slugs = {}
    warnings = []

    with open(md_path, encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip("\n")
            m = re.match(r"^##\s+.*\(([a-z]+),", line)
            if m:
                coll = m.group(1)
                continue
            if line.startswith("### "):
                cat = line[4:].strip()
                continue
            if not line.startswith("- "):
                continue
            parts = [p.strip() for p in line[2:].split(" | ")]
            if len(parts) < 5:
                warnings.append(f"[{lineno}] 컬럼 5개 미만, 건너뜀: {line[:50]}")
                continue
            term, sub, diff, core, *rest = parts
            df = " | ".join(rest).strip()  # 정의에 ' | ' 있어도 복원
            if not term or not df:
                warnings.append(f"[{lineno}] 용어/정의 비어있음, 건너뜀")
                continue
            base = slugify(sub if sub and sub != "-" else term)
            slug = base
            n = seen_slugs.get(base, 0)
            if n:
                slug = f"{base}-{n + 1}"
            seen_slugs[base] = n + 1
            rows.append({
                "termKo": term,
                "termEn": None if (not sub or sub == "-") else sub,
                "def": df,
                "collection": coll or "ai",
                "category": cat or "기타",
                "difficulty": DIFF.get(diff, 2),
                "vibeCore": core == "필수",
                "source": "techdex 마스터",
                "slug": slug,
            })

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)

    print(f"입력: {md_path}")
    print(f"출력: {out_path}")
    print(f"용어: {len(rows)}개")
    by = {}
    for r in rows:
        by[r["collection"]] = by.get(r["collection"], 0) + 1
    print("컬렉션:", by)
    print("필수:", sum(1 for r in rows if r["vibeCore"]))
    if warnings:
        print(f"경고 {len(warnings)}건:")
        for w in warnings[:20]:
            print(" ", w)


if __name__ == "__main__":
    inp = sys.argv[1] if len(sys.argv) > 1 else "apps/techdex/data/용어목록.md"
    out = sys.argv[2] if len(sys.argv) > 2 else "src/worker/resources/techdex-seed.json"
    build(inp, out)

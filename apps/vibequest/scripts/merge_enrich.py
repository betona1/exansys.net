#!/usr/bin/env python3
"""보강 결과 병합: glossary_v2.base.json + (_pilot_output.json, _enrich_out_*.json)
→ glossary_v2.enriched.json

검증:
- 모든 id가 정확히 1회 보강되었는지 (누락/중복 보고)
- confusionSet·aliases 가 리스트인지, whyItMatters/example 이 비어있지 않은지
- difficultySuggested 1~4 범위
"""
import glob
import json

BASE = "apps/vibequest/data/glossary_v2.base.json"
OUT = "apps/vibequest/data/glossary_v2.enriched.json"

base = json.load(open(BASE, encoding="utf-8"))
by_id = {t["id"]: t for t in base}

enrich = {}
dupes = []
files = sorted(glob.glob("apps/vibequest/data/_enrich_out_*.json")) + [
    "apps/vibequest/data/_pilot_output.json"
]
for f in files:
    try:
        arr = json.load(open(f, encoding="utf-8"))
    except Exception as e:
        print(f"!! {f} 파싱 실패: {e}")
        continue
    for e in arr:
        tid = e.get("id")
        if tid in enrich:
            dupes.append(tid)
        enrich[tid] = e

missing = [tid for tid in by_id if tid not in enrich]
unknown = [tid for tid in enrich if tid not in by_id]

bad = []
for tid, e in enrich.items():
    if tid not in by_id:
        continue
    if not (e.get("whyItMatters") or "").strip():
        bad.append((tid, "whyItMatters 비어있음"))
    if not (e.get("example") or "").strip():
        bad.append((tid, "example 비어있음"))
    if not isinstance(e.get("confusionSet"), list):
        bad.append((tid, "confusionSet 리스트 아님"))
    if not isinstance(e.get("aliases"), list):
        bad.append((tid, "aliases 리스트 아님"))
    d = e.get("difficultySuggested")
    if not (isinstance(d, int) and 1 <= d <= 4):
        bad.append((tid, f"difficultySuggested 이상: {d!r}"))

out = []
for t in base:
    e = enrich.get(t["id"])
    r = dict(t)
    if e:
        r["whyItMatters"] = (e.get("whyItMatters") or "").strip()
        r["example"] = (e.get("example") or "").strip()
        r["confusionSet"] = e.get("confusionSet") or []
        # 기존 aliases 와 합집합(순서 유지·중복 제거)
        merged_aliases = list(dict.fromkeys((t.get("aliases") or []) + (e.get("aliases") or [])))
        # termKo 자기 자신은 별칭에서 제거
        r["aliases"] = [a for a in merged_aliases if a.strip() and a.strip() != t["termKo"]]
        d = e.get("difficultySuggested")
        if isinstance(d, int) and 1 <= d <= 4:
            r["difficulty"] = d
        r["difficultyReason"] = e.get("difficultyReason", "")
        r["difficultyReview"] = False
        r["enriched"] = True
    out.append(r)

json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

import collections
diff = collections.Counter(t["difficulty"] for t in out)
enr = sum(1 for t in out if t["enriched"])
print(f"병합 완료 → {OUT}")
print(f"총 {len(out)}개 / 보강 {enr}개 / 누락 {len(missing)}개 / 중복 {len(dupes)}개 / 미지 id {len(unknown)}개 / 필드이상 {len(bad)}건")
print("난이도 분포:", dict(sorted(diff.items())))
if missing:
    print("누락 id:", missing[:30])
if bad:
    print("필드 이상 상위:", bad[:15])

#!/usr/bin/env python3
"""glossary_master_867.json → glossary_v2.base.json (VibeQuest v2 스키마)

- 50개 혼재 카테고리를 11개 표준 도메인으로 통일(원본은 subcategory로 보존)
- 학습 트랙 A~E 태깅(다중 소속 허용)
- v2 스키마 골격 생성(리치 필드는 Fable 5 보강 단계에서 채움)
- 난이도는 유지하되 base-* 의 difficulty==2 는 재평가 대상으로 표시(difficultyReview)
"""
import json
import collections

SRC = "apps/vibequest/data/glossary_master_867.json"
OUT = "apps/vibequest/data/glossary_v2.base.json"

# 11개 표준 도메인 (신규 500의 카테고리를 canonical 로 사용)
DOMAINS = [
    "생성형 AI·모델", "프롬프트·컨텍스트·RAG", "에이전트·바이브코딩", "프로그래밍 핵심",
    "웹·프론트엔드", "백엔드·API", "데이터베이스·데이터", "Git·DevOps·클라우드",
    "테스트·품질·보안", "모바일·앱 출시", "UX·UI·제품·학습게임",
]

# 기존 39개 카테고리 → 표준 도메인
DOMAIN_MAP = {
    # 표준(자기 자신)
    **{d: d for d in DOMAINS},
    # ai collection
    "AI·클로드코드": "에이전트·바이브코딩",
    "DB 구조": "데이터베이스·데이터",
    "DB 운영": "데이터베이스·데이터",
    "DB 종류": "데이터베이스·데이터",
    "개발 도구": "Git·DevOps·클라우드",
    "개발 언어": "프로그래밍 핵심",
    "개발 직무": "프로그래밍 핵심",
    "깃·버전관리": "Git·DevOps·클라우드",
    "데이터 기본": "데이터베이스·데이터",
    "배포·운영·SQL": "Git·DevOps·클라우드",
    "수익화": "모바일·앱 출시",
    "스토어 출시": "모바일·앱 출시",
    "앱 아키텍처": "프로그래밍 핵심",
    "앱 프레임워크": "웹·프론트엔드",
    "웹·언어·API": "웹·프론트엔드",
    "파이어베이스·구글": "백엔드·API",
    "프로그래밍 기초": "프로그래밍 핵심",
    "환경·터미널": "Git·DevOps·클라우드",
    # app collection
    "UI 컴포넌트": "UX·UI·제품·학습게임",
    "개발 일반": "프로그래밍 핵심",
    "내비게이션": "웹·프론트엔드",
    "디자인·스타일": "UX·UI·제품·학습게임",
    "배포·스토어": "모바일·앱 출시",
    "상태·생명주기": "웹·프론트엔드",
    "애니메이션·인터랙션": "UX·UI·제품·학습게임",
    "코드·협업": "Git·DevOps·클라우드",
    "테스트·품질": "테스트·품질·보안",
    "헷갈리는 짝 개념": "프로그래밍 핵심",
    "화면 기본": "UX·UI·제품·학습게임",
    "화면 종류": "UX·UI·제품·학습게임",
    # vibe collection
    "개발/에이전트 경험": "에이전트·바이브코딩",
    "권한·안전": "테스트·품질·보안",
    "비용·토큰경제": "생성형 AI·모델",
    "세션·핸드오프": "에이전트·바이브코딩",
    "작업 방식": "에이전트·바이브코딩",
    "컨텍스트·메모리": "프롬프트·컨텍스트·RAG",
    "품질·리스크": "테스트·품질·보안",
    "하네스·도구": "에이전트·바이브코딩",
    "핵심 개념": "에이전트·바이브코딩",
}

# 표준 도메인 → 학습 트랙(§24, 다중 소속) A:생존 B:첫앱 C:에이전트 D:풀스택 E:제품UX
TRACK_MAP = {
    "생성형 AI·모델": ["C"],
    "프롬프트·컨텍스트·RAG": ["A", "C"],
    "에이전트·바이브코딩": ["A", "C"],
    "프로그래밍 핵심": ["A", "D"],
    "웹·프론트엔드": ["B", "D"],
    "백엔드·API": ["B", "D"],
    "데이터베이스·데이터": ["D"],
    "Git·DevOps·클라우드": ["A", "D"],
    "테스트·품질·보안": ["A", "E"],
    "모바일·앱 출시": ["B"],
    "UX·UI·제품·학습게임": ["E"],
}


def main():
    src = json.load(open(SRC, encoding="utf-8"))
    out = []
    unmapped = set()
    for t in src:
        orig_cat = t.get("category", "")
        domain = DOMAIN_MAP.get(orig_cat)
        if domain is None:
            unmapped.add(orig_cat)
            domain = "프로그래밍 핵심"
        is_base = str(t.get("id", "")).startswith("base")
        out.append({
            "id": t["id"],
            "termKo": t["termKo"],
            "termEn": t.get("termEn") or "",
            "aliases": t.get("aliases") or [],
            "def": t["def"],
            "whyItMatters": "",
            "example": "",
            "confusionSet": [],
            "category": domain,
            "subcategory": orig_cat,
            "tracks": TRACK_MAP.get(domain, []),
            "collection": "vibequest",
            "difficulty": t.get("difficulty", 2),
            "difficultyReview": bool(is_base and t.get("difficulty") == 2),
            "vibeCore": bool(t.get("vibeCore")),
            "volatile": bool(t.get("volatile")),
            "checkedAt": t.get("checkedAt") or "",
            "sourceRefs": t.get("sourceRefs") or [],
            "quizEnabled": t.get("quizEnabled", True),
            "slug": t["slug"],
            "enriched": False,
        })

    json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    dom = collections.Counter(t["category"] for t in out)
    trk = collections.Counter(tr for t in out for tr in t["tracks"])
    print(f"출력: {OUT}  ({len(out)}개)")
    print("도메인 분포:")
    for d in DOMAINS:
        print(f"  {d}: {dom.get(d,0)}")
    print("트랙 분포:", dict(sorted(trk.items())))
    print("난이도 재평가 대상(difficultyReview):", sum(1 for t in out if t["difficultyReview"]))
    if unmapped:
        print("!! 매핑 안 된 카테고리:", unmapped)


if __name__ == "__main__":
    main()

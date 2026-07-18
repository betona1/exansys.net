# CLAUDE.md — AI 바이브코딩 용어 학습 플랫폼 (exansys.net)

> 이 문서는 프로젝트의 **단일 기획·지침 파일(Source of Truth)** 입니다.
> Claude(및 바이브코딩 도구)가 이 파일을 읽고 일관된 방향으로 코드를 생성하도록 작성되었습니다.
> 작성일: 2026-07-18 · 작성 기준: 김준용(netkjy@gmail.com)

---

## 0. 한 줄 요약 (TL;DR)

**"AI 바이브코딩을 시작하려는 비기너가, 게임으로 IT/AI 전문용어를 쉽고 재미있게 익히게 만드는 플랫폼."**

- **it.exansys.net** — AI/바이브코딩 용어 사전(검색 가능한 DB 웹사이트)
- **aistart.exansys.net** — 게임용 용어 데이터를 편집·관리하는 관리자(에디터) + 게임 데이터 API
- **게임 앱** — 위 데이터를 받아 퀴즈·가로세로 퍼즐 등으로 용어를 학습시키는 웹앱(→ 추후 네이티브 앱)

---

## 1. 프로젝트 목표

### 비전
바이브코딩 비기너가 겪는 가장 큰 진입장벽은 **"용어를 몰라서 못 시작하는 것"** 이다.
(예: token, context window, RAG, MCP, embedding, fine-tuning, hallucination…)
이 용어들을 **게임처럼** 습득하게 해서, "용어 → 이해 → 바이브코딩 시작"으로 이어지는 온보딩을 만든다.

### 핵심 목표 (측정 가능한 형태)
1. **용어 DB 구축**: 시드 500~1,000개 이상의 AI/바이브코딩 용어를 카테고리·난이도별로 정리
2. **자동 수집**: 매주 신규 AI 용어를 자동 크롤링/수집하여 DB에 반영(사람 검수 후 게시)
3. **학습 게임화**: 용어 문제풀이·가로세로 퍼즐로 비기너가 **10분 안에** 핵심 용어 20개를 익힐 수 있게
4. **신규 용어 알리미**: 새 바이브코딩 용어가 등록되면 앱 내 알림/뱃지로 사용자에게 알림

### 타깃 사용자
- 코딩 경험이 거의 없이 Cursor/Claude/Copilot 등으로 "바이브코딩"을 시작하려는 입문자
- 비개발 직군(기획·마케팅·창업가) 중 AI 도구를 쓰기 시작한 사람

---

## 2. 시스템 아키텍처

```
                         ┌──────────────────────────────────────┐
                         │        공유 데이터베이스 (PostgreSQL)      │
                         │  terms / categories / sources /        │
                         │  game_items / crawl_log / notifications │
                         └───────────────▲─────────────▲──────────┘
                                         │             │
        ┌────────────────────────────────┘             └────────────────────────────┐
        │ (읽기: 검색/조회)                                          (읽기/쓰기: 관리)     │
        │                                                                            │
┌───────┴─────────┐        ┌──────────────────────┐         ┌──────────────────────┐
│ it.exansys.net  │        │  aistart.exansys.net  │         │  Python 크롤러 워커     │
│ 용어 사전(검색)    │        │  게임 데이터 에디터/관리자 │         │  (주간 자동 수집)         │
│ Next.js (SSR)   │        │  Next.js + 관리자 인증   │         │  APScheduler/cron       │
└─────────────────┘        │  + 게임 데이터 API        │         │  arXiv/HN/GitHub/PH…    │
                           └───────────▲──────────┘         └───────────┬──────────┘
                                       │ (게임 데이터 API)                  │ (수집→정규화→중복제거)
                                       │                                  │
                            ┌──────────┴──────────┐            신규 용어 감지 → notifications 큐
                            │   게임 앱 (웹앱/PWA)    │
                            │   퀴즈·가로세로 퍼즐     │
                            │   앱 내 알림/뱃지 소비    │
                            └─────────────────────┘
```

### 서비스 구성 (3 웹 + 1 워커)

| 구성요소 | 도메인 | 역할 | 기술 |
|---|---|---|---|
| 용어 사전 | `it.exansys.net` | 용어 검색·조회 (SEO 대상, 공개) | Next.js(App Router) + SSR |
| 관리/에디터 | `aistart.exansys.net` | 용어·게임 데이터 편집, 크롤링 검수, 게임 데이터 API 제공 | Next.js + 관리자 인증 |
| 게임 앱 | `aistart.exansys.net/play` (또는 `game.exansys.net`) | 퀴즈·퍼즐 게임, 알림 소비 | Next.js + PWA |
| 크롤러 워커 | (서버 백그라운드) | 주간 신규 용어 자동 수집 | **Python** (선호 언어) |

> **설계 원칙**: 웹 3종은 **Next.js 모노레포**로 통합(공통 UI·타입·DB 클라이언트 재사용).
> 수집 파이프라인만 **Python 독립 워커**로 분리 → 준용님이 편한 언어로 크롤링 로직을 유지보수하고,
> 웹과는 **공유 DB**로만 연결(느슨한 결합). 크롤러가 죽어도 웹은 정상 동작.

---

## 3. 기술 스택 (확정)

| 레이어 | 선택 | 비고 |
|---|---|---|
| 프론트/백엔드(웹) | **Next.js 15 (App Router, TypeScript)** | 모노레포(Turborepo/pnpm workspace) |
| DB | **PostgreSQL** | 관계형 + 전문검색(FTS) |
| 검색 | 1차: **Postgres FTS + `pg_trgm`** / 2차: **Meilisearch** | 초성·오타 허용 검색은 Meilisearch로 확장 |
| ORM | **Prisma** (웹) / **SQLAlchemy**(크롤러) | 두 언어가 같은 DB를 공유 |
| 인증(관리자) | **Auth.js(NextAuth)** or Clerk | 에디터 접근 제한 |
| 크롤러 | **Python 3.12** + `httpx` + `BeautifulSoup`/`lxml` + `feedparser` | 준용님 선호 언어 |
| 스케줄러 | **APScheduler**(단순) 또는 **Celery+Redis**(확장 시) / 인프라 레벨은 cron | 주 1회 실행 |
| 용어 정규화 | **LLM(Claude API)** 로 정의문 생성·난이도 태깅·중복 판정 | 사람 검수 전 초안 자동화 |
| 배포 | Vercel(웹) + Railway/Fly.io/자체 서버(DB·크롤러) | 크롤러는 Docker 컨테이너 |
| 알림 | **앱 내 알림/뱃지** (DB `notifications` 테이블 폴링/구독) | 추후 웹푸시 확장 가능 |

> 참고: 원래 Python 풀스택도 후보였지만 웹은 Next.js 통합으로 결정. 다만 **크롤러는 Python**으로 유지해
> "검색·크롤링 스킬(web-crawling, 준용님 환경에 설치됨)"을 그대로 활용한다.

---

## 4. 데이터 모델 (DB 스키마 초안)

```sql
-- 카테고리 (계층형)
CREATE TABLE categories (
  id           SERIAL PRIMARY KEY,
  slug         TEXT UNIQUE NOT NULL,       -- 'core-concepts', 'rag', 'agents'...
  name_ko      TEXT NOT NULL,
  name_en      TEXT NOT NULL,
  parent_id    INT REFERENCES categories(id),
  sort_order   INT DEFAULT 0
);

-- 수집 소스 (출처 추적/라이선스 관리)
CREATE TABLE sources (
  id           SERIAL PRIMARY KEY,
  name         TEXT NOT NULL,              -- 'Google ML Glossary', 'arXiv', 'HackerNews'...
  url          TEXT,
  source_type  TEXT,                       -- 'glossary' | 'paper' | 'trend' | 'manual'
  license      TEXT,                       -- 'CC-BY', 'MIT', 'proprietary(참조만)'...
  reliability  INT DEFAULT 3               -- 1~5, 검수 우선순위
);

-- 용어 (핵심 테이블)
CREATE TABLE terms (
  id           SERIAL PRIMARY KEY,
  slug         TEXT UNIQUE NOT NULL,       -- 'context-window'
  term_en      TEXT NOT NULL,              -- 'Context Window'
  term_ko      TEXT,                       -- '컨텍스트 윈도우'
  aliases      TEXT[],                     -- 동의어/약어 ['ctx window']
  abbr         TEXT,                       -- 'RAG', 'MCP'
  short_def_ko TEXT,                       -- 한 줄 정의(게임/카드용, 60자 내외)
  long_def_ko  TEXT,                       -- 상세 설명(사전용)
  example      TEXT,                       -- 사용 예/비유
  category_id  INT REFERENCES categories(id),
  difficulty   INT DEFAULT 1,              -- 1(입문)~5(고급)
  is_vibe_core BOOLEAN DEFAULT FALSE,      -- '바이브코딩 필수 용어' 플래그
  status       TEXT DEFAULT 'draft',       -- 'draft' | 'review' | 'published'
  source_id    INT REFERENCES sources(id),
  first_seen   DATE,                       -- 최초 발견일(신규 판정용)
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now(),
  search_tsv   tsvector                    -- FTS 인덱스용
);
CREATE INDEX terms_tsv_idx ON terms USING GIN(search_tsv);
CREATE INDEX terms_trgm_idx ON terms USING GIN(term_en gin_trgm_ops);

-- 게임 아이템 (용어에서 파생된 문제 데이터)
CREATE TABLE game_items (
  id           SERIAL PRIMARY KEY,
  term_id      INT REFERENCES terms(id) ON DELETE CASCADE,
  game_type    TEXT NOT NULL,              -- 'quiz' | 'crossword' | 'match' | 'flashcard'
  payload      JSONB NOT NULL,             -- 게임별 문제 구조(정답/오답보기/힌트/좌표 등)
  difficulty   INT DEFAULT 1,
  is_active    BOOLEAN DEFAULT TRUE
);

-- 크롤링 로그 (수집 이력·중복/신규 판정)
CREATE TABLE crawl_log (
  id           SERIAL PRIMARY KEY,
  source_id    INT REFERENCES sources(id),
  run_at       TIMESTAMPTZ DEFAULT now(),
  raw_term     TEXT,
  matched_term_id INT REFERENCES terms(id),  -- 기존 용어 매칭 시
  is_new       BOOLEAN,
  raw_context  TEXT                          -- 원문 스니펫
);

-- 신규 용어 알림 큐 (앱 내 알림/뱃지 소스)
CREATE TABLE notifications (
  id           SERIAL PRIMARY KEY,
  term_id      INT REFERENCES terms(id),
  title        TEXT,                       -- '새 바이브 용어: Agentic Workflow'
  body         TEXT,
  created_at   TIMESTAMPTZ DEFAULT now(),
  published_at TIMESTAMPTZ                 -- 검수 통과 후 노출 시점
);

-- (선택) 사용자/진행도 — 게임 앱 계정 도입 시
CREATE TABLE users (...);
CREATE TABLE user_progress (user_id, term_id, mastery_level, last_seen);
CREATE TABLE user_notif_reads (user_id, notification_id, read_at);
```

---

## 5. 용어 수집 소스 (리서치 결과)

### 5-A. 1단계 — 시드(Seed) 소스: "지금 존재하는 용어 총정리"
> 최초 DB를 채우는 신뢰도 높은 사전·용어집. 대부분 참조/일부 오픈소스.

**공식·권위 있는 용어집**
- **Google ML Glossary** — 가장 방대·정확한 ML 용어집(수백 개). https://developers.google.com/machine-learning/glossary
- **TechCrunch AI Glossary** — 지속 업데이트되는 일반 AI 용어 해설. (트렌드 반영 좋음)
- **IBM Think / Google Cloud "What is…"** — 개념별 정의 페이지
- **Hugging Face / OpenAI / Anthropic Docs 용어** — 실무 API 용어

**GitHub 오픈소스 글로서리 (구조화·재사용 유리, 라이선스 확인 필수)**
- **mattpocock/dictionary-of-ai-coding** — ⭐️ 바이브코딩 특화. 7개 섹션·80+ 용어(Markdown). 프로젝트 컨셉과 가장 일치.
- **holasoymalva/llm-glossary** — LLM/AI/NLP/ML 핵심 개념
- **bfortuner/ml-glossary** (machinelearning.wtf) — ML 용어, `.rst` 구조화
- **Cool-Runningz/awesome-ai-glossary**, **ahmad-act/AI-ML-concepts-terms-and-abbreviations**, **odisha-ml/AI-Glossary**

**바이브코딩 전용 용어집 (비기너 타깃과 정확히 일치)**
- **sph.sh — 82 dev terms(12 카테고리)**: Core/Model Types/RAG/Fine-tuning/Local Inference/Agents/Prompt Eng/Production/Cost/Security/Eval/Extended Thinking → **우리 카테고리 체계의 베이스로 채택 권장**
- Blink, SiteGround, vibecoder.me, codingwithvibe.com, vibecodewithmatt.com, Explore AI Together 글로서리
- **Wikipedia "Vibe coding" / Merriam-Webster** — 정의·어원

> **수집 방식**: GitHub 저장소는 **git clone → Markdown/rst 파싱**으로 구조화가 가장 깔끔(권장).
> HTML 글로서리는 web-crawling 스킬로 스크래핑하되 **정의문은 그대로 복붙하지 않고 LLM으로 재작성**(저작권·라이선스 안전).

### 5-B. 2단계 — 지속 수집 소스: "매주 신규 AI 용어 크롤링"
> 새 용어가 태어나는 곳. **API 우선**(안정적), 스크래핑은 보조.

**논문 소스 (신조어·기법명이 가장 먼저 등장)**
- **arXiv API** — `cs.AI / cs.CL / cs.LG` 카테고리. 공식 Atom API, 요청 간 **3초 간격 권장**(rate limit). `arxiv` PyPI 패키지로 간단. 신규 제목/초록에서 용어 추출.
- **Semantic Scholar Academic Graph API** — 226M+ 논문, 키워드 검색·인용 그래프. 무료 키.
- **Papers with Code** — 기법·벤치마크 이름 추적

**개발자 트렌드 소스 (실무 유행어·툴 이름)**
- **Hacker News (Algolia HN Search API)** — 무료·키 불필요. `search_by_date?tags=story&query=AI` 등으로 최신 스토리 수집.
- **GitHub Trending / GitHub API** — 급상승 레포명·토픽에서 신규 툴/용어(예: 새 프레임워크명). 참고 아키텍처: `dongzhang84/trend-monitor`(GitHub Trending+PH+HN 주간 리포트).
- **Product Hunt API (GraphQL)** — 신규 AI 제품/기능 이름
- **Reddit API** — `r/LocalLLaMA`, `r/MachineLearning`, `r/ChatGPTCoding` 신조어
- **Wikipedia/Wikidata API** — 신규 문서·리다이렉트로 용어 정식화 여부 확인

> **트렌드→용어 승격 규칙**: 트렌드 소스에서 나온 후보는 곧바로 게시하지 않고,
> ① 빈도(여러 소스에서 반복 등장) ② arXiv/Wikipedia에 근거 존재 ③ 관리자 검수 통과 → 3조건 중 2개 이상일 때 `published`.

---

## 6. 크롤링/수집 파이프라인 설계 (2단계 자동화)

### 6-A. 파이프라인 단계
```
[1] 수집(Collect)   각 소스별 커넥터가 원시 텍스트/제목/초록을 가져옴
        │            (arXiv/HN/GitHub는 API, 글로서리는 스크래핑)
        ▼
[2] 추출(Extract)   후보 용어(term candidate) 뽑기
        │            - 규칙기반: 약어(대문자연속), n-gram, "X is a/an ..." 패턴
        │            - LLM기반: 초록/문서에서 '새로운 기법·개념명' 추출(Claude API)
        ▼
[3] 정규화(Normalize)  소문자화·표제어화·약어↔정식명 매핑, 한글 표기 생성
        ▼
[4] 중복제거(Dedup)   기존 terms와 대조
        │            - 1차: slug/alias 완전일치
        │            - 2차: pg_trgm/embedding 유사도 > 임계값이면 '기존 용어'로 매칭
        ▼
[5] 신규판정(Detect)  어디에도 없으면 is_new=TRUE, first_seen=today
        ▼
[6] 초안생성(Draft)   LLM으로 short_def_ko/long_def_ko/난이도/카테고리 초안 자동 작성
        │            status='review'로 저장 (아직 비공개)
        ▼
[7] 검수(Review)     aistart.exansys.net 에디터에서 사람이 확인/수정 → status='published'
        ▼
[8] 알림(Notify)     published 시 notifications 큐에 삽입 → 게임 앱 뱃지/알림 노출
        ▼
[9] 게임화(Gamify)   published 용어에서 game_items 자동 생성(퀴즈 보기·퍼즐 좌표 등)
```

### 6-B. 스케줄 (매주 자동)
- **주 1회(예: 매주 월요일 새벽 KST)** 전체 파이프라인 실행 — cron: `0 3 * * 1`
- 소스별로 마지막 실행 이후 신규분만 증분 수집(`run_at` 기준)
- 실패 시 재시도·소스별 격리(한 소스 오류가 전체를 막지 않음)

### 6-C. Python 크롤러 구조(예시)
```
crawler/
  connectors/
    arxiv.py          # feedparser/arxiv 패키지
    hackernews.py     # Algolia HN API (httpx)
    github_trending.py
    producthunt.py    # GraphQL
    glossary_scraper.py  # 시드용, web-crawling 스킬 활용
  pipeline/
    extract.py        # 규칙 + LLM 후보 추출
    normalize.py
    dedup.py          # pg_trgm + 임베딩
    draft_llm.py      # Claude API로 정의 초안
  db.py               # SQLAlchemy, 웹과 공유하는 Postgres
  scheduler.py        # APScheduler 주간 잡
  main.py
```

### 6-D. 신규 용어 알림(알리미) 로직
1. 파이프라인 [7] 검수에서 관리자가 `published`로 전환
2. DB 트리거 또는 앱 서버가 `is_vibe_core=TRUE` 또는 신규 용어에 대해 `notifications` 행 생성
3. **게임 앱**: 접속/포커스 시 `GET /api/notifications?after=<last_read>` 폴링 → **뱃지 카운트 + 알림 목록** 표시
4. 사용자가 확인하면 `user_notif_reads`에 기록(뱃지 감소)
5. (2차 확장) 웹푸시(FCM/Web Push)로 미접속 사용자에게도 발송 — PWA 전환 시 활성화

---

## 7. 게임 앱 기능 명세 (웹 먼저 → 앱 확장)

### MVP(웹앱) 게임 모드
1. **용어 문제풀이(Quiz)**
   - 4지선다: "다음 설명에 맞는 용어는?" / 역방향: "이 용어의 뜻은?"
   - 오답 보기는 같은 카테고리·유사 난이도에서 자동 생성(헷갈림 유도)
   - 즉시 정답 해설 + 상세 사전 링크(it.exansys.net)
2. **가로세로 퍼즐(Crossword)**
   - 카테고리별 8~12개 용어로 소형 퍼즐 자동 생성(영문 표기 기반)
   - 힌트 = `short_def_ko`, 정답 = `term_en`
   - 퍼즐 생성기: 백엔드에서 좌표 배치 알고리즘 → `game_items.payload`에 저장
3. **카드 매칭(Match)** — 용어 ↔ 뜻 짝맞추기(입문 난이도)
4. **플래시카드(Flashcard)** — 빠른 복습, 간격반복(SRS) 기초

### 학습 경험(UX)
- **온보딩 코스**: "바이브코딩 필수 20선"(`is_vibe_core`) → 첫 10분 완주 설계
- **난이도 단계**: 입문→초급→중급 순차 해금
- **진행도/스트릭**: 마스터한 용어 수, 연속 학습일
- **신규 용어 배지**: 홈에 "이번 주 새 용어 N개" 뱃지 → 탭하면 신규 용어 미니게임

### 데이터 연동
- 게임 앱은 **자체 용어 저장 안 함**. `aistart.exansys.net`의 **게임 데이터 API**에서 받아옴:
  - `GET /api/game/items?type=quiz&difficulty=1&limit=20`
  - `GET /api/game/crossword?category=rag`
  - `GET /api/notifications?after=...`
- 관리자는 `aistart` 에디터에서 `game_items.payload`를 직접 편집/미리보기 가능(문제 품질 관리)

---

## 8. 단계별 로드맵

### Phase 0 — 기반 (1주)
- [ ] 모노레포 셋업(Next.js × 3 앱 + shared 패키지), Postgres 프로비저닝
- [ ] DB 스키마 마이그레이션(Prisma), Python 크롤러가 같은 DB 접속(SQLAlchemy)
- [ ] 카테고리 체계 확정(sph.sh 12분류 베이스 + 바이브코딩 특화 태그)

### Phase 1 — 시드 용어 DB 구축 ★1단계 목표
- [ ] GitHub 글로서리 레포 clone → 파싱 → terms 적재(라이선스 표기)
- [ ] 공식 글로서리 스크래핑 → LLM 재작성으로 `short/long_def_ko` 생성
- [ ] 500~1,000 용어 검수·`published`, `is_vibe_core` 선별(핵심 100개)
- [ ] `it.exansys.net` 검색 UI(FTS + 오타허용) 오픈

### Phase 2 — 게임 앱 MVP
- [ ] game_items 자동생성기(quiz/flashcard 먼저, crossword 다음)
- [ ] 게임 데이터 API + 게임 앱(웹) 퀴즈·퍼즐 플레이 가능
- [ ] 온보딩 "필수 20선" 코스, 진행도/스트릭

### Phase 3 — 자동 크롤링 ★2단계 목표
- [ ] arXiv·HN·GitHub·PH 커넥터 → 추출/정규화/중복제거 파이프라인
- [ ] 주간 스케줄러 가동, 검수 큐 UI(aistart)
- [ ] 신규 용어 → notifications → 게임 앱 뱃지/알림 연동(알리미)

### Phase 4 — 확장
- [ ] Meilisearch 도입(고급 검색), 사용자 계정·SRS 고도화
- [ ] 웹푸시/PWA, 이후 네이티브 앱(iOS/Android)
- [ ] 다국어(영/한 병기 강화), 커뮤니티 제안 용어

---

## 9. 리스크 · 라이선스 · 품질 관리

- **저작권/라이선스**: 외부 글로서리 정의문을 그대로 복제하지 않는다. **출처는 `sources`에 기록**하고, 정의문은 **LLM으로 재작성 + 사람 검수**. GitHub 레포는 라이선스(MIT/CC 등) 확인 후 준수·표기.
- **크롤링 매너**: robots.txt·rate limit 준수(arXiv 3초 간격 등), API 우선, User-Agent 명시.
- **품질**: 자동 생성 정의는 항상 `review` 단계를 거쳐 `published`. 오정의·중복은 검수에서 차단.
- **중복/동의어**: alias·약어 매핑을 강하게 관리(RAG=Retrieval-Augmented Generation 등).
- **트렌드 노이즈**: 일시적 유행어가 사전에 남지 않도록 "2소스 이상 근거 + 검수" 승격 규칙 적용.

---

## 10. 다음 액션 (바로 시작 가능한 것)

1. **카테고리 확정**: sph.sh 12분류를 한글화한 초안을 만들고 준용님 승인
2. **시드 수집 PoC**: `mattpocock/dictionary-of-ai-coding` + Google ML Glossary로 100개 용어 파싱 → 스키마 검증
3. **모노레포 스캐폴딩**: Next.js 3앱 + Prisma 스키마 + Python 크롤러 골격 코드 생성
4. **검수 에디터 와이어프레임**: aistart 관리자 화면(용어 CRUD + 크롤링 검수 큐)

> 원하시면 위 2~3번(시드 파싱 PoC / 모노레포 골격)을 실제 코드로 착수하겠습니다.

---

## 부록 A. 참고 소스 링크
- Google ML Glossary — https://developers.google.com/machine-learning/glossary
- sph.sh 82 dev terms — https://sph.sh/en/posts/ai-llm-glossary-developer-terms/
- mattpocock/dictionary-of-ai-coding — https://github.com/mattpocock/dictionary-of-ai-coding
- holasoymalva/llm-glossary — https://github.com/holasoymalva/llm-glossary
- bfortuner/ml-glossary — https://github.com/bfortuner/ml-glossary
- Vibe coding (Wikipedia) — https://en.wikipedia.org/wiki/Vibe_coding
- arXiv API 매뉴얼 — https://info.arxiv.org/help/api/user-manual.html
- Semantic Scholar API — https://www.semanticscholar.org/product/api
- trend-monitor(참고 아키텍처) — https://github.com/dongzhang84/trend-monitor
- Hacker News(Algolia) API — https://hn.algolia.com/api

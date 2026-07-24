# CLAUDE.md — exansys.net 프로젝트 가이드

이 문서는 Claude Code가 exansys.net 웹사이트를 개발할 때 따라야 할 프로젝트 규칙과 명세다.
**모든 대화와 커밋 메시지는 한국어로 작성한다.**

---

## 1. 프로젝트 개요

- **회사**: EXANSYS Co., Ltd. ((주)엑사엔시스) — 모바일 앱 전문 개발사
- **목표**: 앱 전문 회사로 보이는 공식 홈페이지 + 앱 쇼케이스 + 커뮤니티 플랫폼
- **도메인**: https://exansys.net (Cloudflare에 등록 완료)
- **호스팅**: Cloudflare 무료 플랜 범위 내에서만 구현한다 (유료 기능 사용 금지)
- **배포**: GitHub 저장소 `exansys-site` → Cloudflare 자동 배포 (main 브랜치 push 시)

## 2. 기술 스택 (고정 — 임의 변경 금지)

| 영역 | 선택 | 비고 |
|---|---|---|
| 프론트엔드 | React + Vite + TypeScript | SPA + Workers Assets로 서빙 |
| 백엔드 API | Hono (Cloudflare Workers) | `/api/*` 라우트 |
| 데이터베이스 | **Cloudflare D1** (SQLite) | 무료: 5GB, 일 500만 read — 충분함 |
| ORM | Drizzle ORM | 마이그레이션은 `drizzle-kit` 사용 |
| 파일 저장 | Cloudflare R2 | 앱 아이콘, 스크린샷, 갤러리 이미지 (무료 10GB) |
| 세션/캐시 | Cloudflare KV | 로그인 세션 토큰 |
| 인증 | 소셜 간편로그인 (아래 4절) | 비밀번호 저장 방식 금지 |
| 스팸 방지 | Cloudflare Turnstile | 게시판 작성 폼에 적용 (무료) |
| 애니메이션 | Motion (framer-motion) + CSS | 과하지 않게 |
| 스타일 | Tailwind CSS | 디자인 토큰은 8절 참고 |
| QR 코드 | `qrcode` npm 패키지 | 서버에서 SVG 생성 |

> **답변: Cloudflare에서 DB 가능한가?** → 가능. D1이 무료 SQLite DB이고,
> 이 프로젝트의 게시판/댓글/카운터/회원 데이터 전부 D1 하나로 처리한다.

## 3. 사용자 역할 (권한 체계)

| 역할 | 설명 | 권한 |
|---|---|---|
| `guest` | 비로그인 방문자 | 공개 페이지 열람, 앱 다운로드 |
| `member` | 소셜 로그인한 일반 사용자 | 문의게시판 글/댓글 작성 |
| `crew` | 앱개발자 모임 회원 (관리자가 승격) | member 권한 + 내부 갤러리 접근/게시 |
| `staff` | EXANSYS 내부 직원 | crew 권한 + 개인정보처리방침 편집, 문의 답변 |
| `admin` | 대표 (최초 1명, 시드로 생성) | 전체 관리: 앱 등록/수정, 회원 승격, 글 삭제 |

## 4. 간편로그인 (인증)

- **방식**: OAuth 소셜 로그인만 제공 — Google, GitHub, 카카오 3종
- 자체 비밀번호 회원가입은 만들지 않는다 (보안 부담 제거)
- 흐름: OAuth 콜백 → D1 `users` 테이블 upsert → 세션 토큰 발급 → KV 저장 (30일) → HttpOnly Secure 쿠키
- OAuth 클라이언트 ID/Secret은 **wrangler secret**으로만 관리. 코드/레포에 절대 커밋 금지
- 신규 가입자는 기본 `member` 역할. `crew` 승격은 admin이 관리자 페이지에서 수동 처리

## 5. 핵심 기능 명세

### 5-1. 첫 페이지 = 대시보드형 홈 (요구 3)
- 히어로: 애니메이션 로고 (6절) + 캐치프레이즈 (영문)
- 대시보드 위젯: 등록된 앱 카드 그리드, 앱별 누적 다운로드 수 카운트업 애니메이션, 최근 문의글, 공지
- 스크롤 진입 애니메이션 (IntersectionObserver), `prefers-reduced-motion` 반드시 대응

### 5-2. 앱 쇼케이스 (요구 3, 9, 10)
- `apps` 테이블: 이름, 슬러그, 아이콘(R2), 스크린샷들, 소개, 스토어 링크(Play/App Store), 상태(개발중/출시)
- 앱 상세 페이지 `/apps/:slug`:
  - 스토어 이동 버튼 + **QR 코드 자동 생성** (스토어 링크 기준, SVG, 다운로드 가능 — 홍보물용)
  - **다운로드 카운터**: 스토어 이동 버튼 클릭 시 `/api/apps/:id/count` 호출로 +1 (IP+UA 기준 하루 1회 중복 방지)
  - 카운트는 대시보드와 상세 페이지에 표시

### 5-3. 개발문의게시판 (요구 2)
- 전역 게시판 `/contact`: 앱 외주/개발 문의용. 제목+내용+연락처(선택)
- 비공개 글 옵션 (작성자와 staff만 열람)
- staff 답변이 달리면 상태가 `답변완료`로 변경

### 5-4. 앱별 문의게시판 — 댓글형 (요구 7)
- 각 앱 상세 페이지 하단에 댓글형 스레드 (`app_comments` 테이블)
- 로그인(member 이상) 필요, 대댓글 1단계까지, staff 댓글은 "EXANSYS" 뱃지 표시

### 5-5. 개인정보처리방침 페이지 (요구 8)
- 앱마다 `/apps/:slug/privacy` 공개 URL 제공 → **Google Play Console에 이 URL을 등록**
- `staff` 이상 로그인 시 해당 페이지에 "편집" 버튼 노출 → 마크다운 에디터로 작성/수정, 버전 이력 저장
- 비로그인 사용자에겐 깔끔한 문서 뷰만 보임

### 5-6. 개발자 모임 내부 갤러리 (요구 11)
- `/crew` — `crew` 역할 이상만 접근 (비로그인·member는 안내 페이지)
- 회원들이 자기 앱을 게시 (이미지 + 설명 + 링크), 서로 댓글
- 목록은 카드형 갤러리, 이미지 R2 업로드 (최대 5MB, webp 변환)

## 6. 로고 (요구 4, 5)

- 콘셉트: **"EXANSYS" 워드마크 + 파이썬 뱀 무늬** — 뱀 비늘의 다이아몬드 패턴을 모티브로 한 SVG
- 구현: 인라인 SVG. `E` 또는 `X` 글자를 뱀이 감아 도는 형태, 비늘 패턴은 `<pattern>`으로
- 애니메이션:
  - 로드 시: 뱀 경로가 `stroke-dasharray`로 그려지는 draw 애니메이션 (약 1.6초, 1회)
  - 이후: 비늘 하이라이트가 흐르는 은은한 루프 (미묘하게 — 촌스럽지 않게)
  - 헤더의 작은 로고는 정적, 히어로의 큰 로고만 애니메이션
- 컬러: 딥그린(#0E5741) → 라임(#9BE15D) 그라디언트 비늘 + 잉크색 워드마크
- `prefers-reduced-motion`일 때는 완성된 정적 로고 즉시 표시

## 7. 디자인 원칙 (요구 6 — 사용자는 디자인 결정을 못 하므로 묻지 말 것)

- **디자인 관련 질문을 사용자에게 하지 않는다.** 아래 기준으로 Claude가 알아서 결정한다
- 한글 폰트: **Pretendard** (github.com/orioncactus/pretendard) — CDN 사용, 본문 전체
- 영문 디스플레이: Bricolage Grotesque (기존 랜딩과 통일)
- 참고할 GitHub/오픈소스 기준:
  - 폰트: orioncactus/pretendard
  - 컴포넌트 결: shadcn/ui 의 간결한 스타일을 Tailwind로 차용
  - 토스 프론트엔드 디자인 감성(넉넉한 여백, 큰 라운드, 절제된 색) 지향
- 색: 배경 #F6F7FA / 카드 #FFF / 잉크 #12141C / 포인트 딥그린·라임 (로고와 통일) / 기존 코발트는 링크·버튼 보조로 유지
- 라이트 모드 우선, 다크 모드는 Phase 3에서
- 모바일 퍼스트 반응형 (320px~), 앱 회사답게 모바일 화면 완성도 최우선

## 8. DB 스키마 요약 (Drizzle, D1)

users(id, provider, provider_id, name, avatar_url, role, created_at)
sessions는 KV 사용
apps(id, slug, name, tagline, description, icon_url, store_url_android, store_url_ios, status, download_count, created_at)
app_screenshots(id, app_id, image_url, sort)
app_comments(id, app_id, user_id, parent_id, body, created_at, deleted_at)
inquiries(id, user_id, title, body, contact, is_private, status, created_at)
inquiry_replies(id, inquiry_id, user_id, body, created_at)
privacy_policies(id, app_id, version, body_md, updated_by, updated_at)
gallery_posts(id, user_id, title, body, link_url, created_at)
gallery_images(id, post_id, image_url, sort)
gallery_comments(id, post_id, user_id, body, created_at)
download_logs(id, app_id, ip_hash, ua_hash, date)  -- 중복 방지용, 30일 후 정리

## 9. 개발 단계 (이 순서를 반드시 지킨다)

- **Phase 1 — 뼈대**: 프로젝트 셋업(Vite+Hono+D1+Drizzle), 배포 파이프라인 확인, 로고 SVG+애니메이션, 대시보드형 홈(정적 데이터)
- **Phase 2 — 인증/앱**: 소셜 로그인 3종, 관리자 페이지(앱 등록), 앱 쇼케이스+QR+다운로드 카운터
- **Phase 3 — 커뮤니티**: 개발문의게시판, 앱별 댓글, 개인정보처리방침 편집기
- **Phase 4 — 크루**: 내부 갤러리, 회원 승격 관리, 다크 모드
- 각 Phase 완료 시 main에 머지하고 exansys.net에서 동작 확인 후 다음 단계 진행

## 10. 코딩 규칙

- TypeScript strict 모드, ESLint + Prettier
- 커밋 메시지: 한국어, `기능:` `수정:` `디자인:` `문서:` 접두어
- 환경변수/시크릿은 `wrangler secret put`으로만. `.dev.vars`는 .gitignore에 포함
- API 응답은 `{ ok: boolean, data?, error? }` 형태 통일
- 모든 사용자 입력은 서버에서 검증 (zod), XSS 방지 위해 마크다운은 sanitize 후 렌더
- 이미지 업로드는 R2 presigned 방식, 확장자·용량 서버 검증
- 무료 플랜 한도(D1 read/write, Workers 요청 수)를 초과할 설계 금지

## 11. 하지 말 것

- 사용자에게 디자인/색상/폰트 선택을 묻지 않기 (7절 기준으로 결정)
- 자체 비밀번호 로그인 구현 금지
- 유료 Cloudflare 기능 사용 금지
- 개인정보(이메일 원문, IP 원본) DB 저장 금지 — 해시 처리
- 기존 랜딩 페이지 톤(신뢰감 있는 앱 전문 회사)을 깨는 화려한 이펙트 금지

## 12. 저장소 구성 — 웹과 앱

이 저장소는 **웹(exansys.net 사이트)** 과 **앱(apps/ 아래 독립 프로젝트들)** 로 나뉜다.
위 1~11절은 전부 **웹**에 대한 규칙이다. 앱 폴더에서 작업할 때는 **그 폴더의 CLAUDE.md/TECHSPEC.md가 우선**한다.

### 12-1. 웹 (exansys.net)

| 경로 | 내용 |
|---|---|
| `src/react-app/` | 사이트 프론트 (React SPA) — 홈·앱 쇼케이스(QR)·크루 갤러리·개발문의·AI교육·앱리뷰·TechDex 웹·VibeQuest 신고게시판/개인정보처리방침 |
| `src/worker/` | 백엔드 API (Hono, `/api/*`) — auth·apps·admin·crew·edu·techdex·vibequest 라우트 |
| `public/` | 정적 자산 — PWA(sw.js·manifest), `public/vibequest/`는 **Flutter 웹 빌드 산출물**(빌드 후 복사해 배포) |
| 배포 | main push → Cloudflare Workers Builds 자동 배포 (워커 gzip 1MB 한도 주의, `?raw` 번들 남용 금지) |
| 서브도메인 | techdex.exansys.net(운영), vibequest.exansys.net(CF 대시보드에서 커스텀 도메인 추가 시 /vibequest/로 자동 이동) |

### 12-2. 앱 (apps/ — 각자 독립 프로젝트)

| 앱 | 위치 | 상태 | 비고 |
|---|---|---|---|
| **VibeQuest** ⭐주력 | `apps/vibequest/` | **Play 스토어 출시 진행 중** | Flutter Android(net.exansys.vibequest) + 웹 PWA(exansys.net/vibequest/). 용어 867개 학습 게임. 자체 CLAUDE.md·TECHSPEC.md 필독. 제출 자료는 `store/`(앱정보.md·AAB·스크린샷). **서명키 `app/android/keystore/` 분실 금지** |
| **TechDex** | `apps/techdex/` | 유지보수만 | 1세대 용어 게임(웹 techdex.exansys.net + Flutter). **VibeQuest가 대체** — 신규 기능 금지, 버그만 수정 |
| **Exanode** | (코드는 별도 저장소) | **출시됨** | Play 스토어 스네이크 퍼즐(com.betona.crdl). 이 저장소에서는 사이트 쇼케이스(slug `crdl`)·홈 QR 배너로만 다룸 |

### 12-3. 앱 공통 규칙

- 콘텐츠(용어) 수정은 VibeQuest 파이프라인으로: `apps/vibequest/data/` 마스터 → 스크립트 → 워커 리소스 번들. 라이브 수정은 웹 신고게시판(관리자)이 오버라이드 → 앱이 원격 반영
- Flutter 버전 올릴 때 `pubspec.yaml`의 `+빌드번호` 반드시 증가
- Windows 빌드 함정: Kotlin 캐시락은 `kotlin.incremental=false`(gradle.properties, 이미 적용), Git Bash에서 `/경로` 인자는 `MSYS_NO_PATHCONV=1` 필요, 릴리스 매니페스트에 INTERNET 권한 확인

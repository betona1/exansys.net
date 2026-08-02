# CLAUDE.md — BookViewer (북뷰) 작업 규칙

이 저장소에서 작업하는 Claude(및 사람 개발자)를 위한 규칙서.
코드를 쓰기 전에 이 문서와 `BRAND.md`, `docs/SPEC.md`, `docs/techspec.md`, `docs/adr/*` 를 먼저 읽는다.

> **v0.2 변경 이력**: 초기 설계는 PySide6 데스크톱이었으나 **Flutter 크로스플랫폼**으로 전환했다.
> 예전 파이썬 스켈레톤은 `_to_delete/` 에 있으며 참고하지 않는다.

> **위치**: 이 프로젝트는 `exansys.net` 저장소의 `apps/bookviewer/` 안에 있다.
> 저장소 루트 `CLAUDE.md` 12절이 웹/앱을 나누며, **앱 폴더에서는 이 문서가 우선**한다.
> 아래 4절의 `BookViewer/` 는 `apps/bookviewer/` 를 가리킨다.
> `server/`(Django)는 아직 만들지 않았다.
>
> 엔진을 실제로 돌려 확인한 결과와 함정은 `docs/engine-verification.md` 에 있다.
> **코드를 쓰기 전에 그 문서도 읽는다.** 특히 pdfrx 점진 로드 함정은 모르면 반드시 당한다.

---

## 1. 한 줄 정의

PDF 를 "문서"가 아니라 **책**으로 읽는 앱. Android 폰·태블릿 우선, 데스크톱 동시 개발.
서버가 유튜브 강의를 **나만의 책(PDF)** 으로 만들어주고, 앱은 그것을 읽는다.

- 제작: **EXANSYS** — 매일 열게 되는, 작고 단단한 앱
- 개발자: 파이썬/앱 시니어 (본인)
- 배포: 무료 · 클로즈드소스 · **고정비 0** (미서명 배포, 무료 호스팅)

---

## 2. 절대 규칙

1. **AGPL 라이브러리를 넣지 않는다.** MuPDF/PyMuPDF 계열 금지.
   PDF 는 `pdfrx`(MIT, 내부 PDFium=BSD) 로만 다룬다. → ADR-0001
2. **원본 PDF 파일을 수정하지 않는다.** 주석은 앱 DB 에 저장하고, 내보낼 때만 **사본**에 쓴다. → ADR-0002
3. **DB 접속정보와 API 키는 `.env` 에서만 읽는다.**
   - Flutter: `--dart-define-from-file=.env.json` 또는 `flutter_dotenv`. **소스에 하드코딩 금지**
     - 실제로 쓰는 곳: `app/.env.json` (커밋 안 함) → `app/.env.example` 에 무엇을 적는지 적어 둔다.
       빌드할 때 반드시 `--dart-define-from-file=.env.json` 을 붙인다.
       지금 들어 있는 키: `ocrEndpoint`(OCR 서버 주소) · `ocrModel`(비전 모델)
   - ⚠ 클라이언트 번들은 디컴파일 가능하다. **MySQL 접속정보를 앱에 절대 넣지 않는다.**
     앱은 Django API 만 호출하고, DB 는 서버만 만진다. 이건 타협 대상이 아니다
   - Django: `python-dotenv`. `.env` 는 커밋 금지, 새 키는 `.env.example` 에 **한글 주석과 함께** 추가
4. **무거운 처리는 전부 서버에서.** yt-dlp / ffmpeg / whisper / OCR 은 앱에 넣지 않는다.
   모바일에서 돌지 않을뿐더러 앱 용량과 배터리를 파괴한다
5. **UI 스레드를 막지 않는다.** 렌더·파싱·인덱싱·해시계산은 `compute()` 또는 Isolate 로 뺀다
6. **브랜드 색 앰버(`#FFC24B`)를 버튼 텍스트·포커스·본문에 쓰지 않는다.**
   흰 배경 대비 1.8:1 로 WCAG 미달. 누르는 것은 `action #2F6BFF`. → BRAND.md §3.2
7. **작업(job)은 반드시 재개 가능해야 한다.** 영상→북 변환, OCR, 인덱싱은 단계별 체크포인트를
   DB 에 남긴다. 중간에 죽었을 때 처음부터 다시 도는 설계는 그 자체로 실패다

---

## 3. 확정 기술 결정 (바꾸려면 ADR 부터)

| 항목 | 결정 |
|---|---|
| 앱 | **Flutter** (Android 폰·태블릿 우선 → Windows/macOS 데스크톱 동시) |
| PDF | **pdfrx** (MIT / PDFium BSD). 텍스트선택·검색·링크·목차 내장 |
| 상태관리 | **Riverpod** |
| 로컬 DB | **Drift** + `sqlite3_flutter_libs` (FTS5 포함 SQLite 번들) |
| 서버 | **Django** (기존 스택). 영상→북 파이프라인 + 동기화 API |
| OCR | **Ollama 비전 모델**(`qwen2.5vl:7b`). 앱은 그림을 보내고 글자를 받을 뿐 — 추론은 서버에서 (§4). 실측·함정은 `docs/engine-verification.md` |
| 서버 DB | **MySQL** `192.168.219.200` (utf8mb4) |
| 검색 | FTS5 + **앱 레벨 bigram 정규화** (한국어). 토크나이저 교체 가능하게 추상화 |
| 주석 | 앱 DB 오버레이 → checksum 불일치 시 **자동 퍼지 재부착**, 실패분만 경고 |
| 주석 내보내기 | Markdown/Obsidian(딥링크) · **표준 PDF 주석**(재편집 가능) · 굽기(flatten) · JSON/CSV |
| 포맷 | **PDF 전용** (EPUB/CBZ 미지원) |
| 다크모드 | 휘도만 반전 + 이미지 영역 원본 복원 |
| LLM | **서버의 Ollama 로컬 모델만.** 클라우드 API 키 사용 안 함 |
| 브랜드 | EXANSYS · 캐릭터 EXA → `BRAND.md` |

---

## 4. 저장소 구조

```
BookViewer/
  BRAND.md                브랜드·캐릭터 (모든 디자인의 단일 진실 소스)
  CLAUDE.md               이 문서
  docs/                   SPEC / techspec / ADR / DB스키마.xlsx
  assets/brand/svg/       EXA 캐릭터 자산
  app/                    Flutter 앱
    lib/
      core/               설정, 상수, 예외, 테마, 라우팅
      data/               Drift DB, API 클라이언트, 리포지토리 구현
      domain/             엔티티, 유즈케이스, 리포지토리 인터페이스
      features/
        library/          서재, 메타데이터, 진행률
        reader/           페이지 뷰, 크롭, 다크모드, 선택
        search/           문서내/전체 검색, 인덱싱
        capture/          영역 캡처, 스마트 복사, 인용
        annotation/       하이라이트, 메모, 북마크, 내보내기
        bookmaker/        영상→북 (서버 작업 요청/진행/수신)
        settings/
      ui/                 공용 위젯, EXA 캐릭터 위젯, 디자인 토큰
  server/                 Django
    api/                  앱용 REST API
    bookmaker/            yt-dlp → whisper → scenedetect → OCR → PDF 파이프라인
    sync/                 MySQL 동기화
```

**의존 방향**: `features → domain → data`. UI 가 Drift/API 를 직접 부르지 않는다.

---

## 5. Flutter 코딩 컨벤션

- Dart 3.x, `flutter_lints` + `very_good_analysis`
- 이름: 클래스 `PascalCase`, 파일 `snake_case.dart`, 상수 `kCamelCase`
- **주석과 doc comment 는 한국어로.** 왜 그렇게 했는지를 적는다
- 위젯은 **`StatelessWidget` + Riverpod `Consumer`** 우선. `setState` 는 순수 로컬 UI 상태만
- `build()` 안에서 Provider 를 생성하지 않는다. `ref.watch` 로 구독만
- 화면 하나 = 파일 하나. 200줄 넘으면 위젯을 분리한다
- 색·간격·폰트는 **반드시 `AppTokens` 를 통해서** 쓴다. `Color(0xFF...)` 직접 작성 금지
- `Navigator.push` 대신 `go_router` 사용. 딥링크(`bookviewer://`) 를 여기서 받는다
- 에러는 `Result<T>` 또는 `AsyncValue` 로 다룬다. `catch (e) {}` 로 삼키지 않는다
- 반응형: `LayoutBuilder` 로 **compact(<600) / medium(600~1024) / expanded(≥1024)** 3분기.
  기기 종류로 분기하지 않는다 (폴더블·분할화면에서 깨진다)

---

## 6. 한국어 처리 — 자주 터지는 함정

텍스트를 다룰 때 `lib/core/korean.dart` 를 거치지 않으면 거의 확실히 버그가 난다.

1. **NFD 자모 분리** — macOS/iOS 유래 텍스트는 "한글"이 자모로 분해된다.
   NFC 정규화를 안 하면 검색이 그냥 안 된다
2. **라틴 리가처** — `fi`/`fl` 가 U+FB01 로 나와 검색·복사가 실패. NFKC 로 해소
3. **공백 소실** — 한글 PDF 는 어절 공백이 실제 space 가 아니라 글자 간격인 경우가 흔하다.
   인덱싱 시 공백 제거 사본을 함께 저장하고 질의도 같은 방식으로 폴백
4. **줄바꿈 결합** — 영어는 공백으로 잇고, **한글은 공백 없이 붙인다.**
   `\n` → `' '` 단순 치환 금지
5. **깨진 CID 폰트** — 한글 비율이 비정상적으로 낮으면 텍스트 레이어가 죽은 것. OCR 폴백 제안
6. **FTS5 토크나이저** — 기본 `unicode61` 은 조사 때문에 한국어에서 무용지물이다.
   인덱싱 전 **bigram 으로 쪼갠 그림자 텍스트**를 만들어 넣고, 질의도 같은 방식으로 변환한다
   (Dart 에서 커스텀 FTS5 토크나이저를 등록하기 어려우므로 앱 레벨에서 해결)

---

## 7. DB 규칙

- 스키마 변경은 Drift 스키마 · `docs/BookViewer_DB스키마.xlsx` · Django 모델 **셋을 함께** 갱신
- 필드명 영문, 설명 한글 주석
- 삭제는 `deleted_at` 소프트 삭제. 물리 삭제하면 동기화 시 다른 기기에서 되살아난다
- 동기화 기준 키는 `uuid`. AUTOINCREMENT `id` 는 기기마다 다르므로 절대 쓰지 않는다
- **주석은 append-only 이벤트로 저장**한다(생성/수정/삭제를 레코드로).
  그러면 병합이 자동으로 되고 충돌 해결 UI 자체가 필요 없어진다.
  실제로 충돌하는 것은 읽던 위치 하나뿐이고 그건 최신 우선(LWW)으로 충분하다
- FTS 인덱스는 **동기화하지 않는다.** 각 기기에서 로컬 재생성한다

---

## 8. 서버(Django) 규칙

- 영상→북 파이프라인은 **상태머신 + 체크포인트**로 만든다
  `QUEUED → FETCHING → TRANSCRIBING → SLIDES → OCR → COMPOSING → DONE / FAILED`
  각 단계 산출물을 디스크에 남겨 재시작 시 그 단계부터 재개한다
- yt-dlp 는 **바이너리를 별도 관리**하고 주기적으로 갱신한다 (유튜브 변경 대응 속도)
- **ffmpeg 는 반드시 LGPL 빌드를 쓴다.** `--enable-gpl` 로 빌드된 배포본(libx264 포함)은 GPL 이라
  클로즈드소스 제품에 묶는 순간 소스 공개 의무가 생긴다. PyMuPDF 를 막아놓고 여기서 뚫리면 의미가 없다
- 생성물은 **개인 학습용**임을 PDF 메타데이터와 첫 페이지에 명시하고, 원본 URL·채널·타임코드를 항상 남긴다
- API 는 토큰 인증. 앱에 MySQL 접속정보를 내려보내지 않는다

---

## 9. 테스트

- `flutter test` / `pytest`
- 반드시 테스트하는 것: **한국어 정규화·bigram 변환, 스마트 복사 한영 분기, 주석 앵커 재부착,
  크롭 좌표 계산, 검색 질의 라우팅, 진행률 계산**
- UI 위젯 테스트는 강제하지 않는다 (1인 개발 속도 우선). 순수 로직에 집중한다
- 테스트 PDF 코퍼스 10종을 `test/fixtures/` 에 둔다
  1) 한국어 텍스트 책 2) 한국어 스캔본 3) 한영 혼합 기술문서 4) 2단 논문 5) 수식 교재
  6) 표·이미지 보고서 7) 암호 PDF 8) 300MB 이상 9) 내부링크·목차 많은 PDF
  10) **기존 주석이 이미 들어있는 PDF** ← 내 오버레이와 어떻게 구분해 보여줄지 강제로 결정하게 만든다
  저작권 있는 책은 넣지 않는다

---

## 10. 응답/작업 방식 (Claude 에게)

- **10라인 이하 수정**: 고칠 부분만. 전체 파일 재출력 금지
- **100라인 이하**: 어느 파일 / 어느 함수(위젯) / 어디에 넣는지 명확히
- **100라인 이상**: 먼저 "전체 리팩토링 해서 드릴까요?" 묻고 승인 후 전체 코드
- 새 패키지를 제안할 때는 **라이선스 · pub points · 최근 업데이트**를 반드시 명시한다
- 최신 API·버전·라이선스는 추측하지 말고 웹 검색으로 확인한다
- 디자인 관련 작업은 `BRAND.md` 를 먼저 읽고, 거기 없는 색/형태를 새로 만들지 않는다

---

## 11. 커밋

```
feat(reader): 두 페이지 펼침 모드 추가
fix(search): NFD 자모분리로 한글 검색 실패하던 문제 수정
refactor(sync): 주석을 append-only 이벤트로 전환
docs(adr): ADR-0004 플랫폼 결정 추가
chore(brand): EXA 표정 세트 갱신
```
`.env`, `build/`, `.dart_tool/`, `data/`, `_to_delete/` 는 커밋하지 않는다.

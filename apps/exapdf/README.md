# ExaPDF / ExaPDF

> PDF 를 "문서"가 아니라 **책**으로 읽는 앱.
> 유튜브 강의를 **나만의 책**으로 만들어 같은 앱에서 학습한다.
>
> made by **EXANSYS** — 매일 열게 되는, 작고 단단한 앱

## 무엇을 해결하는가

1. 데스크톱·모바일 통틀어 **"책 읽기용" PDF 앱이 거의 없다.** 대부분 "문서 뷰어"다
2. 읽기 + 주석 + 노트 + **라이브러리 전체 검색**을 한 앱에서 하는 제품이 없다
3. **한국어를 제대로 처리하는 PDF 앱이 없다** — 조사한 어떤 앱도 신경 쓰지 않는다
4. 영상→노트 도구는 전부 클라우드 구독제이고 "내보내기가 제한적"이 1순위 불만이다
   → 우리는 **완전한 PDF 산출물 + 영구 소유**

## 스택

| 영역 | 선택 |
|---|---|
| 앱 | **Flutter** — Android 폰·태블릿 우선, Windows/macOS 동시 |
| PDF | **pdfrx** (MIT / PDFium BSD) — 6개 플랫폼, 텍스트선택·검색·링크·목차 내장 |
| 상태 / 로컬 DB | Riverpod + Drift (FTS5 포함 SQLite 번들) |
| 서버 | Django + MySQL — 영상→북 파이프라인, OCR, 동기화 |
| AI | 서버의 Ollama 로컬 모델 (클라우드 API 키 없음) |

## 구조

```
app/          Flutter 앱 (core / data / domain / features / ui)
server/       Django (api / bookmaker / sync)
docs/         SPEC · techspec · ADR · DB스키마.xlsx
assets/brand/ EXA 캐릭터 자산
BRAND.md      브랜드·캐릭터 (모든 디자인의 단일 진실 소스)
CLAUDE.md     작업 규칙
```

## 문서 읽는 순서

1. `CLAUDE.md` — 절대 규칙과 확정 결정
2. `docs/SPEC.md` — 무엇을 만드는가
3. `docs/techspec.md` — 화면·버튼·제스처·단축키
4. `BRAND.md` — 색·캐릭터·아이콘
5. `docs/adr/` — 왜 그렇게 정했는가

## 원칙

- **서버가 죽어도 "PDF 읽기"는 100% 동작한다.** 이건 설계 제약이다
- 원본 PDF 파일은 절대 수정하지 않는다
- 앱에 DB 접속정보를 넣지 않는다. 앱은 API 만 호출한다
- 무거운 처리(yt-dlp·whisper·ffmpeg·OCR)는 전부 서버에서
- AGPL 라이브러리를 넣지 않는다

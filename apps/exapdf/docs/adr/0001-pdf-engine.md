# ADR-0001. PDF 엔진: pdfrx (PDFium)

- 상태: 채택 (2026-08-01) / 대체: PySide6 QtPdf 안 폐기

## 배경
ExaPDF는 **무료 · 클로즈드소스**로 배포한다. 그리고 Android 우선 + 데스크톱 동시라
**한 코드베이스에서 6개 플랫폼**이 돌아야 한다.

- **MuPDF / PyMuPDF 계열은 AGPLv3 또는 카피당 과금 상용 라이선스다.** 배제 대상.
- Syncfusion Flutter PDF Viewer 는 완성도가 높지만 Community License 조건(매출·인원 제한)을
  벗어나면 유료이고 공급자 종속이 생긴다.

## 결정
**`pdfrx`** 를 단일 엔진으로 채택한다.

| 항목 | 확인값 (2026-08) |
|---|---|
| 라이선스 | **MIT** (내부 엔진 PDFium = BSD) |
| 최신 | 2.4.2 |
| 플랫폼 | Android / iOS / Windows / macOS / Linux / Web(WASM) |
| 기능 | 텍스트 선택, 검색, 링크, 문서 개요(목차), 페이지 조작 |
| 지표 | 주간 다운로드 292k, likes 331, verified publisher |

## 결과 / 대가
- ✅ 라이선스 리스크 0, 무료 배포 자유
- ✅ 모바일·데스크톱 동일 렌더 결과 (같은 PDFium)
- ❌ **주석 쓰기 API 가 없다** → 주석은 앱 DB 오버레이(ADR-0002),
  표준 PDF 주석 내보내기는 **서버(pikepdf)** 가 담당
- ❌ 표 추출·수식 인식 없음 → 서버 처리
- ⚠ 텍스트 추출 정밀도는 PDFium 수준. 한국어 공백 문제는 앱 레벨 정규화로 흡수(ADR-0003)

## 폐기된 대안
- PySide6 + QtPdf: 데스크톱 전용이라 플랫폼 결정과 함께 폐기.
  (참고: `QPdfView` 는 `PageMode` 가 `SinglePage`/`MultiPage` 뿐이고 텍스트 선택·두 페이지 펼침·
  주석 오버레이가 없어 어차피 커스텀 뷰포트가 필요했다)
- MuPDF 계열: AGPL. 논쟁 여지 없음

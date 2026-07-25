# 산출물 안내

- `TECHSPEC.md`: 앱 UX/UI와 기능 중심 전체 명세
- `GLOSSARY_AUDIT.md`: 기존 367개 문제점과 교정 결과
- `glossary_cleaned_367.json`: 기존 용어 교정본
- `glossary_additions_500.json`: 신규 용어 500개
- `glossary_master_867.json`: 앱 import용 통합 JSON
- `glossary_master_867.csv`: 엑셀 검수용 통합 CSV
- `glossary_validation_report.json`: 개수·중복·누락 자동 검증
- `build_vibe_terms.py`: 데이터 재생성 스크립트

권장 적용 순서:

1. 앱에서 `glossary_master_867.json`을 읽는다.
2. `id`를 사용자 숙련도 저장 키로 사용한다.
3. `volatile=true` 항목은 콘텐츠 업데이트 전에 재검수한다.
4. 문제 DB는 용어 DB와 분리한다.

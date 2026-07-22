# VibeQuest 출시 체크리스트

## ✅ 완료된 것
- [x] 서명 키 생성 (`app/android/keystore/vibequest-release.keystore` — **커밋 안 됨, 백업 필수!**)
- [x] 서명된 AAB 빌드: `app/build/app/outputs/bundle/release/app-release.aab`
- [x] 앱 아이콘 (어댑티브) · 스토어 아이콘 512 · 피처 그래픽
- [x] 개인정보처리방침 공개 URL: https://exansys.net/vibequest/privacy
- [x] 등록 문안: `listing.md`
- [x] 웹 PWA: https://exansys.net/vibequest/
- [x] 문제 신고 게시판: https://exansys.net/vibequest/reports

## ⬜ 대표님이 할 일 (Play Console)
1. **스크린샷 캡처** — 폰에서 인트로/홈/퀴즈/오답 설명/도감/결과 화면 (세로, 4~8장)
2. play.google.com/console → **앱 만들기** (이름: VibeQuest: AI·코딩 용어 퀘스트, 무료, 앱)
3. **프로덕션 → 새 버전** → `app-release.aab` 업로드
4. 스토어 등록정보: `listing.md` 내용 붙여넣기 + 그래픽 업로드
5. **데이터 보안** 설문: listing.md 하단 답변대로
6. 콘텐츠 등급 설문(교육, 전체이용가), 타겟 고객층(만 13세 이상 권장)
7. 개인정보처리방침 URL 입력
8. 검토 제출

> ⚠️ 신규 개인 개발자 계정은 프로덕션 전에 **비공개 테스트(테스터 12명, 14일)** 요건이 있을 수 있음 —
> 콘솔 안내에 따라 비공개 테스트 트랙부터 시작하세요. (crew 멤버들을 테스터로!)

## ⬜ 선택 작업
- [ ] vibequest.exansys.net 서브도메인: Cloudflare 대시보드 → Workers & Pages → exansys-site →
      Settings → Domains & Routes → **Add Custom Domain** → `vibequest.exansys.net` (한 번의 클릭이면 끝 —
      사이트가 자동으로 /vibequest/로 보내줍니다)
- [ ] 앱 버전 올릴 때: `pubspec.yaml`의 `version: 1.0.0+1` → `1.0.1+2` 식으로 (+빌드번호 필수 증가)

## 키 백업 (중요!)
아래 2개 파일을 잃어버리면 앱 업데이트를 영영 올릴 수 없습니다. 클라우드/USB 등 안전한 곳에 복사해 두세요.
- `apps/vibequest/app/android/keystore/vibequest-release.keystore`
- `apps/vibequest/app/android/key.properties`

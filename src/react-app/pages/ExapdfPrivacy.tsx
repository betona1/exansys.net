// ExaPDF 개인정보처리방침 — Google Play Console 등록용 공개 URL (/exapdf/privacy)
// 원문: apps/exapdf/docs/PRIVACY.md — 내용을 고치면 두 곳을 함께 고친다
export default function ExapdfPrivacy() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-14">
      <p className="mb-2 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">EXAPDF</p>
      <h1 className="font-display text-3xl font-extrabold tracking-tight">개인정보처리방침</h1>
      <p className="mt-2 text-sm text-muted">최종 수정: 2026년 8월 18일 · (주)엑사엔시스 (EXANSYS Co., Ltd.)</p>

      <div className="prose-sm mt-8 space-y-6 text-[15px] leading-relaxed text-ink/90">
        <section>
          <h2 className="font-display text-lg font-bold">한 줄 요약</h2>
          <p className="mt-2">
            <b>ExaPDF 는 여러분의 자료를 밖으로 보내지 않습니다.</b> 책도, 읽던 자리도, 칠한 것도
            전부 여러분 기기 안에만 있습니다. 계정 연결과 OCR 은 선택 기능이며, 쓰지 않으면
            앱은 네트워크를 사용하지 않습니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">1. 수집하지 않는 것</h2>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            <li>어떤 책을 읽는지, 얼마나 읽었는지 — 사용 기록·통계·분석 도구를 넣지 않았습니다</li>
            <li>광고 식별자, 위치, 연락처, 사진첩</li>
            <li>오류 보고 자동 전송</li>
          </ul>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">2. 기기 안에만 담기는 것</h2>
          <p className="mt-2">
            서재에 넣은 PDF 의 경로(웹에서는 파일 자체), 읽던 쪽·진행률·보기 설정, 칠한 곳·메모·북마크,
            검색용 본문 색인은 <b>여러분 기기에만</b> 저장되며 누구에게도 전송되지 않습니다.
            앱을 지우면 함께 사라집니다. 원본 PDF 파일은 앱이 고치지도, 지우지도 않습니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">3. 계정 연결 (선택)</h2>
          <p className="mt-2">
            스캔본 OCR 등 서버 기능을 쓰려는 경우에만 exansys.net 계정(소셜 로그인)을 연결합니다.
            이때 앱은 로그인 토큰과 프로필(이름·아바타·요금제)만 다루며, 읽는 책이나 주석을
            계정으로 전송하지 않습니다. 계정을 연결하지 않아도 읽기 기능 전부를 쓸 수 있습니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">4. 글자로 바꾸기(OCR)를 쓸 때</h2>
          <p className="mt-2">
            스캔본을 글자로 바꾸는 기능을 쓸 때만 해당 쪽의 그림이 OCR 서버로 전송됩니다.
            이 기능은 기본으로 꺼져 있으며, 직접 켜야 동작합니다. 전송된 그림은 글자 인식에만
            쓰이고 학습이나 다른 목적에 쓰이지 않습니다. 직접 지정한 사설 서버를 쓰는 경우
            그 서버의 취급은 서버 운영자의 방침을 따릅니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">5. 광고·분석·제3자 제공</h2>
          <p className="mt-2">
            앱은 광고를 게재하지 않으며, 외부 광고·분석 SDK를 사용하지 않습니다.
            수집 정보를 제3자에게 제공하지 않습니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">6. 저작권</h2>
          <p className="mt-2">
            ExaPDF 는 여러분이 가진 PDF 를 읽는 도구입니다. 권리 없는 자료를 넣어 쓰는 것에
            대한 책임은 사용자에게 있습니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">7. 어린이</h2>
          <p className="mt-2">만 14세 미만을 대상으로 하지 않으며, 나이를 묻지도 수집하지도 않습니다.</p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">8. 방침이 바뀌면</h2>
          <p className="mt-2">
            이 페이지와 앱 문서를 함께 고치고 위 "최종 수정" 날짜를 갱신합니다.
            수집 항목이 늘어나는 변경은 앱 안에서 따로 알려 드립니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">9. 문의</h2>
          <p className="mt-2">
            이메일: netkjy@gmail.com · 웹사이트: https://exansys.net
          </p>
        </section>
      </div>
    </main>
  );
}

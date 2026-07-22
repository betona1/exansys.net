// VibeQuest 개인정보처리방침 — Google Play Console 등록용 공개 URL (/vibequest/privacy)
export default function VqPrivacy() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-14">
      <p className="mb-2 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">VIBEQUEST</p>
      <h1 className="font-display text-3xl font-extrabold tracking-tight">개인정보처리방침</h1>
      <p className="mt-2 text-sm text-muted">시행일: 2026년 7월 22일 · (주)엑사엔시스 (EXANSYS Co., Ltd.)</p>

      <div className="prose-sm mt-8 space-y-6 text-[15px] leading-relaxed text-ink/90">
        <section>
          <h2 className="font-display text-lg font-bold">1. 개요</h2>
          <p className="mt-2">
            VibeQuest(이하 "앱")는 회원가입·로그인 없이 사용하는 학습 게임입니다.
            앱은 개인을 식별할 수 있는 정보(이름, 이메일, 전화번호 등)를 <b>수집하지 않습니다</b>.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">2. 기기에만 저장되는 정보</h2>
          <p className="mt-2">
            학습 진행도(숙련도·복습 일정·XP·보석·설정)는 <b>사용자 기기 내부에만</b> 저장되며
            서버로 전송되지 않습니다. 앱을 삭제하면 함께 삭제됩니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">3. 서버로 전송되는 정보</h2>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            <li>
              <b>콘텐츠 업데이트 확인</b>: 앱 실행 시 최신 용어 데이터 버전을 확인하기 위한 통신이 발생합니다.
              이 과정에서 개인정보는 전송되지 않습니다.
            </li>
            <li>
              <b>문제 오류 신고</b>(사용자가 직접 신고 버튼을 누른 경우): 신고한 용어 정보, 선택한 사유,
              사용자가 입력한 내용이 전송됩니다. 스팸 방지를 위해 IP 주소를 <b>복원 불가능한 해시로만</b> 처리·보관하며
              원본 IP는 저장하지 않습니다.
            </li>
          </ul>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">4. 광고·분석·제3자 제공</h2>
          <p className="mt-2">
            앱은 광고를 게재하지 않으며, 외부 광고·분석 SDK를 사용하지 않습니다.
            수집 정보를 제3자에게 제공하지 않습니다.
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">5. 아동의 개인정보</h2>
          <p className="mt-2">앱은 개인정보를 수집하지 않으므로 아동에 대한 별도 수집도 없습니다.</p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">6. 문의</h2>
          <p className="mt-2">
            개인정보 관련 문의: <a className="font-semibold text-cobalt hover:underline" href="mailto:contact@exansys.net">contact@exansys.net</a>
            {" "}또는 <a className="font-semibold text-cobalt hover:underline" href="/contact">개발 문의 게시판</a>
          </p>
        </section>
        <section>
          <h2 className="font-display text-lg font-bold">7. 방침 변경</h2>
          <p className="mt-2">방침이 변경되면 이 페이지를 통해 공지합니다.</p>
        </section>
      </div>
    </main>
  );
}

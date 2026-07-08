import SnakeLogo from "./components/SnakeLogo";
import Reveal from "./components/Reveal";
import CountUp from "./components/CountUp";
import { APPS, NOTICES, STATS, COMPANY } from "./data/site";

const statusStyle: Record<string, string> = {
  development: "bg-lime/25 text-green-deep",
  planning: "bg-amber-100 text-amber-800",
  available: "bg-cobalt/10 text-cobalt",
};

export default function App() {
  return (
    <>
      {/* ---------- 헤더 ---------- */}
      <header className="sticky top-0 z-50 border-b border-line bg-paper/85 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
          <a href="#top" aria-label="EXANSYS 홈">
            <SnakeLogo size={34} />
          </a>
          <nav aria-label="주 메뉴">
            <ul className="flex items-center gap-7 text-[15px] font-medium">
              <li className="hidden sm:block">
                <a className="text-muted transition hover:text-ink" href="#apps">앱</a>
              </li>
              <li className="hidden sm:block">
                <a className="text-muted transition hover:text-ink" href="#about">소개</a>
              </li>
              <li>
                <a
                  className="rounded-full bg-ink px-4.5 py-2 font-semibold text-white transition hover:bg-green"
                  href="#contact"
                >
                  개발 문의
                </a>
              </li>
            </ul>
          </nav>
        </div>
      </header>

      <main id="top">
        {/* ---------- 히어로 ---------- */}
        <section className="relative overflow-hidden">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute -top-40 right-[-10%] h-[520px] w-[520px] rounded-full opacity-60"
            style={{ background: "radial-gradient(circle, rgba(155,225,93,.22), transparent 65%)" }}
          />
          <div
            aria-hidden="true"
            className="pointer-events-none absolute bottom-[-30%] left-[-8%] h-[420px] w-[420px] rounded-full opacity-60"
            style={{ background: "radial-gradient(circle, rgba(14,87,65,.14), transparent 65%)" }}
          />
          <div className="mx-auto max-w-6xl px-6 pb-16 pt-20 text-center sm:pt-24">
            <div className="mb-8 flex justify-center">
              <SnakeLogo size={88} animated wordmark={false} />
            </div>
            <p className="mb-4 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">
              Mobile App Studio · Seoul
            </p>
            <h1 className="font-display mx-auto max-w-3xl text-4xl font-extrabold leading-[1.08] tracking-tight sm:text-6xl">
              Apps built to be
              <br />
              <span className="bg-gradient-to-r from-green to-lime bg-clip-text text-transparent">
                opened every day.
              </span>
            </h1>
            <p className="mx-auto mt-6 max-w-xl text-lg text-muted">
              엑사엔시스는 홈 화면에 남을 자격이 있는 앱을 만듭니다.
              작고, 빠르고, 믿을 수 있게 — 10년의 인프라 운영 경험 위에서.
            </p>
            <div className="mt-9 flex flex-wrap justify-center gap-3.5">
              <a
                href="#apps"
                className="rounded-full bg-green px-7 py-3.5 font-semibold text-white shadow-lg shadow-green/25 transition hover:bg-green-deep"
              >
                우리 앱 보기
              </a>
              <a
                href="#contact"
                className="rounded-full border-[1.5px] border-line bg-card px-7 py-3.5 font-semibold transition hover:border-ink"
              >
                개발 문의하기
              </a>
            </div>
          </div>
        </section>

        {/* ---------- 대시보드: 지표 ---------- */}
        <section className="border-y border-line bg-card">
          <div className="mx-auto grid max-w-6xl grid-cols-1 gap-px sm:grid-cols-3">
            {STATS.map((s) => (
              <Reveal key={s.label} className="px-6 py-10 text-center">
                <div className="font-display text-4xl font-extrabold text-green">
                  {s.plain ? s.value : <CountUp value={s.value} suffix={s.suffix ?? ""} />}
                </div>
                <div className="mt-1.5 text-sm text-muted">{s.label}</div>
              </Reveal>
            ))}
          </div>
        </section>

        {/* ---------- 대시보드: 앱 + 소식 ---------- */}
        <section id="apps" className="mx-auto max-w-6xl px-6 py-20">
          <Reveal className="mb-12 max-w-xl">
            <p className="mb-3 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">
              Our Apps
            </p>
            <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
              집중된 도구, 군더더기 없이.
            </h2>
            <p className="mt-4 text-muted">
              Android와 iOS에서 직접 설계하고 출시하는 앱들입니다. 매일 쓰는 단순한
              도구가, 한 번 쓰고 마는 복잡한 도구를 이깁니다.
            </p>
          </Reveal>

          <div className="grid gap-6 lg:grid-cols-3">
            {/* 앱 카드 */}
            <div className="grid gap-5 sm:grid-cols-2 lg:col-span-2 lg:grid-cols-2">
              {APPS.map((app) => (
                <Reveal
                  key={app.name}
                  className="rounded-2xl border border-line bg-card p-7 transition hover:-translate-y-1 hover:shadow-xl hover:shadow-ink/8"
                >
                  <div
                    className="mb-5 grid h-13 w-13 place-items-center rounded-xl text-2xl"
                    style={{ background: app.tint }}
                  >
                    {app.emoji}
                  </div>
                  <h3 className="font-display mb-2 text-xl font-bold">{app.name}</h3>
                  <p className="mb-4 text-[15px] text-muted">{app.description}</p>
                  <span
                    className={`inline-block rounded-full px-3 py-1 text-xs font-semibold ${statusStyle[app.status]}`}
                  >
                    {app.statusLabel}
                  </span>
                </Reveal>
              ))}
            </div>

            {/* 사이드: 공지 + 문의 안내 */}
            <div className="flex flex-col gap-5">
              <Reveal className="rounded-2xl border border-line bg-card p-7">
                <h3 className="font-display mb-4 text-lg font-bold">공지</h3>
                <ul className="space-y-3.5">
                  {NOTICES.map((n) => (
                    <li key={n.text} className="flex gap-3 text-sm">
                      <span className="shrink-0 font-semibold text-green">{n.date}</span>
                      <span className="text-muted">{n.text}</span>
                    </li>
                  ))}
                </ul>
              </Reveal>
              <Reveal className="rounded-2xl border border-dashed border-line bg-paper p-7">
                <h3 className="font-display mb-2 text-lg font-bold">문의게시판</h3>
                <p className="text-sm text-muted">
                  소셜 로그인과 함께 준비 중입니다. 지금은{" "}
                  <a className="font-semibold text-cobalt hover:underline" href="#contact">
                    이메일로 문의
                  </a>
                  해 주세요.
                </p>
              </Reveal>
            </div>
          </div>
        </section>

        {/* ---------- 소개 ---------- */}
        <section id="about" className="border-y border-line bg-card">
          <div className="mx-auto max-w-6xl px-6 py-20">
            <Reveal className="mb-12 max-w-2xl">
              <p className="mb-3 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">
                About EXANSYS
              </p>
              <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
                10년간 시스템을 지켜온 손으로,
                <br />
                이제 앱을 만듭니다.
              </h2>
              <p className="mt-4 text-muted">
                2016년 서울에서 창립한 엑사엔시스는 컴퓨터 시스템 유지보수, 통신망
                구축 등 비즈니스가 기대는 인프라를 오래 다뤄왔습니다. 그 신뢰성의
                감각이 지금 우리가 만드는 모든 모바일 앱에 담깁니다.
              </p>
            </Reveal>
            <div className="grid gap-5 sm:grid-cols-3">
              {[
                { title: "작고 빠르게", body: "빨리 열리고 바로 쓰이는 앱. 기능 욕심보다 완성도." },
                { title: "광고 없이, 공정하게", body: "광고와 다크 패턴 없이 정직한 가격으로 운영합니다." },
                { title: "오래 가게", body: "인프라를 지켜온 규율로, 출시 후에도 꾸준히 관리합니다." },
              ].map((p) => (
                <Reveal key={p.title} className="rounded-2xl border border-line bg-paper p-7">
                  <h3 className="font-display mb-2 text-lg font-bold text-green">{p.title}</h3>
                  <p className="text-sm text-muted">{p.body}</p>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* ---------- 문의 ---------- */}
        <section id="contact" className="bg-ink text-white">
          <div className="mx-auto max-w-6xl px-6 py-20">
            <Reveal className="max-w-xl">
              <p className="mb-3 text-[13px] font-semibold uppercase tracking-[0.18em] text-lime">
                Contact
              </p>
              <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
                앱 이야기를 나눠요.
              </h2>
              <p className="mt-4 text-white/65">
                앱에 대한 질문, 파트너십, 만들고 싶은 프로젝트 — 모든 메일에
                답장합니다.
              </p>
              <div className="mt-8">
                <a
                  className="inline-block rounded-full bg-lime px-7 py-3.5 font-bold text-green-deep transition hover:brightness-95"
                  href={`mailto:${COMPANY.email}`}
                >
                  {COMPANY.email}
                </a>
              </div>
              <p className="mt-5 text-sm text-white/45">{COMPANY.addressEn}</p>
            </Reveal>
          </div>
        </section>
      </main>

      {/* ---------- 푸터 ---------- */}
      <footer className="border-t border-white/10 bg-ink pb-11 pt-9 text-[13.5px] leading-relaxed text-white/55">
        <div className="mx-auto flex max-w-6xl flex-wrap justify-between gap-5 px-6">
          <div>
            <div className="mb-2">
              <SnakeLogo size={26} className="[&_span]:!text-white" />
            </div>
            <span className="block">
              {COMPANY.nameEn} ({COMPANY.nameKo})
            </span>
            <span className="block">
              대표: {COMPANY.ceo} · 사업자등록번호 {COMPANY.bizNo}
            </span>
            <span className="block">{COMPANY.addressEn}</span>
          </div>
          <div className="space-y-1">
            <a className="block text-white/75 hover:text-white" href="#apps">앱</a>
            <a className="block text-white/75 hover:text-white" href="#about">소개</a>
            <a className="block text-white/75 hover:text-white" href={`mailto:${COMPANY.email}`}>
              {COMPANY.email}
            </a>
            <span className="block pt-2">© 2026 EXANSYS Co., Ltd. All rights reserved.</span>
          </div>
        </div>
      </footer>
    </>
  );
}

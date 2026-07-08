import { useEffect, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import SnakeLogo from "../components/SnakeLogo";
import Reveal from "../components/Reveal";
import CountUp from "../components/CountUp";
import { APPS, NOTICES, STATS, COMPANY } from "../data/site";
import { api, STATUS_LABEL, type AppRow } from "../lib/api";

const statusStyle: Record<string, string> = {
  development: "bg-lime/25 text-green-deep",
  planning: "bg-amber-100 text-amber-800",
  released: "bg-cobalt/10 text-cobalt",
  available: "bg-cobalt/10 text-cobalt",
};

export default function Home() {
  const [dbApps, setDbApps] = useState<AppRow[]>([]);
  const location = useLocation();

  useEffect(() => {
    void api<{ apps: AppRow[] }>("/api/apps").then((res) => {
      if (res.ok) setDbApps(res.data.apps);
    });
  }, []);

  // /#apps 형태의 해시 이동 지원
  useEffect(() => {
    if (location.hash) {
      document.querySelector(location.hash)?.scrollIntoView({ behavior: "smooth" });
    }
  }, [location.hash]);

  return (
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
      <section id="apps" className="mx-auto max-w-6xl scroll-mt-20 px-6 py-20">
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
          <div className="grid gap-5 sm:grid-cols-2 lg:col-span-2 lg:grid-cols-2">
            {dbApps.length > 0
              ? dbApps.map((app) => (
                  <Reveal
                    key={app.id}
                    className="rounded-2xl border border-line bg-card p-7 transition hover:-translate-y-1 hover:shadow-xl hover:shadow-ink/8"
                  >
                    <Link to={`/apps/${app.slug}`} className="block">
                      <div className="mb-5 grid h-13 w-13 place-items-center overflow-hidden rounded-xl bg-lime/15 text-2xl">
                        {app.iconUrl?.startsWith("http") ? (
                          <img src={app.iconUrl} alt="" className="h-full w-full object-cover" />
                        ) : (
                          <span>{app.iconUrl || "📱"}</span>
                        )}
                      </div>
                      <h3 className="font-display mb-2 text-xl font-bold">{app.name}</h3>
                      <p className="mb-4 text-[15px] text-muted">{app.tagline}</p>
                      <div className="flex items-center gap-2.5">
                        <span
                          className={`inline-block rounded-full px-3 py-1 text-xs font-semibold ${statusStyle[app.status]}`}
                        >
                          {STATUS_LABEL[app.status]}
                        </span>
                        {app.status === "released" && (
                          <span className="text-xs font-semibold text-muted">
                            ⬇ <CountUp value={app.downloadCount} />
                          </span>
                        )}
                      </div>
                    </Link>
                  </Reveal>
                ))
              : APPS.map((app) => (
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
                Phase 3에서 열립니다. 지금은{" "}
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
      <section id="about" className="scroll-mt-20 border-y border-line bg-card">
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
      <section id="contact" className="scroll-mt-20 bg-ink text-white">
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
  );
}

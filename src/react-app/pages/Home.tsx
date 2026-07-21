import { useEffect, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import SnakeLogo from "../components/SnakeLogo";
import Reveal from "../components/Reveal";
import CountUp from "../components/CountUp";
import Faq from "../components/Faq";
import PhoneScene from "../components/PhoneScene";
import { APPS, NOTICES, STATS, COMPANY } from "../data/site";
import { api, STATUS_LABEL, type AppRow } from "../lib/api";

const statusStyle: Record<string, string> = {
  development: "bg-lime/25 text-green-deep",
  planning: "bg-amber-100 text-amber-800",
  released: "bg-cobalt/10 text-cobalt",
  available: "bg-cobalt/10 text-cobalt",
};

/** 챕터 헤더 — 이모지 뱃지 + 그라디언트 키워드 (alar.my 스타일) */
function ChapterHead({
  emoji,
  label,
  line1,
  accent,
  dark = false,
}: {
  emoji: string;
  label: string;
  line1: string;
  accent: string;
  dark?: boolean;
}) {
  return (
    <Reveal className="mx-auto mb-14 max-w-2xl text-center">
      <p
        className={`mb-5 inline-flex items-center gap-2 text-[15px] font-bold ${dark ? "text-white/70" : "text-muted"}`}
      >
        <span className="text-xl">{emoji}</span> {label}
      </p>
      <h2
        className={`font-display text-3xl font-extrabold leading-[1.2] tracking-tight sm:text-[2.6rem] ${dark ? "text-white" : ""}`}
      >
        {line1}
        <br />
        <span className="bg-gradient-to-r from-green to-lime bg-clip-text text-transparent">
          {accent}
        </span>
      </h2>
    </Reveal>
  );
}

export default function Home() {
  const [dbApps, setDbApps] = useState<AppRow[]>([]);
  const location = useLocation();

  useEffect(() => {
    void api<{ apps: AppRow[] }>("/api/apps").then((res) => {
      if (res.ok) setDbApps(res.data.apps);
    });
  }, []);

  useEffect(() => {
    if (location.hash) {
      document.querySelector(location.hash)?.scrollIntoView({ behavior: "smooth" });
    }
  }, [location.hash]);

  const featured = dbApps[0];
  const rest = dbApps.slice(1);

  return (
    <main id="top">
      {/* ---------- 히어로 (대형 헤드라인 + 폰 목업 패널) ---------- */}
      <section className="px-3 pt-6 sm:px-6">
        <div className="hero-panel relative mx-auto max-w-[1400px] overflow-hidden rounded-[2.5rem] px-6 pt-16 text-center sm:pt-24">
          <div className="mb-7 flex justify-center">
            <SnakeLogo size={72} animated wordmark={false} />
          </div>
          <h1 className="font-display mx-auto max-w-3xl text-[2.5rem] font-extrabold leading-[1.12] tracking-tight sm:text-6xl">
            매일 열게 되는
            <br />단 하나의 앱
          </h1>
          <p className="mx-auto mt-5 max-w-xl text-base text-muted sm:text-lg">
            한국에서 만들고 매일 쓰이는 — Apps built to be opened every day.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-3">
            <a
              href="#apps"
              className="rounded-xl bg-ink px-6 py-3.5 text-[15px] font-semibold text-white transition hover:bg-green"
            >
              우리 앱 보기
            </a>
            <a
              href="#contact"
              className="rounded-xl border border-ink/15 bg-white/70 px-6 py-3.5 text-[15px] font-semibold backdrop-blur transition hover:border-ink"
            >
              개발 문의하기
            </a>
          </div>

          <PhoneScene />
        </div>
        <p className="mt-6 text-center text-[11px] font-bold tracking-[0.2em] text-muted">
          SCROLL DOWN ↓
        </p>
      </section>

      {/* ---------- 출시 앱 설치 배너 (Play + QR, 데스크톱에서 크게) ---------- */}
      {featured?.status === "released" && featured.storeUrlAndroid && (
        <section className="px-3 pt-8 sm:px-6 sm:pt-14">
          <Reveal className="mx-auto flex max-w-[1100px] flex-col items-center gap-8 rounded-[2rem] border border-green/25 bg-gradient-to-br from-green/10 to-lime/15 p-7 sm:flex-row sm:justify-between sm:gap-12 sm:p-12">
            <div className="flex flex-col items-center gap-5 text-center sm:flex-row sm:items-center sm:gap-6 sm:text-left">
              <div className="grid h-24 w-24 shrink-0 place-items-center overflow-hidden rounded-[1.4rem] bg-white text-5xl shadow-lg sm:h-28 sm:w-28">
                {/^(https?:\/\/|\/)/.test(featured.iconUrl ?? "") ? (
                  <img src={featured.iconUrl!} alt="" className="h-full w-full object-cover" />
                ) : (
                  <span>{featured.iconUrl || "📱"}</span>
                )}
              </div>
              <div>
                <span className="inline-block rounded-full bg-green px-3 py-1 text-xs font-bold text-white">🎉 새 앱 출시</span>
                <h2 className="font-display mt-3 text-3xl font-extrabold tracking-tight sm:text-5xl">{featured.name}</h2>
                <p className="mt-2 max-w-md text-[15px] text-muted sm:text-lg">{featured.tagline}</p>
                <a
                  href={featured.storeUrlAndroid}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-5 inline-block rounded-2xl bg-ink px-7 py-4 text-base font-semibold text-white transition hover:bg-green sm:text-lg"
                >
                  ▶ Google Play에서 받기
                </a>
              </div>
            </div>
            <div className="shrink-0 text-center">
              <img
                src={`/api/apps/${featured.slug}/qr?platform=android`}
                alt={`${featured.name} Google Play 설치 QR 코드`}
                className="h-44 w-44 rounded-2xl border border-line bg-white p-2 shadow-md sm:h-56 sm:w-56"
              />
              <p className="mt-3 text-sm font-semibold text-green-deep">📷 폰으로 스캔하면 바로 설치</p>
            </div>
          </Reveal>
        </section>
      )}

      {/* ---------- 소셜 프루프 + 지표 ---------- */}
      <section className="px-6 py-24 text-center sm:py-32">
        <Reveal className="mx-auto max-w-3xl">
          <h2 className="font-display text-3xl font-extrabold leading-[1.25] tracking-tight sm:text-[2.6rem]">
            2016년부터 시스템을 지켜온 팀이 만드는
            <br />
            <span className="bg-gradient-to-r from-green to-lime bg-clip-text text-transparent">
              신뢰할 수 있는 앱
            </span>
          </h2>
          <p className="mt-5 text-muted">
            하루의 시작과 끝에 함께할 앱을 준비하고 있습니다.
            <br />
            10년의 IT 인프라 운영 규율을 그대로 모바일에 담습니다.
          </p>
        </Reveal>
        <div className="mx-auto mt-14 grid max-w-4xl grid-cols-1 gap-4 sm:grid-cols-3">
          {STATS.map((s) => (
            <Reveal key={s.label} className="rounded-3xl border border-line bg-card px-6 py-9">
              <div className="font-display text-4xl font-extrabold text-green">
                {s.plain ? s.value : <CountUp value={s.value} suffix={s.suffix ?? ""} />}
              </div>
              <div className="mt-1.5 text-sm text-muted">{s.label}</div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* ---------- 챕터 1: 앱 (벤토 그리드) ---------- */}
      <section id="apps" className="scroll-mt-20 px-6 pb-24">
        <div className="mx-auto max-w-6xl">
          <ChapterHead
            emoji="📱"
            label="OUR APPS"
            line1="군더더기 없이"
            accent="확실하게 쓰이니까"
          />

          <div className="grid gap-5 lg:grid-cols-2">
            {/* 큰 카드: 대표 앱 */}
            <Reveal className="rounded-[2rem] bg-paper-deep bg-card p-9 shadow-sm ring-1 ring-line lg:row-span-2">
              {featured ? (
                <>
                  <Link to={`/apps/${featured.slug}`} className="block">
                    <p className="mb-2 text-sm font-bold text-green">⏰ {STATUS_LABEL[featured.status]}</p>
                    <h3 className="font-display text-2xl font-extrabold leading-snug">
                      {featured.name}
                    </h3>
                    <p className="mt-3 max-w-md text-[15px] text-muted">{featured.tagline}</p>
                    <div className="mt-8 grid h-64 place-items-center overflow-hidden rounded-2xl bg-gradient-to-b from-paper to-lime/15 text-7xl">
                      {/^(https?:\/\/|\/)/.test(featured.iconUrl ?? "") ? (
                        <img src={featured.iconUrl} alt="" className="h-28 w-28 rounded-3xl object-cover shadow-xl" />
                      ) : (
                        <span>{featured.iconUrl || "📱"}</span>
                      )}
                    </div>
                  </Link>
                  {featured.storeUrlAndroid && (
                    <div className="mt-6 flex flex-col items-center gap-5 rounded-2xl border border-line bg-paper/60 p-5 sm:flex-row sm:justify-between">
                      <div className="flex-1 text-center sm:text-left">
                        <p className="font-display text-base font-extrabold">지금 설치하기</p>
                        <p className="mt-1 text-sm text-muted">Google Play에서 받거나, 폰으로 QR을 스캔하세요.</p>
                        <a
                          href={featured.storeUrlAndroid}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-4 inline-block rounded-xl bg-ink px-5 py-3 text-sm font-semibold text-white transition hover:bg-green"
                        >
                          ▶ Google Play에서 받기
                        </a>
                      </div>
                      <div className="text-center">
                        <img
                          src={`/api/apps/${featured.slug}/qr?platform=android`}
                          alt={`${featured.name} Google Play QR 코드`}
                          className="h-32 w-32 rounded-xl border border-line bg-white p-1.5"
                        />
                        <p className="mt-2 text-xs font-medium text-muted">📷 QR 스캔 설치</p>
                      </div>
                    </div>
                  )}
                </>
              ) : (
                <>
                  <p className="mb-2 text-sm font-bold text-green">⏰ 개발 중 · 2026 출시 목표</p>
                  <h3 className="font-display text-2xl font-extrabold leading-snug">
                    눈이 저절로 가는
                    <br />
                    데일리 생산성 컴패니언
                  </h3>
                  <p className="mt-3 max-w-md text-[15px] text-muted">
                    오프라인 우선, 광고 없음, 다크 패턴 없음. 홈 화면 첫 줄에 남는
                    것이 목표입니다.
                  </p>
                  <div className="mt-8 grid grid-cols-4 gap-3">
                    {[
                      ["✅", "할 일"],
                      ["⏱️", "루틴"],
                      ["📊", "리포트"],
                      ["🔔", "리마인더"],
                      ["📆", "일정"],
                      ["🌙", "집중"],
                      ["📝", "메모"],
                      ["☁️", "동기화"],
                    ].map(([icon, name]) => (
                      <div key={name} className="text-center">
                        <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-paper text-2xl shadow-sm ring-1 ring-line">
                          {icon}
                        </div>
                        <div className="mt-1.5 text-xs font-medium text-muted">{name}</div>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </Reveal>

            {/* 작은 카드들 */}
            {rest.length > 0 ? (
              rest.slice(0, 2).map((app) => (
                <Reveal key={app.id} className="rounded-[2rem] bg-card p-8 shadow-sm ring-1 ring-line">
                  <Link to={`/apps/${app.slug}`} className="block">
                    <span className={`mb-3 inline-block rounded-full px-3 py-1 text-xs font-semibold ${statusStyle[app.status]}`}>
                      {STATUS_LABEL[app.status]}
                    </span>
                    <h3 className="font-display text-xl font-extrabold">{app.name}</h3>
                    <p className="mt-2 text-[15px] text-muted">{app.tagline}</p>
                  </Link>
                </Reveal>
              ))
            ) : (
              APPS.slice(1).map((app) => (
                <Reveal key={app.name} className="rounded-[2rem] bg-card p-8 shadow-sm ring-1 ring-line">
                  <span className={`mb-3 inline-block rounded-full px-3 py-1 text-xs font-semibold ${statusStyle[app.status]}`}>
                    {app.statusLabel}
                  </span>
                  <h3 className="font-display text-xl font-extrabold">
                    {app.emoji} {app.name}
                  </h3>
                  <p className="mt-2 text-[15px] text-muted">{app.description}</p>
                </Reveal>
              ))
            )}
          </div>
        </div>
      </section>

      {/* ---------- 챕터 2: 원칙 (다크 섹션) ---------- */}
      <section id="about" className="scroll-mt-20 bg-ink px-6 py-24 sm:py-28">
        <div className="mx-auto max-w-6xl">
          <ChapterHead
            emoji="🌙"
            label="OUR CRAFT"
            line1="오래 쓰여야"
            accent="좋은 앱이니까"
            dark
          />
          <div className="grid gap-5 sm:grid-cols-3">
            {[
              {
                icon: "🚫",
                title: "광고 없음, 영원히",
                body: "광고와 다크 패턴 없이 정직한 가격으로만 운영합니다. 사용자의 아침을 광고로 시작하게 하지 않습니다.",
              },
              {
                icon: "⚡",
                title: "오프라인 우선",
                body: "네트워크가 없어도 바로 열리고 바로 쓰입니다. 빠른 실행 속도는 협상하지 않습니다.",
              },
              {
                icon: "🔧",
                title: "출시 후가 진짜",
                body: "10년간 인프라를 지켜온 규율로, 출시한 앱은 꾸준히 업데이트하고 관리합니다.",
              },
            ].map((p) => (
              <Reveal key={p.title} className="rounded-[2rem] bg-white/[0.06] p-8 ring-1 ring-white/10">
                <div className="mb-4 text-3xl">{p.icon}</div>
                <h3 className="font-display text-lg font-bold text-white">{p.title}</h3>
                <p className="mt-2.5 text-sm leading-relaxed text-white/60">{p.body}</p>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* ---------- 공지 + 문의게시판 ---------- */}
      <section className="px-6 py-20">
        <div className="mx-auto grid max-w-6xl gap-5 sm:grid-cols-2">
          <Reveal className="rounded-[2rem] border border-line bg-card p-8">
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
          <Reveal className="rounded-[2rem] border border-line bg-card p-8">
            <h3 className="font-display mb-2 text-lg font-bold">개발 문의게시판</h3>
            <p className="text-sm text-muted">
              앱 외주 개발·파트너십 문의를 게시판으로 받습니다. 비공개 글도 지원하며,
              모든 문의에 답변합니다.
            </p>
            <Link to="/contact"
              className="mt-4 inline-block rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green">
              문의 게시판 가기 →
            </Link>
          </Reveal>
        </div>
      </section>

      {/* ---------- FAQ ---------- */}
      <section className="px-6 pb-24">
        <div className="mx-auto max-w-3xl">
          <ChapterHead emoji="💬" label="FAQ" line1="자주 묻는" accent="질문들" />
          <Faq
            items={[
              {
                q: "EXANSYS는 어떤 회사인가요?",
                a: "2016년 서울에서 창립한 모바일 앱 전문 개발사입니다. 10년간 컴퓨터 시스템 유지보수와 통신망 구축 등 IT 인프라를 다뤄왔고, 지금은 그 신뢰성의 감각으로 모바일 앱을 만드는 데 집중하고 있습니다.",
              },
              {
                q: "첫 앱은 언제 출시되나요?",
                a: "데일리 생산성 컴패니언 앱을 2026년 출시 목표로 개발하고 있습니다. 출시 소식은 이 홈페이지 공지에서 가장 먼저 알려드립니다.",
              },
              {
                q: "앱 외주 개발도 하나요?",
                a: "네. 아이디어 정리부터 기획·디자인·개발·스토어 출시까지 전 과정을 함께합니다. 아래 이메일로 만들고 싶은 앱을 알려주세요.",
              },
              {
                q: "앱은 정말 광고가 없나요?",
                a: "네. 저희가 직접 만드는 앱에는 광고와 다크 패턴을 넣지 않습니다. 필요한 경우 정직한 구독/구매 모델로만 운영합니다.",
              },
              {
                q: "출시된 앱의 개인정보처리방침은 어디서 보나요?",
                a: "각 앱 상세 페이지에서 공개 문서로 제공할 예정입니다 (Phase 3). Google Play·App Store 등록 정보에서도 같은 링크를 확인할 수 있게 됩니다.",
              },
            ]}
          />
        </div>
      </section>

      {/* ---------- 최종 CTA ---------- */}
      <section id="contact" className="scroll-mt-20 px-3 pb-8 sm:px-6">
        <div className="cta-panel mx-auto max-w-[1400px] rounded-[2.5rem] px-6 py-24 text-center">
          <Reveal>
            <div className="mb-6 flex justify-center">
              <SnakeLogo size={64} wordmark={false} />
            </div>
            <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
              함께 만들 앱이 있나요?
            </h2>
            <p className="mx-auto mt-4 max-w-md text-muted">
              앱에 대한 질문, 파트너십, 만들고 싶은 프로젝트 — 모든 메일에 답장합니다.
            </p>
            <div className="mt-8">
              <a
                className="inline-block rounded-xl bg-ink px-7 py-4 font-semibold text-white transition hover:bg-green"
                href={`mailto:${COMPANY.email}`}
              >
                {COMPANY.email}
              </a>
            </div>
            <p className="mt-6 text-xs text-ink/40">{COMPANY.addressEn}</p>
          </Reveal>
        </div>
      </section>
    </main>
  );
}

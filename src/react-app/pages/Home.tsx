import { useEffect, useState } from "react";
import AppGallery, { youtubeEmbed } from "../components/AppGallery";
import { pick, useLang } from "../lib/i18n";
import { Link, useLocation } from "react-router-dom";
import BrandLogo from "../components/BrandLogo";
import Mascot from "../components/Mascot";
import Reveal from "../components/Reveal";
import CountUp from "../components/CountUp";
import Faq from "../components/Faq";
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

/** 지표 라벨 — 순서대로 창립·경력·프로젝트 */
const STAT_KEYS = ["stats.founded", "stats.experience", "stats.projects"] as const;

export default function Home() {
  const { t, lang } = useLang();
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

  // 히어로에 세울 앱: featured 지정 > 영상 있는 앱 > 첫 앱
  const heroApp =
    dbApps.find((a) => a.featured) ?? dbApps.find((a) => a.videoUrl?.trim()) ?? dbApps[0];
  // 유튜브는 배경 자동재생에 못 쓰므로 mp4 계열만 배경으로 깐다
  const heroVideoSrc =
    heroApp?.videoUrl?.trim() && !youtubeEmbed(heroApp.videoUrl) ? heroApp.videoUrl : null;
  // 영문이 비어 있으면 한글 값을 그대로 쓴다
  const heroName = heroApp ? pick(lang, heroApp.nameEn, heroApp.name) || heroApp.name : null;
  const heroTagline = heroApp ? pick(lang, heroApp.taglineEn, heroApp.tagline) : "";
  const featured = dbApps[0];
  const rest = dbApps.slice(1);

  return (
    <main id="top">
      {/* ---------- 히어로 — 대표 앱 홍보영상이 주인공 ---------- */}
      <section className="px-3 pt-4 sm:px-6">
        <div className="hero-panel relative mx-auto max-w-[1400px] overflow-hidden rounded-[2.5rem]">
          {/* 배경 영상 — 소리 없이 반복 재생. 없으면 썸네일, 그것도 없으면 그라디언트만 */}
          {heroVideoSrc ? (
            <video
              src={heroVideoSrc}
              poster={heroApp?.thumbUrl ?? undefined}
              autoPlay
              muted
              loop
              playsInline
              preload="metadata"
              aria-hidden="true"
              className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-40"
            />
          ) : heroApp?.thumbUrl ? (
            <img
              src={heroApp.thumbUrl}
              alt=""
              aria-hidden="true"
              className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-30"
            />
          ) : null}
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-paper/70 via-paper/55 to-paper" />

          {/* 바브바브 — 히어로 오른쪽에서 슬쩍 올려다본다 */}
          <Mascot
            variant="full"
            size={230}
            float
            className="pointer-events-none absolute bottom-0 right-6 z-10 hidden opacity-95 lg:block xl:right-16"
          />

          <div className="relative px-6 py-16 text-center sm:py-24">
            <div className="mb-6 flex justify-center">
              <BrandLogo variant="full" size={170} animated />
            </div>

            {/* 슬로건 — 브랜드의 한 줄. 로고 바로 아래에 크게 세운다 */}
            <p className="font-display bg-gradient-to-r from-lime via-green to-cobalt bg-clip-text text-lg font-extrabold tracking-[0.3em] text-transparent sm:text-2xl">
              {t("slogan.main")}
            </p>
            <p className="mt-2 text-sm text-muted">{t("slogan.sub")}</p>

            <div className="mx-auto my-8 h-px w-24 bg-gradient-to-r from-transparent via-green to-transparent" />

            {heroApp && (
              <p className="font-display text-sm font-bold tracking-[0.28em] text-green">
                {(heroApp.category ?? t("hero.featured")).toUpperCase()}
              </p>
            )}
            <h1 className="font-display mx-auto mt-3 max-w-3xl text-[2.5rem] font-extrabold leading-[1.12] tracking-tight sm:text-6xl">
              {heroName ?? "EXANSYS"}
            </h1>
            <p className="mx-auto mt-5 max-w-xl text-base text-muted sm:text-lg">
              {heroTagline || t("hero.fallbackTagline")}
            </p>

            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <a
                href="#apps"
                className="rounded-xl bg-ink px-6 py-3.5 text-[15px] font-semibold text-white transition hover:bg-green"
              >
                {t("hero.viewApps")}
              </a>
              {heroApp && heroVideoSrc && (
                <Link
                  to={`/?app=${heroApp.slug}#apps`}
                  className="rounded-xl border border-green/40 bg-green/10 px-6 py-3.5 text-[15px] font-semibold text-green transition hover:bg-green/20"
                >
                  ▶ {t("hero.playVideo")}
                </Link>
              )}
              <a
                href="#contact"
                className="rounded-xl border border-ink/15 bg-white/70 px-6 py-3.5 text-[15px] font-semibold backdrop-blur transition hover:border-ink"
              >
                {t("hero.contact")}
              </a>
            </div>
          </div>
        </div>
        <p className="mt-6 text-center text-[11px] font-bold tracking-[0.2em] text-muted">
          {t("hero.scroll")}
        </p>
      </section>


      {/* 앱 개발 갤러리 — 카드 클릭 시 홍보영상이 모달로 바로 재생된다 */}
      <section id="apps" className="scroll-mt-20 px-6 pb-24">
        <div className="mx-auto max-w-6xl">
          <ChapterHead
            emoji="📱"
            label={t("gallery.label")}
            line1={t("gallery.line1")}
            accent={t("gallery.accent")}
          />
          <AppGallery
            apps={dbApps}
            labels={{
              all: t("gallery.all"),
              watch: t("gallery.watch"),
              details: t("gallery.details"),
              visitStore: t("gallery.visitStore"),
              copyLink: t("gallery.copyLink"),
              copied: t("gallery.copied"),
              inquiry: t("gallery.inquiry"),
              noVideo: t("gallery.noVideo"),
              empty: t("gallery.empty"),
            }}
          />
        </div>
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
                <span className="inline-block rounded-full bg-green px-3 py-1 text-xs font-bold text-white">{t("banner.new")}</span>
                <h2 className="font-display mt-3 text-3xl font-extrabold tracking-tight sm:text-5xl">{featured.name}</h2>
                <p className="mt-2 max-w-md text-[15px] text-muted sm:text-lg">{featured.tagline}</p>
                <a
                  href={featured.storeUrlAndroid}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-5 inline-block rounded-2xl bg-ink px-7 py-4 text-base font-semibold text-white transition hover:bg-green sm:text-lg"
                >
                  ▶ {t("banner.getPlay")}
                </a>
              </div>
            </div>
            <div className="shrink-0 text-center">
              <img
                src={`/api/apps/${featured.slug}/qr?platform=android`}
                alt={`${featured.name} — ${t("banner.qrAlt")}`}
                className="h-44 w-44 rounded-2xl border border-line bg-white p-2 shadow-md sm:h-56 sm:w-56"
              />
              <p className="mt-3 text-sm font-semibold text-green-deep">{t("banner.scan")}</p>
            </div>
          </Reveal>
        </section>
      )}

      {/* ---------- 소셜 프루프 + 지표 ---------- */}
      <section className="px-6 py-24 text-center sm:py-32">
        <Reveal className="mx-auto max-w-3xl">
          <h2 className="font-display text-3xl font-extrabold leading-[1.25] tracking-tight sm:text-[2.6rem]">
            {t("about.headline1")}
            <br />
            <span className="bg-gradient-to-r from-green to-lime bg-clip-text text-transparent">
              {t("about.headline2")}
            </span>
          </h2>
          <p className="mt-5 text-muted">
            {t("about.body").split("\n").map((line, i) => (
              <span key={i}>
                {i > 0 && <br />}
                {line}
              </span>
            ))}
          </p>
        </Reveal>
        <div className="mx-auto mt-14 grid max-w-4xl grid-cols-1 gap-4 sm:grid-cols-3">
          {STATS.map((s, i) => (
            <Reveal key={s.label} className="rounded-3xl border border-line bg-card px-6 py-9">
              <div className="font-display text-4xl font-extrabold text-green">
                {s.plain ? s.value : <CountUp value={s.value} suffix={s.suffix ?? ""} />}
              </div>
              <div className="mt-1.5 text-sm text-muted">{t(STAT_KEYS[i] ?? "stats.projects")}</div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* ---------- 챕터 1: 앱 (벤토 그리드) ---------- */}

      {/* ---------- 챕터 2: 원칙 (다크 섹션) ---------- */}
      <section id="about" className="scroll-mt-20 bg-ink px-6 py-24 sm:py-28">
        <div className="mx-auto max-w-6xl">
          <ChapterHead
            emoji="🌙"
            label={t("craft.label")}
            line1={t("craft.line1")}
            accent={t("craft.accent")}
            dark
          />
          <div className="grid gap-5 sm:grid-cols-3">
            {[
              {
                icon: "🚫",
                title: t("craft.1.title"),
                body: t("craft.1.body"),
              },
              {
                icon: "⚡",
                title: t("craft.2.title"),
                body: t("craft.2.body"),
              },
              {
                icon: "🔧",
                title: t("craft.3.title"),
                body: t("craft.3.body"),
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
            <h3 className="font-display mb-4 text-lg font-bold">{t("notice.title")}</h3>
            <ul className="space-y-3.5">
              {NOTICES.map((n) => (
                <li key={lang === "ko" ? n.text : (n.textEn ?? n.text)} className="flex gap-3 text-sm">
                  <span className="shrink-0 font-semibold text-green">{n.date}</span>
                  <span className="text-muted">{n.text}</span>
                </li>
              ))}
            </ul>
          </Reveal>
          <Reveal className="rounded-[2rem] border border-line bg-card p-8">
            <h3 className="font-display mb-2 text-lg font-bold">{t("board.title")}</h3>
            <p className="text-sm text-muted">
              {t("board.body")}
            </p>
            <Link to="/contact"
              className="mt-4 inline-block rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green">
              {t("contact.board")}
            </Link>
          </Reveal>
        </div>
      </section>

      {/* ---------- FAQ ---------- */}
      <section className="px-6 pb-24">
        <div className="mx-auto max-w-3xl">
          <div className="mb-2 flex justify-center">
            <Mascot variant="bust" size={130} float />
          </div>
          <ChapterHead emoji="💬" label="FAQ" line1={t("faq.line1")} accent={t("faq.accent")} />
          <Faq
            items={[
              {
                q: t("faq.q1"),
                a: t("faq.a1"),
              },
              {
                q: t("faq.q2"),
                a: t("faq.a2"),
              },
              {
                q: t("faq.q3"),
                a: t("faq.a3"),
              },
              {
                q: t("faq.q4"),
                a: t("faq.a4"),
              },
              {
                q: t("faq.q5"),
                a: t("faq.a5"),
              },
            ]}
          />
        </div>
      </section>

      {/* ---------- 최종 CTA ---------- */}
      <section id="contact" className="scroll-mt-20 px-3 pb-8 sm:px-6">
        <div className="cta-panel mx-auto max-w-[1400px] rounded-[2.5rem] px-6 py-24 text-center">
          <Reveal>
            {/* 로고 옆에서 바브바브가 같이 손짓한다 */}
            <div className="mb-6 flex items-end justify-center gap-4">
              <BrandLogo variant="full" size={110} />
              <Mascot variant="full" size={150} float className="hidden sm:block" />
            </div>
            <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
              {t("contact.title")}
            </h2>
            <p className="mx-auto mt-4 max-w-md text-muted">
              {t("contact.body")}
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

// 앱 개발 갤러리 — 카테고리 칩 + 카드 그리드 + 영상 모달.
//
// 카드를 누르면 모달이 열리고 홍보영상이 바로 재생된다. 영상은 mp4 직링크와
// 유튜브를 모두 받는다(URL 을 보고 판별). 열린 앱은 ?app=슬러그 로 주소에 남아서
// 링크를 공유하면 그 앱이 바로 열린다.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { STATUS_LABEL, type AppRow } from "../lib/api";
import { pick, useLang } from "../lib/i18n";
import Mascot from "./Mascot";

/** 한 번에 보여주는 앱 개수 (더보기로 이만큼씩 추가) */
const PAGE = 30;

/** 유튜브 URL 이면 임베드 주소를, 아니면 null 을 준다 (mp4 등은 <video> 로 재생) */
export function youtubeEmbed(url: string): string | null {
  const m = url.match(
    /(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([A-Za-z0-9_-]{6,})/,
  );
  if (!m) return null;
  return `https://www.youtube-nocookie.com/embed/${m[1]}?autoplay=1&rel=0&modestbranding=1`;
}

/** 현재 언어의 문구. 영문이 비어 있으면 한글을 그대로 쓴다 */
function useAppText(app: AppRow | null) {
  const { lang } = useLang();
  if (!app) return { name: "", tagline: "", description: "" };
  return {
    name: pick(lang, app.nameEn, app.name) || app.name,
    tagline: pick(lang, app.taglineEn, app.tagline),
    description: pick(lang, app.descriptionEn, app.description),
  };
}

function hasVideo(app: AppRow): boolean {
  return Boolean(app.videoUrl && app.videoUrl.trim());
}

/** 썸네일이 없으면 아이콘, 그것도 없으면 그라디언트 플레이스홀더 */
function Thumb({ app }: { app: AppRow }) {
  const src = app.thumbUrl?.trim() || (app.iconUrl?.trim().startsWith("http") ? app.iconUrl : "");
  if (!src) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-[linear-gradient(135deg,#0a3dff_0%,#00d4ff_100%)] opacity-80">
        <span className="font-display text-2xl font-extrabold tracking-wider text-white/90">
          {app.name.slice(0, 2).toUpperCase()}
        </span>
      </div>
    );
  }
  return (
    <img
      src={src}
      alt=""
      loading="lazy"
      className="h-full w-full object-cover transition duration-500 group-hover:scale-[1.04]"
    />
  );
}

function PlayBadge() {
  return (
    <span className="grid h-12 w-12 place-items-center rounded-full bg-white/15 backdrop-blur-sm ring-1 ring-white/40 transition group-hover:bg-white/25">
      <svg viewBox="0 0 24 24" className="ml-0.5 h-5 w-5 fill-white" aria-hidden="true">
        <path d="M8 5v14l11-7z" />
      </svg>
    </span>
  );
}

export default function AppGallery({
  apps,
  labels,
}: {
  apps: AppRow[];
  labels: {
    all: string;
    watch: string;
    details: string;
    visitStore: string;
    copyLink: string;
    copied: string;
    inquiry: string;
    noVideo: string;
    empty: string;
    more: string;
  };
}) {
  const [params, setParams] = useSearchParams();
  const [cat, setCat] = useState<string>("ALL");
  /** 한 번에 보여줄 개수. 더보기를 누르면 이만큼씩 늘어난다 */
  const [limit, setLimit] = useState(PAGE);
  const [copied, setCopied] = useState(false);

  const openSlug = params.get("app");
  const open = useMemo(() => apps.find((a) => a.slug === openSlug) ?? null, [apps, openSlug]);

  // 카테고리별 개수 (분류가 없는 앱은 상태 라벨로 묶는다)
  const categories = useMemo(() => {
    const counts = new Map<string, number>();
    for (const a of apps) {
      const key = a.category?.trim() || "Etc";
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
    return [...counts.entries()].sort((a, b) => b[1] - a[1]);
  }, [apps]);

  const filtered = useMemo(
    () => (cat === "ALL" ? apps : apps.filter((a) => (a.category?.trim() || "Etc") === cat)),
    [apps, cat],
  );
  const shown = useMemo(() => filtered.slice(0, limit), [filtered, limit]);
  const remaining = filtered.length - shown.length;

  useEffect(() => {
    setLimit(PAGE);
  }, [cat]);

  const openApp = useCallback(
    (slug: string) => {
      const next = new URLSearchParams(params);
      next.set("app", slug);
      setParams(next, { replace: false });
    },
    [params, setParams],
  );

  const close = useCallback(() => {
    const next = new URLSearchParams(params);
    next.delete("app");
    setParams(next, { replace: false });
    setCopied(false);
  }, [params, setParams]);

  // 모달이 열려 있는 동안 배경 스크롤을 막고 Esc 로 닫는다
  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") close();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKey);
    };
  }, [open, close]);

  const copyLink = useCallback(() => {
    if (!open) return;
    const url = `${window.location.origin}${window.location.pathname}?app=${open.slug}`;
    void navigator.clipboard
      .writeText(url)
      .then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      })
      .catch(() => {});
  }, [open]);

  if (apps.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-line py-14 text-center">
        <Mascot variant="bust" size={120} float />
        <p className="text-muted">{labels.empty}</p>
      </div>
    );
  }

  return (
    <>
      {/* 카테고리 칩 — 실제 등록된 분류만, 개수와 함께 */}
      {categories.length > 1 && (
        <div className="mb-8 flex flex-wrap justify-center gap-2">
          <Chip active={cat === "ALL"} onClick={() => setCat("ALL")} label={labels.all} count={apps.length} />
          {categories.map(([name, n]) => (
            <Chip key={name} active={cat === name} onClick={() => setCat(name)} label={name} count={n} />
          ))}
        </div>
      )}

      <ul className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {shown.map((app) => (
          <li key={app.id}>
            <GalleryCard app={app} onOpen={() => openApp(app.slug)} labels={labels} />
          </li>
        ))}
      </ul>

      {remaining > 0 && (
        <div className="mt-10 text-center">
          <button
            onClick={() => setLimit((n) => n + PAGE)}
            className="rounded-full border border-line px-8 py-3 text-sm font-semibold transition hover:border-ink hover:bg-card"
          >
            {labels.more} <span className="text-muted">+{Math.min(remaining, PAGE)}</span>
          </button>
          <p className="mt-2 text-xs text-muted">
            {shown.length} / {filtered.length}
          </p>
        </div>
      )}

      {/* 상세 모달 — 영상이 있으면 열자마자 재생 */}
      {open && (
        <div
          className="fixed inset-0 z-[100] flex items-start justify-center overflow-y-auto bg-black/80 p-4 backdrop-blur-sm sm:p-8"
          onClick={close}
          role="dialog"
          aria-modal="true"
          aria-label={open.name}
        >
          <div
            className="my-auto w-full max-w-3xl overflow-hidden rounded-2xl border border-line bg-card shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="relative aspect-video bg-black">
              <VideoPlayer app={open} noVideoLabel={labels.noVideo} />
              <button
                onClick={close}
                aria-label="닫기"
                className="absolute right-3 top-3 z-10 grid h-9 w-9 place-items-center rounded-full bg-black/60 text-white backdrop-blur-sm transition hover:bg-black/80"
              >
                ✕
              </button>
            </div>

            <div className="p-6">
              <ModalHead app={open} />

              <div className="mt-6 flex flex-wrap gap-2">
                <Link
                  to={`/apps/${open.slug}`}
                  className="rounded-full bg-green px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep"
                >
                  {labels.details}
                </Link>
                {open.storeUrlAndroid && (
                  <a
                    href={open.storeUrlAndroid}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="rounded-full border border-line px-5 py-2.5 text-sm transition hover:border-ink"
                  >
                    {labels.visitStore} ↗
                  </a>
                )}
                <button
                  onClick={copyLink}
                  className="rounded-full border border-line px-5 py-2.5 text-sm transition hover:border-ink"
                >
                  {copied ? labels.copied : labels.copyLink}
                </button>
                <Link
                  to="/contact"
                  className="rounded-full border border-line px-5 py-2.5 text-sm transition hover:border-ink"
                >
                  {labels.inquiry}
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

/** 카드 — 마우스를 올리면 그 자리에서 커지며 홍보영상이 소리 없이 재생된다.
 *  모달을 띄우지 않는 이유: 스쳐도 창이 뜨면 성가시고, 모바일에는 hover 가 없다.
 *  자세히 보려면 눌러서 모달을 연다. */
function GalleryCard({
  app,
  onOpen,
  labels,
}: {
  app: AppRow;
  onOpen: () => void;
  labels: { watch: string; details: string };
}) {
  const text = useAppText(app);
  const [preview, setPreview] = useState(false);
  const timer = useRef<number | null>(null);
  const videoRef = useRef<HTMLVideoElement>(null);

  const url = app.videoUrl?.trim() ?? "";
  const isYoutube = url ? Boolean(youtubeEmbed(url)) : false;
  const canPreview = Boolean(url) && !isYoutube; // 유튜브는 인라인 미리보기가 무거워 제외

  // 스쳐 지나갈 때 재생되지 않도록 잠깐 머문 뒤에 시작한다
  const enter = useCallback(() => {
    if (!canPreview) return;
    timer.current = window.setTimeout(() => setPreview(true), 420);
  }, [canPreview]);

  const leave = useCallback(() => {
    if (timer.current) window.clearTimeout(timer.current);
    timer.current = null;
    setPreview(false);
  }, []);

  useEffect(() => () => {
    if (timer.current) window.clearTimeout(timer.current);
  }, []);

  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;
    if (preview) {
      v.currentTime = 0;
      void v.play().catch(() => {});
    } else {
      v.pause();
    }
  }, [preview]);

  return (
    <button
      onClick={onOpen}
      onMouseEnter={enter}
      onMouseLeave={leave}
      onFocus={enter}
      onBlur={leave}
      className={`group relative block w-full overflow-hidden rounded-2xl border bg-card text-left transition duration-300 ${
        preview
          ? "z-20 scale-[1.06] border-green/70 shadow-2xl shadow-green/20"
          : "z-0 border-line hover:-translate-y-1 hover:border-green/60 hover:shadow-2xl hover:shadow-green/10"
      }`}
    >
      <div className="relative aspect-video overflow-hidden bg-paper">
        <Thumb app={app} />
        {canPreview && (
          <video
            ref={videoRef}
            src={url}
            muted
            loop
            playsInline
            preload="none"
            aria-hidden="true"
            className={`absolute inset-0 h-full w-full object-cover transition-opacity duration-300 ${
              preview ? "opacity-100" : "opacity-0"
            }`}
          />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" />
        <div
          className={`absolute inset-0 grid place-items-center transition ${
            preview ? "opacity-0" : "opacity-0 group-hover:opacity-100"
          }`}
        >
          {hasVideo(app) && <PlayBadge />}
        </div>
        <div className="absolute left-3 top-3 flex gap-1.5">
          <span className="rounded-full bg-black/55 px-2.5 py-1 text-[11px] font-semibold tracking-wide text-white backdrop-blur-sm">
            {app.category?.trim() || STATUS_LABEL[app.status]}
          </span>
          {hasVideo(app) && (
            <span className="rounded-full bg-green/85 px-2.5 py-1 text-[11px] font-semibold text-white">
              ▶ {labels.watch}
            </span>
          )}
        </div>
        <p className="absolute bottom-3 left-4 right-4 truncate font-display text-lg font-extrabold text-white">
          {text.name}
        </p>
      </div>
      <div className="p-5">
        <p className="line-clamp-2 min-h-11 text-sm text-muted">{text.tagline || text.description}</p>
        <span className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-green">
          {labels.details}
          <span aria-hidden="true">→</span>
        </span>
      </div>
    </button>
  );
}

/** 모달 상단 — 제목·분류·소개 */
function ModalHead({ app }: { app: AppRow }) {
  const text = useAppText(app);
  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        <h3 className="font-display text-2xl font-extrabold">{text.name}</h3>
        <span className="rounded-full bg-paper px-2.5 py-0.5 text-xs text-muted">
          {app.category?.trim() || STATUS_LABEL[app.status]}
        </span>
      </div>
      {text.tagline && <p className="mt-2 text-muted">{text.tagline}</p>}
      {text.description && (
        <p className="mt-3 whitespace-pre-wrap text-sm leading-relaxed text-muted">
          {text.description}
        </p>
      )}
    </>
  );
}

function Chip({
  active,
  onClick,
  label,
  count,
}: {
  active: boolean;
  onClick: () => void;
  label: string;
  count: number;
}) {
  return (
    <button
      onClick={onClick}
      className={`rounded-full border px-4 py-2 text-sm font-medium transition ${
        active
          ? "border-green bg-green text-white"
          : "border-line text-muted hover:border-ink hover:text-ink"
      }`}
    >
      {label}
      <span className={`ml-1.5 text-xs ${active ? "text-white/70" : "text-muted"}`}>{count}</span>
    </button>
  );
}

/** mp4 는 <video>, 유튜브는 iframe. 영상이 없으면 썸네일을 크게 보여준다. */
function VideoPlayer({ app, noVideoLabel }: { app: AppRow; noVideoLabel: string }) {
  const ref = useRef<HTMLVideoElement>(null);
  const url = app.videoUrl?.trim() ?? "";
  const embed = url ? youtubeEmbed(url) : null;

  useEffect(() => {
    // 카드 클릭이라는 사용자 동작으로 열렸으므로 소리와 함께 재생해도 막히지 않는다.
    // 그래도 브라우저가 거부하면 음소거로 한 번 더 시도한다.
    const v = ref.current;
    if (!v) return;
    v.play().catch(() => {
      v.muted = true;
      void v.play().catch(() => {});
    });
  }, [url]);

  if (!url) {
    return (
      <div className="flex h-full w-full items-center justify-center">
        <Thumb app={app} />
        <span className="absolute rounded-full bg-black/60 px-4 py-2 text-sm text-white">
          {noVideoLabel}
        </span>
      </div>
    );
  }

  if (embed) {
    return (
      <iframe
        src={embed}
        title={app.name}
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen
        className="absolute inset-0 h-full w-full"
      />
    );
  }

  return (
    <video
      ref={ref}
      src={url}
      poster={app.thumbUrl?.trim() || undefined}
      controls
      playsInline
      preload="metadata"
      className="absolute inset-0 h-full w-full bg-black"
    />
  );
}

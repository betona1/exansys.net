import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, STATUS_LABEL, type AppRow, type Me } from "../lib/api";
import CountUp from "../components/CountUp";
import Comments from "../components/Comments";
import { formatBytes, type BuildRow } from "../components/AppAssets";

type Screenshot = { id: number; imageUrl: string };

export default function AppDetail({ me }: { me: Me }) {
  const { slug } = useParams<{ slug: string }>();
  const [app, setApp] = useState<AppRow | null>(null);
  const [screenshots, setScreenshots] = useState<Screenshot[]>([]);
  const [betaAvailable, setBetaAvailable] = useState(false);
  const [builds, setBuilds] = useState<BuildRow[]>([]);
  const [notFound, setNotFound] = useState(false);
  const [count, setCount] = useState(0);
  const [qrPlatform, setQrPlatform] = useState<"android" | "ios">("android");

  useEffect(() => {
    if (!slug) return;
    void api<{ app: AppRow; screenshots: Screenshot[]; betaAvailable: boolean }>(
      `/api/apps/${slug}`,
    ).then((res) => {
      if (res.ok) {
        setApp(res.data.app);
        setScreenshots(res.data.screenshots);
        setBetaAvailable(res.data.betaAvailable);
        setCount(res.data.app.downloadCount);
        if (!res.data.app.storeUrlAndroid && res.data.app.storeUrlIos) setQrPlatform("ios");
      } else {
        setNotFound(true);
      }
    });
  }, [slug]);

  // 베타 빌드 목록은 로그인 회원에게만 (401 방지 위해 조건부 호출)
  useEffect(() => {
    if (!slug || !me || !betaAvailable) return;
    void api<{ builds: BuildRow[] }>(`/api/apps/${slug}/builds`).then((res) => {
      if (res.ok) setBuilds(res.data.builds);
    });
  }, [slug, me, betaAvailable]);

  // 스토어 이동 버튼: 카운터 +1 후 스토어 새 탭 (CLAUDE.md 5-2절)
  const goStore = async (platform: "android" | "ios", url: string) => {
    const res = await api<{ downloadCount: number }>(`/api/apps/${slug}/count`, {
      method: "POST",
      body: JSON.stringify({ platform }),
    });
    if (res.ok) setCount(res.data.downloadCount);
    window.open(url, "_blank", "noopener");
  };

  if (notFound) {
    return (
      <main className="mx-auto max-w-6xl px-6 py-24 text-center">
        <p className="font-display text-2xl font-bold">앱을 찾을 수 없습니다.</p>
        <Link to="/" className="mt-4 inline-block font-semibold text-cobalt hover:underline">
          ← 홈으로
        </Link>
      </main>
    );
  }
  if (!app) {
    return <main className="mx-auto max-w-6xl px-6 py-24 text-center text-muted">불러오는 중…</main>;
  }

  const hasQr = Boolean(qrPlatform === "ios" ? app.storeUrlIos : app.storeUrlAndroid);

  return (
    <main className="mx-auto max-w-6xl px-6 py-14">
      <Link to="/#apps" className="text-sm font-semibold text-muted hover:text-ink">
        ← 모든 앱
      </Link>

      <div className="mt-6 flex flex-wrap items-start gap-6">
        <div className="grid h-20 w-20 place-items-center overflow-hidden rounded-2xl border border-line bg-lime/15 text-4xl">
          {/^(https?:\/\/|\/)/.test(app.iconUrl ?? "") ? (
            <img src={app.iconUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            <span>{app.iconUrl || "📱"}</span>
          )}
        </div>
        <div className="min-w-60 flex-1">
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
              {app.name}
            </h1>
            <span className="rounded-full bg-lime/25 px-3 py-1 text-xs font-semibold text-green-deep">
              {STATUS_LABEL[app.status]}
            </span>
          </div>
          {app.tagline && <p className="mt-2 text-lg text-muted">{app.tagline}</p>}
          <div className="mt-3 text-sm font-semibold text-muted">
            누적 다운로드 <span className="text-green"><CountUp value={count} /></span>
          </div>
        </div>
      </div>

      <div className="mt-10 grid gap-8 lg:grid-cols-3">
        <div className="lg:col-span-2">
          {app.description && (
            <p className="whitespace-pre-line text-[15.5px] leading-relaxed text-ink/85">
              {app.description}
            </p>
          )}

          {screenshots.length > 0 && (
            <div className="mt-8 flex gap-4 overflow-x-auto pb-2">
              {screenshots.map((s) =>
                s.imageUrl.endsWith(".mp4") ? (
                  <video
                    key={s.id}
                    src={s.imageUrl}
                    controls
                    loop
                    muted
                    playsInline
                    className="h-96 rounded-2xl border border-line"
                  />
                ) : (
                  <img
                    key={s.id}
                    src={s.imageUrl}
                    alt=""
                    className="h-96 rounded-2xl border border-line object-cover"
                  />
                ),
              )}
            </div>
          )}

          {slug && <Comments slug={slug} me={me} />}
        </div>

        <aside className="space-y-5">
          <div className="rounded-2xl border border-line bg-card p-6">
            <h3 className="font-display mb-4 text-lg font-bold">다운로드</h3>
            <div className="space-y-2.5">
              {app.storeUrlAndroid ? (
                <button
                  onClick={() => void goStore("android", app.storeUrlAndroid!)}
                  className="block w-full rounded-xl bg-ink px-4 py-3 text-center text-sm font-semibold text-white transition hover:bg-green"
                >
                  ▶ Google Play에서 받기
                </button>
              ) : (
                <div className="rounded-xl border border-dashed border-line px-4 py-3 text-center text-sm text-muted">
                  Google Play — 준비 중
                </div>
              )}
              {app.storeUrlIos ? (
                <button
                  onClick={() => void goStore("ios", app.storeUrlIos!)}
                  className="block w-full rounded-xl bg-ink px-4 py-3 text-center text-sm font-semibold text-white transition hover:bg-green"
                >
                   App Store에서 받기
                </button>
              ) : (
                <div className="rounded-xl border border-dashed border-line px-4 py-3 text-center text-sm text-muted">
                  App Store — 준비 중
                </div>
              )}
            </div>
          </div>

          {betaAvailable && (
            <div className="rounded-2xl border-2 border-green/40 bg-card p-6">
              <h3 className="font-display mb-1 text-lg font-bold">🧪 베타 테스트</h3>
              <p className="text-xs text-muted">출시 전 테스트 버전입니다. 회원 전용.</p>
              {!me ? (
                <Link
                  to="/login"
                  className="mt-4 block rounded-xl bg-green px-4 py-3 text-center text-sm font-semibold text-white transition hover:bg-green-deep"
                >
                  로그인하고 테스트 참여하기
                </Link>
              ) : builds.length === 0 ? (
                <p className="mt-4 text-sm text-muted">빌드를 불러오는 중…</p>
              ) : (
                <div className="mt-4 space-y-3">
                  <a
                    href={`/api/apps/${app.slug}/builds/${builds[0].id}/download`}
                    className="block rounded-xl bg-green px-4 py-3 text-center text-sm font-semibold text-white transition hover:bg-green-deep"
                  >
                    ⬇ APK 받기 — v{builds[0].version} ({formatBytes(builds[0].fileSize)})
                  </a>
                  {builds[0].notes && (
                    <p className="whitespace-pre-line rounded-xl bg-paper px-4 py-3 text-xs leading-relaxed text-muted">
                      {builds[0].notes}
                    </p>
                  )}
                  {builds.length > 1 && (
                    <details className="text-xs text-muted">
                      <summary className="cursor-pointer font-semibold">이전 빌드</summary>
                      <ul className="mt-2 space-y-1.5">
                        {builds.slice(1).map((b) => (
                          <li key={b.id}>
                            <a
                              href={`/api/apps/${app.slug}/builds/${b.id}/download`}
                              className="text-cobalt hover:underline"
                            >
                              v{b.version}
                            </a>{" "}
                            · {formatBytes(b.fileSize)}
                          </li>
                        ))}
                      </ul>
                    </details>
                  )}
                  <div className="rounded-xl border border-line p-4 text-center">
                    {/* 다크 모드에서도 QR은 흰 배경 유지 (스캔 안정성) — bg-white는 다크에서 오버라이드되므로 인라인 지정 */}
                    <img
                      src={`/api/apps/${app.slug}/builds/${builds[0].id}/qr`}
                      alt="테스트 APK 다운로드 QR 코드"
                      className="mx-auto w-40 rounded-lg p-2"
                      style={{ background: "#ffffff" }}
                    />
                    <p className="mt-2 text-xs font-semibold">📱 핸드폰 카메라로 스캔</p>
                    <p className="mt-0.5 text-[11px] text-muted">
                      폰에서 로그인 없이 바로 다운로드 (QR은 30분간 유효)
                    </p>
                  </div>
                  <p className="text-xs text-muted">
                    설치 시 "출처를 알 수 없는 앱" 허용이 필요합니다. 사용해 보시고 아래{" "}
                    <b className="text-ink">댓글로 피드백</b>을 남겨주세요! 🙏
                  </p>
                </div>
              )}
            </div>
          )}

          <Link
            to={`/apps/${app.slug}/privacy`}
            className="block rounded-2xl border border-line bg-card p-5 text-sm font-semibold transition hover:border-ink"
          >
            📄 개인정보처리방침 →
          </Link>

          {hasQr && (
            <div className="rounded-2xl border border-line bg-card p-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="font-display text-lg font-bold">QR 코드</h3>
                {app.storeUrlAndroid && app.storeUrlIos && (
                  <div className="flex gap-1 rounded-full border border-line p-0.5 text-xs font-semibold">
                    {(["android", "ios"] as const).map((p) => (
                      <button
                        key={p}
                        onClick={() => setQrPlatform(p)}
                        className={`rounded-full px-2.5 py-1 ${qrPlatform === p ? "bg-ink text-white" : "text-muted"}`}
                      >
                        {p === "android" ? "Android" : "iOS"}
                      </button>
                    ))}
                  </div>
                )}
              </div>
              <img
                src={`/api/apps/${app.slug}/qr?platform=${qrPlatform}`}
                alt={`${app.name} ${qrPlatform} 스토어 QR 코드`}
                className="mx-auto w-44 rounded-xl border border-line p-2"
                style={{ background: "#ffffff" }}
              />
              <a
                href={`/api/apps/${app.slug}/qr?platform=${qrPlatform}`}
                download={`${app.slug}-${qrPlatform}-qr.svg`}
                className="mt-4 block text-center text-sm font-semibold text-cobalt hover:underline"
              >
                SVG 다운로드 (홍보물용)
              </a>
            </div>
          )}
        </aside>
      </div>
    </main>
  );
}

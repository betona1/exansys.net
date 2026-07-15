// App Review 분석 (reviewgg 웹판) — crew 이상 전용
// 구글플레이/앱스토어 앱 검색 → 순위·평점·다운로드 표시 → 리뷰 수집·과학적 분석 → 엑셀 추출
import { useCallback, useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  api,
  REVIEW_REGIONS,
  type Me,
  type StoreKind,
  type AppHit,
  type CollectResult,
  type ReviewItem,
} from "../lib/api";

function isCrew(me: Me) {
  return Boolean(me && (me.role === "crew" || me.role === "staff" || me.role === "admin"));
}

const STORE_LABEL: Record<StoreKind, string> = { play: "Google Play", apple: "App Store" };

function fmtNum(n: number | null | undefined) {
  return typeof n === "number" ? n.toLocaleString("ko-KR") : "—";
}
function fmtDate(ms: number | null) {
  if (!ms) return "";
  const d = new Date(ms);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, "0")}.${String(d.getDate()).padStart(2, "0")}`;
}
function stars(score: number | null | undefined) {
  if (typeof score !== "number") return "☆";
  return `★ ${score.toFixed(2)}`;
}

export default function AppReview({ me, meLoading }: { me: Me; meLoading: boolean }) {
  const [store, setStore] = useState<StoreKind>("play");
  const [region, setRegion] = useState("kr");
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<AppHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [limit, setLimit] = useState(300);
  const [collecting, setCollecting] = useState(false);
  const [result, setResult] = useState<CollectResult | null>(null);
  const [selected, setSelected] = useState<AppHit | null>(null);
  const [error, setError] = useState("");

  const onSearch = useCallback(
    async (e?: React.FormEvent) => {
      e?.preventDefault();
      const q = query.trim();
      if (!q) return;
      setSearching(true);
      setError("");
      setHits([]);
      const res = await api<{ hits: AppHit[] }>(
        `/api/appreview/search?q=${encodeURIComponent(q)}&store=${store}&region=${region}`,
      );
      setSearching(false);
      if (res.ok) {
        setHits(res.data.hits);
        if (res.data.hits.length === 0) setError("검색 결과가 없습니다.");
      } else {
        setError("검색에 실패했습니다. 스토어가 일시적으로 응답하지 않을 수 있어요.");
      }
    },
    [query, store, region],
  );

  const collect = useCallback(
    async (hit: AppHit, refresh = false) => {
      setSelected(hit);
      setCollecting(true);
      setError("");
      if (!refresh) setResult(null);
      const res = await api<CollectResult>("/api/appreview/collect", {
        method: "POST",
        body: JSON.stringify({ store: hit.store, appId: hit.appId, region, limit, refresh }),
      });
      setCollecting(false);
      if (res.ok) setResult(res.data);
      else if (res.error === "no_reviews") setError("수집된 리뷰가 없습니다.");
      else setError("리뷰 수집에 실패했습니다. 잠시 후 다시 시도해 주세요.");
    },
    [region, limit],
  );

  const exportUrl = result
    ? `/api/appreview/export?store=${result.app.store}&appId=${encodeURIComponent(result.app.appId)}&region=${result.app.region}`
    : "#";

  if (meLoading) {
    return <main className="mx-auto max-w-6xl px-6 py-24 text-center text-muted">확인 중…</main>;
  }

  if (!isCrew(me)) {
    return (
      <main className="mx-auto max-w-2xl px-6 py-24 text-center">
        <div className="mb-6 text-5xl">📊</div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">앱 리뷰 분석실</h1>
        <p className="mx-auto mt-4 max-w-md text-muted">
          구글플레이·앱스토어의 앱 리뷰를 수집해 <b>별점 분포·불만/칭찬 키워드·추이</b>를 분석하고
          엑셀로 내보내는 <b>크루 전용</b> 도구입니다.
        </p>
        <div className="mt-8 rounded-2xl border border-line bg-card p-6 text-left text-sm text-muted">
          <p className="font-semibold text-ink">이용하려면</p>
          <ol className="mt-2 list-decimal space-y-1 pl-5">
            <li>우측 상단에서 소셜 계정으로 로그인해 주세요.</li>
            <li>
              <Link to="/contact" className="font-semibold text-cobalt hover:underline">개발 문의 게시판</Link>
              에 크루 참여 희망 글을 남겨주세요.
            </li>
            <li>운영진 승인 후 크루 권한이 부여됩니다.</li>
          </ol>
        </div>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <header className="mb-8">
        <h1 className="font-display text-3xl font-extrabold tracking-tight">앱 리뷰 분석실</h1>
        <p className="mt-2 text-muted">
          앱을 검색하면 순위·평점·다운로드가 함께 표시됩니다. 리뷰를 수집해 과학적으로 분석하고 엑셀로 받으세요.
          <span className="ml-1 text-xs">(수집 데이터는 7일간 캐시 후 자동 정리)</span>
        </p>
      </header>

      {/* 검색 바 */}
      <form onSubmit={onSearch} className="mb-6 flex flex-wrap items-center gap-3">
        <div className="inline-flex rounded-full border border-line bg-card p-1">
          {(["play", "apple"] as StoreKind[]).map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => setStore(s)}
              className={`rounded-full px-4 py-1.5 text-sm font-semibold transition ${
                store === s ? "bg-ink text-white" : "text-muted hover:text-ink"
              }`}
            >
              {STORE_LABEL[s]}
            </button>
          ))}
        </div>
        <select
          value={region}
          onChange={(e) => setRegion(e.target.value)}
          className="rounded-full border border-line bg-card px-4 py-2 text-sm"
        >
          {REVIEW_REGIONS.map((r) => (
            <option key={r.code} value={r.code}>{r.label}</option>
          ))}
        </select>
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="앱 이름 검색 (예: 카카오톡, Habitica)"
          className="min-w-52 flex-1 rounded-full border border-line bg-card px-5 py-2 text-sm outline-none focus:border-ink"
        />
        <button
          type="submit"
          disabled={searching}
          className="rounded-full bg-green px-6 py-2 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
        >
          {searching ? "검색 중…" : "검색"}
        </button>
      </form>

      {error && (
        <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* 검색 결과 (순위·평점·다운로드) */}
      {hits.length > 0 && (
        <section className="mb-8">
          <h2 className="mb-3 text-sm font-semibold text-muted">검색 결과 · 순위순</h2>
          <ul className="grid gap-2">
            {hits.map((h, i) => (
              <li key={h.appId}>
                <button
                  onClick={() => collect(h)}
                  className={`flex w-full items-center gap-4 rounded-2xl border bg-card p-3 text-left transition hover:border-ink ${
                    selected?.appId === h.appId ? "border-green" : "border-line"
                  }`}
                >
                  <span className="w-7 shrink-0 text-center font-display text-lg font-extrabold text-muted">
                    {i + 1}
                  </span>
                  {h.iconUrl ? (
                    <img src={h.iconUrl} alt="" className="h-12 w-12 shrink-0 rounded-xl" />
                  ) : (
                    <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-paper text-lg">📱</span>
                  )}
                  <span className="min-w-0 flex-1">
                    <span className="block truncate font-semibold text-ink">{h.title}</span>
                    <span className="mt-0.5 flex flex-wrap gap-x-3 gap-y-0.5 text-xs text-muted">
                      <span className="text-amber-500">{stars(h.score)}</span>
                      <span>평가 {fmtNum(h.ratings)}</span>
                      {h.installs && <span className="font-medium text-green-deep">다운로드 {h.installs}</span>}
                      {h.developer && <span className="truncate">· {h.developer}</span>}
                    </span>
                  </span>
                  <span className="shrink-0 rounded-full bg-lime/30 px-3 py-1 text-xs font-semibold text-green-deep">
                    리뷰 분석 →
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}

      {collecting && (
        <div className="rounded-2xl border border-line bg-card p-10 text-center text-muted">
          <div className="mb-2 animate-pulse text-3xl">📥</div>
          리뷰를 수집·분석하는 중입니다… (최대 {limit}건)
        </div>
      )}

      {/* 수집 옵션 */}
      {hits.length > 0 && (
        <div className="mb-8 flex items-center gap-2 text-sm text-muted">
          <span>수집량</span>
          {[100, 300, 500, 1000].map((n) => (
            <button
              key={n}
              onClick={() => setLimit(n)}
              className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                limit === n ? "bg-ink text-white" : "border border-line bg-card hover:border-ink"
              }`}
            >
              {n}건
            </button>
          ))}
          <span className="text-xs">· 앱스토어는 최대 500건</span>
        </div>
      )}

      {result && !collecting && <AnalysisView result={result} exportUrl={exportUrl} onRefresh={() => selected && collect(selected, true)} />}
    </main>
  );
}

// ── 분석 대시보드 ──
function AnalysisView({
  result,
  exportUrl,
  onRefresh,
}: {
  result: CollectResult;
  exportUrl: string;
  onRefresh: () => void;
}) {
  const { app, analysis: a, reviews } = result;
  const maxDist = Math.max(...a.distribution, 1);
  const maxMonth = Math.max(...a.monthlyTrend.map((m) => m.count), 1);

  return (
    <section className="space-y-8">
      {/* 앱 헤더 */}
      <div className="flex flex-wrap items-center gap-4 rounded-2xl border border-line bg-card p-5">
        {app.iconUrl ? (
          <img src={app.iconUrl} alt="" className="h-16 w-16 rounded-2xl" />
        ) : (
          <span className="grid h-16 w-16 place-items-center rounded-2xl bg-paper text-2xl">📱</span>
        )}
        <div className="min-w-0 flex-1">
          <h2 className="truncate font-display text-xl font-extrabold">{app.title}</h2>
          <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted">
            <span>{STORE_LABEL[app.store]}</span>
            <span className="text-amber-500">{stars(app.score)}</span>
            <span>평가 {fmtNum(app.ratings)}</span>
            {app.installs && <span className="font-medium text-green-deep">다운로드 {app.installs}</span>}
            <span>수집 {fmtNum(app.reviewCount)}건</span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted">
            {result.cached ? "캐시" : "방금 수집"} · {fmtDate(result.fetchedAt)}
          </span>
          <button
            onClick={onRefresh}
            className="rounded-full border border-line bg-card px-3 py-1.5 text-xs font-semibold hover:border-ink"
          >
            새로고침
          </button>
          <a
            href={exportUrl}
            className="rounded-full bg-green px-4 py-1.5 text-xs font-semibold text-white hover:bg-green-deep"
          >
            ⬇ 엑셀 추출
          </a>
        </div>
      </div>

      {/* 요약 타일 */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <Tile label="수집 평균별점" value={a.avgScore.toFixed(2)} accent="text-amber-500" />
        <Tile label="긍정 (4~5점)" value={`${pct(a.positive, a.total)}%`} accent="text-green-deep" />
        <Tile label="부정 (1~2점)" value={`${pct(a.negative, a.total)}%`} accent="text-red-500" />
        <Tile label="불만율" value={`${a.negativeRate}%`} accent="text-red-500" />
      </div>

      {/* 별점 분포 */}
      <Card title="별점 분포">
        <div className="space-y-2">
          {[5, 4, 3, 2, 1].map((s) => {
            const n = a.distribution[s - 1];
            return (
              <div key={s} className="flex items-center gap-3 text-sm">
                <span className="w-8 shrink-0 text-amber-500">{s}★</span>
                <div className="h-4 flex-1 overflow-hidden rounded-full bg-paper">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-green to-lime"
                    style={{ width: `${(n / maxDist) * 100}%` }}
                  />
                </div>
                <span className="w-24 shrink-0 text-right text-muted">
                  {fmtNum(n)} · {a.distributionPct[s - 1]}%
                </span>
              </div>
            );
          })}
        </div>
      </Card>

      {/* 키워드 */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card title="😡 불만 키워드 (1~2점)">
          <KeywordChips items={a.complaintKeywords} tone="neg" />
        </Card>
        <Card title="😍 칭찬 키워드 (4~5점)">
          <KeywordChips items={a.praiseKeywords} tone="pos" />
        </Card>
      </div>

      {/* 월별 추이 */}
      {a.monthlyTrend.length > 1 && (
        <Card title="월별 리뷰 추이 (건수 · 평균별점)">
          <div className="flex items-end gap-1 overflow-x-auto pb-2">
            {a.monthlyTrend.map((m) => (
              <div key={m.month} className="flex min-w-9 flex-1 flex-col items-center gap-1">
                <span className="text-[10px] text-muted">{m.avg}</span>
                <div
                  className="w-full rounded-t bg-gradient-to-t from-green to-lime"
                  style={{ height: `${Math.max(4, (m.count / maxMonth) * 120)}px` }}
                  title={`${m.month}: ${m.count}건, 평균 ${m.avg}`}
                />
                <span className="rotate-0 whitespace-nowrap text-[9px] text-muted">{m.month.slice(2)}</span>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* 버전별 (play) */}
      {a.versionBreakdown.length > 0 && (
        <Card title="버전별 평가">
          <div className="grid gap-2 sm:grid-cols-2">
            {a.versionBreakdown.map((v) => (
              <div key={v.version} className="flex items-center justify-between rounded-lg bg-paper px-3 py-2 text-sm">
                <span className="font-mono text-xs">{v.version}</span>
                <span className="text-muted">
                  {fmtNum(v.count)}건 · <span className="text-amber-500">★{v.avg}</span>
                </span>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* 리뷰 테이블 */}
      <ReviewTable reviews={reviews} />
    </section>
  );
}

function pct(n: number, total: number) {
  return total ? Math.round((n / total) * 100) : 0;
}

function Tile({ label, value, accent }: { label: string; value: string; accent: string }) {
  return (
    <div className="rounded-2xl border border-line bg-card p-4">
      <div className="text-xs text-muted">{label}</div>
      <div className={`mt-1 font-display text-2xl font-extrabold ${accent}`}>{value}</div>
    </div>
  );
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-line bg-card p-5">
      <h3 className="mb-4 text-sm font-semibold text-ink">{title}</h3>
      {children}
    </div>
  );
}

function KeywordChips({ items, tone }: { items: { word: string; count: number }[]; tone: "neg" | "pos" }) {
  if (items.length === 0) return <p className="text-sm text-muted">키워드가 충분하지 않습니다.</p>;
  const max = Math.max(...items.map((i) => i.count), 1);
  const base = tone === "neg" ? "bg-red-50 text-red-700" : "bg-green-50 text-green-deep";
  return (
    <div className="flex flex-wrap gap-2">
      {items.map((k) => (
        <span
          key={k.word}
          className={`rounded-full px-3 py-1 text-sm font-medium ${base}`}
          style={{ fontSize: `${0.8 + (k.count / max) * 0.5}rem` }}
        >
          {k.word} <span className="opacity-60">{k.count}</span>
        </span>
      ))}
    </div>
  );
}

function ReviewTable({ reviews }: { reviews: ReviewItem[] }) {
  const [filter, setFilter] = useState<"all" | "pos" | "neu" | "neg">("all");
  const [kw, setKw] = useState("");

  const filtered = useMemo(() => {
    const term = kw.trim().toLowerCase();
    return reviews.filter((r) => {
      if (filter === "pos" && r.score < 4) return false;
      if (filter === "neu" && r.score !== 3) return false;
      if (filter === "neg" && r.score > 2) return false;
      if (term && !r.content.toLowerCase().includes(term)) return false;
      return true;
    });
  }, [reviews, filter, kw]);

  const tabs: { key: typeof filter; label: string }[] = [
    { key: "all", label: "전체" },
    { key: "pos", label: "긍정" },
    { key: "neu", label: "중립" },
    { key: "neg", label: "부정" },
  ];

  return (
    <Card title={`리뷰 원본 (${fmtNum(filtered.length)}건)`}>
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="inline-flex rounded-full border border-line bg-card p-1">
          {tabs.map((t) => (
            <button
              key={t.key}
              onClick={() => setFilter(t.key)}
              className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                filter === t.key ? "bg-ink text-white" : "text-muted hover:text-ink"
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
        <input
          value={kw}
          onChange={(e) => setKw(e.target.value)}
          placeholder="리뷰 내용 검색"
          className="min-w-40 flex-1 rounded-full border border-line bg-card px-4 py-1.5 text-sm outline-none focus:border-ink"
        />
      </div>
      <div className="max-h-[32rem] overflow-y-auto">
        <ul className="space-y-2">
          {filtered.slice(0, 500).map((r, i) => (
            <li key={i} className="rounded-xl bg-paper p-3 text-sm">
              <div className="mb-1 flex items-center gap-2 text-xs text-muted">
                <span className={r.score <= 2 ? "text-red-500" : r.score >= 4 ? "text-green-deep" : "text-amber-500"}>
                  {"★".repeat(r.score)}{"☆".repeat(5 - r.score)}
                </span>
                {r.userName && <span className="truncate">{r.userName}</span>}
                {r.at && <span>· {fmtDate(r.at)}</span>}
                {r.version && <span>· v{r.version}</span>}
                {r.thumbsUp > 0 && <span>· 👍 {r.thumbsUp}</span>}
              </div>
              <p className="whitespace-pre-wrap break-words text-ink">{r.content}</p>
            </li>
          ))}
        </ul>
        {filtered.length > 500 && (
          <p className="mt-3 text-center text-xs text-muted">
            상위 500건만 표시됩니다. 전체는 엑셀로 추출하세요.
          </p>
        )}
        {filtered.length === 0 && <p className="py-8 text-center text-sm text-muted">해당 조건의 리뷰가 없습니다.</p>}
      </div>
    </Card>
  );
}

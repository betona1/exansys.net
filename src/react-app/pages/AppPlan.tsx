// 앱기획 — 내 아이디어 목록 (member 이상 로그인 필수, 본인 것만 보인다)
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  api,
  getPlanApiKey,
  planAi,
  setPlanApiKey,
  PLAN_AI_ERROR_MESSAGE,
  PLAN_AI_FORBIDDEN_HINTS,
  PLAN_PIVOT_LABEL,
  PLAN_STAGE_LABEL,
  type Me,
  type PlanProjectSummary,
  type PlanStage,
} from "../lib/api";

function fmtDate(ms: number) {
  const d = new Date(ms);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, "0")}.${String(d.getDate()).padStart(2, "0")}`;
}

/** 판단 결과별 뱃지 색 — 유지는 초록, 피벗류는 주황, 보류는 회색 */
function decisionTone(decision: string) {
  if (decision === "KEEP") return "bg-lime/40 text-green-deep";
  if (decision === "HOLD") return "bg-paper text-muted";
  if (decision === "REFINE") return "bg-cobalt/10 text-cobalt";
  return "bg-amber-100 text-amber-800";
}

export default function AppPlan({ me, meLoading }: { me: Me; meLoading: boolean }) {
  const [projects, setProjects] = useState<PlanProjectSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState("");
  const [rawIdea, setRawIdea] = useState("");
  const [error, setError] = useState("");
  const [apiKey, setApiKeyState] = useState("");
  const [keyOpen, setKeyOpen] = useState(false);
  const [keySaved, setKeySaved] = useState(false);
  const [stageFilter, setStageFilter] = useState<PlanStage | "ALL">("ALL");
  const [checking, setChecking] = useState(false);
  const [checkResult, setCheckResult] = useState<{
    ok: boolean;
    text: string;
    hints?: string[];
  } | null>(null);

  const isMember = Boolean(me);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await api<{ projects: PlanProjectSummary[] }>("/api/plan/projects");
    setLoading(false);
    if (res.ok) setProjects(res.data.projects);
    else if (res.error !== "unauthorized") setError("목록을 불러오지 못했습니다.");
  }, []);

  useEffect(() => {
    setApiKeyState(getPlanApiKey());
  }, []);

  useEffect(() => {
    if (isMember) void load();
    else setLoading(false);
  }, [isMember, load]);

  const create = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      const appName = name.trim();
      if (!appName) return;
      setCreating(true);
      setError("");
      const res = await api<{ id: number }>("/api/plan/projects", {
        method: "POST",
        body: JSON.stringify({ appName, rawIdea: rawIdea.trim() || undefined }),
      });
      setCreating(false);
      if (res.ok) {
        setName("");
        setRawIdea("");
        void load();
      } else {
        setError(
          res.error === "too_many_projects"
            ? "아이디어는 100건까지 저장할 수 있습니다. 쓰지 않는 아이디어를 정리해 주세요."
            : "저장하지 못했습니다.",
        );
      }
    },
    [name, rawIdea, load],
  );

  const saveKey = useCallback(() => {
    setPlanApiKey(apiKey);
    setKeySaved(true);
    setCheckResult(null);
    setTimeout(() => setKeySaved(false), 2000);
  }, [apiKey]);

  /** 토큰을 쓰지 않고 키가 실제로 동작하는지, 어떤 모델을 쓸 수 있는지 확인 */
  const checkKey = useCallback(async () => {
    const key = apiKey.trim();
    if (!key) {
      setCheckResult({ ok: false, text: "키를 먼저 입력해 주세요." });
      return;
    }
    setChecking(true);
    setCheckResult(null);
    const res = await planAi<{ models: string[]; picked: string | null }>("/api/plan/ai/check", key);
    setChecking(false);
    if (res.ok) {
      setCheckResult({
        ok: true,
        text: res.data.picked
          ? `정상입니다. 이 키로 ${res.data.models.length}개 모델을 쓸 수 있고, 구조화에는 ${res.data.picked} 를 사용합니다.`
          : "키는 유효하지만 쓸 수 있는 모델이 없습니다. Anthropic 콘솔에서 결제·권한을 확인해 주세요.",
      });
    } else if (res.error.startsWith("ai_upstream:")) {
      const detail = res.error.slice("ai_upstream:".length);
      setCheckResult({
        ok: false,
        text: `Anthropic 응답 — ${detail}`,
        // 403 은 원인이 여러 개라 점검 목록을 함께 보여준다
        hints: detail.includes("403") ? PLAN_AI_FORBIDDEN_HINTS : undefined,
      });
    } else {
      setCheckResult({
        ok: false,
        text: PLAN_AI_ERROR_MESSAGE[res.error] ?? `확인 실패 (${res.error})`,
      });
    }
  }, [apiKey]);

  if (meLoading) {
    return <main className="mx-auto max-w-5xl px-6 py-20 text-center text-muted">불러오는 중…</main>;
  }

  // ── 비로그인 안내 ──
  if (!isMember) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-20 text-center">
        <div className="text-5xl">🧭</div>
        <h1 className="mt-4 font-display text-3xl font-extrabold tracking-tight">앱기획</h1>
        <p className="mx-auto mt-4 max-w-lg text-muted">
          앱 아이디어를 <b>구조화하고 진단해</b> 유지·수정·피벗을 판단하는 기획 의사결정 도구입니다.
          점수와 판정은 <b>규칙 엔진</b>이 계산하므로 같은 입력이면 항상 같은 결과가 나옵니다.
        </p>
        <div className="mt-8 rounded-2xl border border-line bg-card p-6 text-left text-sm text-muted">
          <p className="font-semibold text-ink">이용하려면</p>
          <ol className="mt-2 list-decimal space-y-1 pl-5">
            <li>우측 상단에서 소셜 계정으로 로그인해 주세요. (회원 등급 이상)</li>
            <li>작성한 아이디어는 <b>본인에게만</b> 보이며 다른 사람은 열람할 수 없습니다.</li>
            <li>AI 구조화 초안 기능은 <b>본인 Anthropic API 키</b>를 입력해야 동작합니다.</li>
          </ol>
        </div>
        <Link
          to="/login"
          className="mt-8 inline-block rounded-full bg-ink px-7 py-3 font-semibold text-white transition hover:bg-green"
        >
          로그인하고 시작하기
        </Link>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      <header className="mb-8">
        <h1 className="font-display text-3xl font-extrabold tracking-tight">앱기획</h1>
        <p className="mt-2 text-muted">
          아이디어를 구조화하고 10개 항목으로 진단해 <b>유지 · 보완 · 피벗</b>을 판단합니다.
          점수·신뢰도·피벗은 규칙 엔진이 계산하며 AI는 초안 작성만 돕습니다.
        </p>
        <p className="mt-1 text-xs text-muted">
          🔒 여기에 적은 아이디어는 <b>{me?.name}</b> 님 본인에게만 보입니다.
        </p>
      </header>

      {/* AI 키 설정 — 브라우저에만 저장 */}
      <section className="mb-8 rounded-2xl border border-line bg-card p-5">
        <button
          onClick={() => setKeyOpen(!keyOpen)}
          className="flex w-full items-center justify-between text-left"
        >
          <span className="text-sm font-semibold">
            🔑 AI 구조화 키 {apiKey ? <span className="text-green">· 설정됨</span> : <span className="text-muted">· 미설정</span>}
          </span>
          <span className="text-muted">{keyOpen ? "▲" : "▼"}</span>
        </button>
        {keyOpen && (
          <div className="mt-4 border-t border-line pt-4">
            <p className="text-sm text-muted">
              AI 진단(구조화 초안)은 <b>본인 Anthropic API 키</b>로만 동작합니다. 키는 이 브라우저에만
              저장되고 서버 DB에는 기록하지 않으며, 요청 처리 후 바로 폐기됩니다.
            </p>
            <div className="mt-3 flex flex-wrap items-center gap-2">
              <input
                type="password"
                value={apiKey}
                onChange={(e) => setApiKeyState(e.target.value)}
                placeholder="sk-ant-..."
                autoComplete="off"
                className="min-w-64 flex-1 rounded-full border border-line bg-paper px-5 py-2 text-sm outline-none focus:border-ink"
              />
              <button
                onClick={saveKey}
                className="rounded-full bg-ink px-6 py-2 text-sm font-semibold text-white transition hover:bg-green"
              >
                {keySaved ? "저장됨 ✓" : "저장"}
              </button>
              <button
                onClick={checkKey}
                disabled={checking}
                className="rounded-full border border-line px-5 py-2 text-sm transition hover:border-ink disabled:opacity-50"
              >
                {checking ? "확인 중…" : "키 점검"}
              </button>
              {apiKey && (
                <button
                  onClick={() => {
                    setApiKeyState("");
                    setPlanApiKey("");
                  }}
                  className="rounded-full border border-line px-5 py-2 text-sm text-muted transition hover:border-ink hover:text-ink"
                >
                  삭제
                </button>
              )}
            </div>
            {checkResult && (
              <div
                className={`mt-3 rounded-xl border px-4 py-3 text-sm ${
                  checkResult.ok
                    ? "border-green bg-lime/20 text-green-deep"
                    : "border-red-200 bg-red-50 text-red-700"
                }`}
              >
                <p className="break-words">{checkResult.text}</p>
                {checkResult.hints && (
                  <>
                    <p className="mt-2 text-xs font-semibold">이 순서로 확인해 보세요</p>
                    <ol className="mt-1 list-decimal space-y-0.5 pl-5 text-xs">
                      {checkResult.hints.map((h, i) => (
                        <li key={i}>{h}</li>
                      ))}
                    </ol>
                  </>
                )}
              </div>
            )}
            <p className="mt-2 text-xs text-muted">
              키 발급: console.anthropic.com → API Keys. <b>키 점검</b>은 토큰을 쓰지 않고 키가
              동작하는지만 확인합니다. AI를 쓰지 않아도 규칙 엔진 진단은 그대로 동작합니다.
            </p>
          </div>
        )}
      </section>

      {/* 새 아이디어 */}
      <section className="mb-10 rounded-2xl border border-line bg-card p-6">
        <h2 className="text-sm font-semibold">새 아이디어 등록</h2>
        <form onSubmit={create} className="mt-4 grid gap-3">
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="앱 이름 (예: 아침 루틴 코치)"
            maxLength={120}
            className="rounded-xl border border-line bg-paper px-4 py-2.5 text-sm outline-none focus:border-ink"
          />
          <textarea
            value={rawIdea}
            onChange={(e) => setRawIdea(e.target.value)}
            placeholder="떠오른 대로 적어도 됩니다. 다음 화면에서 구조화합니다."
            rows={3}
            maxLength={4000}
            className="resize-y rounded-xl border border-line bg-paper px-4 py-2.5 text-sm outline-none focus:border-ink"
          />
          <div>
            <button
              type="submit"
              disabled={creating || !name.trim()}
              className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
            >
              {creating ? "만드는 중…" : "아이디어 만들기"}
            </button>
          </div>
        </form>
      </section>

      {error && (
        <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* 목록 */}
      <section>
        <h2 className="mb-3 text-sm font-semibold text-muted">
          내 아이디어 {projects.length > 0 && `· ${projects.length}건`}
        </h2>

        {/* 단계 필터 — 실제로 등록된 단계만 보여준다 */}
        {projects.length > 1 && (
          <div className="mb-4 flex flex-wrap gap-1.5">
            {(["ALL", ...(Object.keys(PLAN_STAGE_LABEL) as PlanStage[])] as const)
              .filter((s) => s === "ALL" || projects.some((p) => p.stage === s))
              .map((s) => {
                const count = s === "ALL" ? projects.length : projects.filter((p) => p.stage === s).length;
                return (
                  <button
                    key={s}
                    onClick={() => setStageFilter(s)}
                    className={`rounded-full border px-3.5 py-1.5 text-xs font-medium transition ${
                      stageFilter === s
                        ? "border-ink bg-ink text-white"
                        : "border-line text-muted hover:border-ink hover:text-ink"
                    }`}
                  >
                    {s === "ALL" ? "전체" : PLAN_STAGE_LABEL[s]} {count}
                  </button>
                );
              })}
          </div>
        )}
        {loading ? (
          <p className="py-10 text-center text-muted">불러오는 중…</p>
        ) : projects.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-line py-12 text-center text-muted">
            아직 등록한 아이디어가 없습니다. 위에서 첫 아이디어를 만들어 보세요.
          </p>
        ) : (
          <ul className="grid gap-3">
            {projects
              .filter((p) => stageFilter === "ALL" || p.stage === stageFilter)
              .map((p) => (
              <li key={p.id}>
                <Link
                  to={`/app-plan/${p.id}`}
                  className="block rounded-2xl border border-line bg-card p-5 transition hover:border-ink"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="text-base font-semibold">{p.appName}</span>
                    <span className="rounded-full bg-paper px-2.5 py-0.5 text-xs text-muted">
                      {PLAN_STAGE_LABEL[p.stage] ?? p.stage}
                    </span>
                    {p.latest && (
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${decisionTone(p.latest.decision)}`}
                      >
                        {PLAN_PIVOT_LABEL[p.latest.decision] ?? p.latest.decision}
                      </span>
                    )}
                  </div>
                  <div className="mt-2 flex flex-wrap items-center gap-4 text-xs text-muted">
                    {p.latest ? (
                      <>
                        <span>
                          총점 <b className="text-ink">{p.latest.totalScore.toFixed(1)}</b> / 100
                        </span>
                        <span>
                          근거 신뢰도{" "}
                          <b className="text-ink">{(p.latest.overallConfidence * 100).toFixed(0)}%</b>
                        </span>
                        <span>진단 {fmtDate(p.latest.createdAt)}</span>
                      </>
                    ) : (
                      <span>아직 진단하지 않음</span>
                    )}
                    <span className="ml-auto">수정 {fmtDate(p.updatedAt)}</span>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}

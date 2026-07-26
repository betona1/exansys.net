// 앱기획 워크스페이스 — 원문 → 구조화 → 근거 → 진단 → 타깃/MVP → 내보내기
// 본인 아이디어만 열린다. 남의 id 로 들어오면 서버가 404 를 준다.
import { useCallback, useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
  api,
  getPlanApiKey,
  planAi,
  PLAN_AI_ERROR_MESSAGE,
  PLAN_DIMENSION_CODES,
  PLAN_DIMENSION_LABEL,
  PLAN_EVIDENCE_CONFIDENCE,
  PLAN_EVIDENCE_LABEL,
  PLAN_PIVOT_LABEL,
  PLAN_STAGE_FOCUS,
  PLAN_STAGE_LABEL,
  type Me,
  type PlanAnalysisResult,
  type PlanDetail,
  type PlanDimensionCode,
  type PlanEvidence,
  type PlanEvidenceType,
  type PlanProject,
  type PlanStage,
} from "../lib/api";

type Tab = "raw" | "structure" | "evidence" | "diagnosis" | "plan";

const TABS: { key: Tab; label: string; hint: string }[] = [
  { key: "raw", label: "1. 아이디어 원문", hint: "떠오른 그대로. 이후 단계에서 덮어쓰지 않습니다." },
  { key: "structure", label: "2. 구조화", hint: "12칸으로 나눠 적으면 빈칸이 곧 위험 신호입니다." },
  { key: "evidence", label: "3. 근거", hint: "근거가 없으면 모든 항목의 신뢰도가 상한에 묶입니다." },
  { key: "diagnosis", label: "4. 진단", hint: "규칙 엔진이 10개 항목을 채점하고 피벗을 판단합니다." },
  { key: "plan", label: "5. 타깃·MVP", hint: "검증할 타깃 후보와 MVP 범위를 확인합니다." },
];

// 구조화 12칸 정의 — 라벨과 도움말을 한곳에 모아 화면과 검증 기준을 일치시킨다
const STRUCTURE_FIELDS: {
  key: keyof PlanProject;
  label: string;
  hint: string;
  required?: boolean;
  rows?: number;
}[] = [
  { key: "targetUser", label: "사용자", hint: "상황 + 문제 + 현재 행동 + 중단 원인을 한 문장에. '누구나'는 금지.", required: true, rows: 2 },
  { key: "payer", label: "구매자", hint: "결제·설치를 결정하는 사람. 같으면 '사용자와 동일'." },
  { key: "influencer", label: "영향자", hint: "추천하거나 관리하는 사람 (교사·팀장·부모 등)." },
  { key: "problemSituation", label: "문제 상황", hint: "언제, 무엇을 하다가 문제가 생기는가.", required: true, rows: 3 },
  { key: "currentSolution", label: "현재 대체 방법", hint: "지금은 어떻게 넘기고 있는가. 방치도 답입니다." },
  { key: "currentSolutionProblem", label: "대체 방법의 한계", hint: "시간·복잡성·실패·불안·비용 중 무엇 때문에 부족한가.", rows: 2 },
  { key: "coreAction", label: "핵심 행동", hint: "반드시 완료해야 하는 행동 하나.", required: true, rows: 2 },
  { key: "expectedResult", label: "기대 결과", hint: "몇 % / 몇 분 / 몇 회 달라지는가 — 측정 가능하게.", required: true, rows: 2 },
  { key: "firstSuccess", label: "첫 성공 경험", hint: "처음 진입한 사용자가 몇 분 안에 무엇을 해내는가.", rows: 2 },
  { key: "retentionReason", label: "재방문 이유", hint: "내일 다시 열 이유. 제품 안의 장치로.", rows: 2 },
  { key: "revenueModel", label: "수익 모델", hint: "누가 무엇에 지불하는가." },
  { key: "distributionChannel", label: "유입 경로", hint: "첫 100명을 어디서 데려오는가." },
];

// 경고의 field 값(영문 키) → 구조화 탭의 한글 라벨. 경고에서 바로 해당 칸으로 보내는 데 쓴다.
const FIELD_LABEL: Record<string, string> = Object.fromEntries(
  STRUCTURE_FIELDS.map((f) => [f.key as string, f.label]),
);

const RAW_FIELDS: { key: keyof PlanProject; label: string; rows: number }[] = [
  { key: "rawIdea", label: "아이디어", rows: 5 },
  { key: "targetUserRaw", label: "예상 사용자", rows: 2 },
  { key: "problemRaw", label: "문제 상황", rows: 3 },
  { key: "solutionRaw", label: "해결 방법", rows: 3 },
  { key: "revenueModelRaw", label: "수익 모델", rows: 2 },
  { key: "distributionChannelRaw", label: "유입 경로", rows: 2 },
];

const EVIDENCE_TYPES: PlanEvidenceType[] = [
  "USER_INTERVIEW",
  "PROTOTYPE_TEST",
  "BEHAVIOR_DATA",
  "DESK_RESEARCH",
  "EXPERT_REVIEW",
  "FOUNDER_ASSUMPTION",
];

function fmtDateTime(ms: number) {
  const d = new Date(ms);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, "0")}.${String(d.getDate()).padStart(2, "0")} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function decisionTone(decision: string) {
  if (decision === "KEEP") return "bg-lime/40 text-green-deep";
  if (decision === "HOLD") return "bg-paper text-muted";
  if (decision === "REFINE") return "bg-cobalt/10 text-cobalt";
  return "bg-amber-100 text-amber-800";
}

function severityTone(severity: string) {
  if (severity === "CRITICAL") return "border-red-200 bg-red-50 text-red-700";
  if (severity === "WARN") return "border-amber-200 bg-amber-50 text-amber-800";
  return "border-line bg-paper text-muted";
}

export default function AppPlanDetail({ me }: { me: Me }) {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [tab, setTab] = useState<Tab>("raw");
  const [detail, setDetail] = useState<PlanDetail | null>(null);
  const [draft, setDraft] = useState<Partial<PlanProject>>({});
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [saving, setSaving] = useState(false);
  const [savedAt, setSavedAt] = useState<number | null>(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [result, setResult] = useState<PlanAnalysisResult | null>(null);
  const [error, setError] = useState("");
  const [aiBusy, setAiBusy] = useState(false);
  const [aiDraft, setAiDraft] = useState<Record<string, string> | null>(null);
  const [aiError, setAiError] = useState("");
  const [aiModel, setAiModel] = useState("");
  const [aiNotes, setAiNotes] = useState<{ field: string; origin: string; reason: string }[]>([]);
  const [aiUnknowns, setAiUnknowns] = useState<string[]>([]);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await api<PlanDetail>(`/api/plan/projects/${id}`);
    setLoading(false);
    if (res.ok) {
      setDetail(res.data);
      setDraft(res.data.project);
      setResult(res.data.latestResult);
    } else if (res.error === "not_found" || res.error === "unauthorized") {
      setNotFound(true);
    } else {
      setError("불러오지 못했습니다.");
    }
  }, [id]);

  useEffect(() => {
    if (me) void load();
    else setLoading(false);
  }, [me, load]);

  const dirty = useMemo(() => {
    if (!detail) return false;
    return Object.entries(draft).some(
      ([k, v]) => (v ?? "") !== ((detail.project[k as keyof PlanProject] as string | null) ?? ""),
    );
  }, [draft, detail]);

  const setField = useCallback((key: keyof PlanProject, value: string) => {
    setDraft((d) => ({ ...d, [key]: value }));
  }, []);

  /** 경고를 눌렀을 때 구조화 탭의 해당 입력칸으로 이동해 커서를 놓는다 */
  const focusField = useCallback((key: string) => {
    setTab("structure");
    // 탭이 그려진 뒤에 스크롤해야 위치가 잡힌다
    requestAnimationFrame(() => {
      const el = document.getElementById(`plan-field-${key}`);
      el?.scrollIntoView({ behavior: "smooth", block: "center" });
      (el as HTMLTextAreaElement | null)?.focus({ preventScroll: true });
    });
  }, []);

  /** 필수 4칸 중 아직 비어 있는 칸 — 진단 전에 미리 알려준다 */
  const missingRequired = useMemo(
    () =>
      STRUCTURE_FIELDS.filter(
        (f) => f.required && ((draft[f.key] as string | null) ?? "").trim().length < 2,
      ),
    [draft],
  );

  const save = useCallback(async () => {
    if (!detail) return;
    setSaving(true);
    setError("");
    // 서버가 받는 칸만 추린다 (id·userId 등은 보내지 않는다)
    // 이름을 비우면 서버 검증(min 1)에 걸려 저장 전체가 실패하므로 기존 이름을 유지한다
    const payload: Record<string, unknown> = {
      appName: draft.appName?.trim() || detail.project.appName,
      stage: draft.stage,
    };
    for (const f of [...RAW_FIELDS, ...STRUCTURE_FIELDS]) {
      payload[f.key] = (draft[f.key] as string | null) ?? "";
    }
    const res = await api<{ updatedAt: number }>(`/api/plan/projects/${id}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });
    setSaving(false);
    if (res.ok) {
      setSavedAt(res.data.updatedAt);
      setDetail((d) => (d ? { ...d, project: { ...d.project, ...draft } as PlanProject } : d));
    } else {
      setError("저장하지 못했습니다.");
    }
  }, [detail, draft, id]);

  const analyze = useCallback(async () => {
    setAnalyzing(true);
    setError("");
    // 저장하지 않은 수정이 있으면 먼저 저장한다 — 화면과 진단 입력이 어긋나지 않게
    if (dirty) await save();
    const res = await api<{ result: PlanAnalysisResult }>(`/api/plan/projects/${id}/analyze`, {
      method: "POST",
    });
    setAnalyzing(false);
    if (res.ok) {
      setResult(res.data.result);
      setTab("diagnosis");
      void load();
    } else {
      setError("진단에 실패했습니다.");
    }
  }, [dirty, save, id, load]);

  const runAi = useCallback(async () => {
    const key = getPlanApiKey();
    if (!key) {
      setAiError("AI 초안을 쓰려면 앱기획 목록 화면에서 본인 API 키를 먼저 저장해 주세요.");
      return;
    }
    setAiBusy(true);
    setError("");
    setAiError("");
    setAiDraft(null);
    if (dirty) await save();
    const res = await planAi<{
      model: string;
      draft: Record<string, string> & {
        notes?: { field: string; origin: string; reason: string }[];
        unknowns?: string[];
      };
    }>(`/api/plan/projects/${id}/ai/structure`, key);
    setAiBusy(false);
    if (res.ok) {
      const { notes, unknowns, ...fields } = res.data.draft;
      setAiDraft(fields as Record<string, string>);
      setAiNotes(notes ?? []);
      setAiUnknowns(unknowns ?? []);
      setAiModel(res.data.model);
    } else if (res.error.startsWith("ai_upstream:")) {
      // Anthropic 이 알려준 실제 사유를 그대로 보여준다 (크레딧 부족 등)
      setAiError(`Anthropic 응답: ${res.error.slice("ai_upstream:".length)}`);
    } else {
      setAiError(PLAN_AI_ERROR_MESSAGE[res.error] ?? `AI 요청에 실패했습니다. (${res.error})`);
    }
  }, [dirty, save, id]);

  /** AI 초안 채택 — 비어 있는 칸만 채운다. 사람이 쓴 내용을 덮어쓰지 않는다. */
  const applyAiDraft = useCallback(
    async (overwrite: boolean) => {
      if (!aiDraft) return;
      setDraft((d) => {
        const next = { ...d };
        for (const f of STRUCTURE_FIELDS) {
          const incoming = (aiDraft[f.key as string] ?? "").trim();
          if (!incoming) continue;
          const current = ((next[f.key] as string | null) ?? "").trim();
          if (overwrite || !current) (next as Record<string, unknown>)[f.key] = incoming;
        }
        return next;
      });
      setAiDraft(null);
      await api(`/api/plan/projects/${id}/ai/applied`, {
        method: "POST",
        body: JSON.stringify({ model: aiModel }),
      });
      setTab("structure");
    },
    [aiDraft, aiModel, id],
  );

  const remove = useCallback(async () => {
    if (!confirm("이 아이디어와 등록한 근거·진단 이력을 모두 삭제합니다. 되돌릴 수 없습니다.")) return;
    const res = await api(`/api/plan/projects/${id}`, { method: "DELETE" });
    if (res.ok) navigate("/app-plan");
    else setError("삭제하지 못했습니다.");
  }, [id, navigate]);

  if (!me) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-20 text-center">
        <h1 className="font-display text-2xl font-extrabold">로그인이 필요합니다</h1>
        <p className="mt-3 text-muted">앱기획은 로그인한 본인만 열람할 수 있습니다.</p>
        <Link
          to="/login"
          className="mt-6 inline-block rounded-full bg-ink px-7 py-3 font-semibold text-white transition hover:bg-green"
        >
          로그인
        </Link>
      </main>
    );
  }

  if (loading) {
    return <main className="mx-auto max-w-5xl px-6 py-20 text-center text-muted">불러오는 중…</main>;
  }

  if (notFound || !detail) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-20 text-center">
        <h1 className="font-display text-2xl font-extrabold">찾을 수 없는 아이디어입니다</h1>
        <p className="mt-3 text-muted">이미 삭제되었거나 본인의 아이디어가 아닙니다.</p>
        <Link to="/app-plan" className="mt-6 inline-block font-semibold text-cobalt hover:underline">
          내 아이디어 목록으로
        </Link>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      {/* 헤더 */}
      <div className="mb-6">
        <Link to="/app-plan" className="text-sm text-muted hover:text-ink">
          ← 내 아이디어
        </Link>
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <input
            value={draft.appName ?? ""}
            onChange={(e) => setField("appName", e.target.value)}
            maxLength={120}
            className="min-w-52 flex-1 rounded-xl border border-transparent bg-transparent px-2 py-1 font-display text-2xl font-extrabold tracking-tight outline-none hover:border-line focus:border-ink"
          />
          <select
            value={draft.stage ?? "IDEA"}
            onChange={(e) => setField("stage", e.target.value as PlanStage)}
            className="rounded-full border border-line bg-card px-4 py-2 text-sm"
          >
            {(Object.keys(PLAN_STAGE_LABEL) as PlanStage[]).map((s) => (
              <option key={s} value={s}>
                {PLAN_STAGE_LABEL[s]}
              </option>
            ))}
          </select>
          <button
            onClick={save}
            disabled={saving || !dirty}
            className="rounded-full bg-ink px-6 py-2 text-sm font-semibold text-white transition hover:bg-green disabled:opacity-40"
          >
            {saving ? "저장 중…" : dirty ? "저장" : savedAt ? "저장됨 ✓" : "저장"}
          </button>
          <button
            onClick={analyze}
            disabled={analyzing}
            className="rounded-full bg-green px-6 py-2 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
          >
            {analyzing ? "진단 중…" : "진단 실행"}
          </button>
        </div>
        <p className="mt-2 rounded-xl bg-paper px-3 py-2 text-sm">
          <b>{PLAN_STAGE_LABEL[(draft.stage ?? "IDEA") as PlanStage]} 단계</b> —{" "}
          <span className="text-muted">{PLAN_STAGE_FOCUS[(draft.stage ?? "IDEA") as PlanStage]}</span>
        </p>
        <p className="mt-2 text-xs text-muted">
          🔒 본인 전용 · 마지막 수정 {fmtDateTime(savedAt ?? detail.project.updatedAt)}
          {detail.project.aiModel && ` · 구조화 초안 보조: ${detail.project.aiModel}`}
        </p>
      </div>

      {error && (
        <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* 필수 칸 안내 — 진단 엔진은 원문이 아니라 구조화 12칸만 읽는다 */}
      {missingRequired.length > 0 && (
        <div className="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          <p className="font-semibold">
            아직 채우지 않은 필수 칸이 {missingRequired.length}개 있습니다
          </p>
          <p className="mt-1 text-xs">
            진단은 <b>① 원문이 아니라 ② 구조화 12칸</b>을 읽습니다. 아래 칸이 비면 관련 항목이 0점이
            되고 치명 경고가 뜹니다.
          </p>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {missingRequired.map((f) => (
              <button
                key={f.key}
                onClick={() => focusField(f.key as string)}
                className="rounded-full bg-white px-3 py-1 text-xs font-semibold underline-offset-2 hover:underline"
              >
                {f.label} 적기 →
              </button>
            ))}
          </div>
        </div>
      )}

      {/* 최근 진단 요약 */}
      {result && (
        <section className="mb-8 rounded-2xl border border-line bg-card p-5">
          <div className="flex flex-wrap items-center gap-3">
            <span
              className={`rounded-full px-3 py-1 text-sm font-bold ${decisionTone(result.pivot.decision)}`}
            >
              {PLAN_PIVOT_LABEL[result.pivot.decision]}
            </span>
            {result.pivot.wouldBeDecision && (
              <span className="text-xs text-muted">
                근거가 충분했다면 → {PLAN_PIVOT_LABEL[result.pivot.wouldBeDecision]}
              </span>
            )}
            <span className="text-sm">
              총점 <b>{result.diagnosis.totalScore.toFixed(1)}</b>
              <span className="text-muted"> / 100</span>
            </span>
            <span className="text-sm">
              근거 신뢰도 <b>{(result.diagnosis.overallConfidence * 100).toFixed(0)}%</b>
            </span>
          </div>
          <p className="mt-3 text-sm text-muted">{result.pivot.rationale}</p>
        </section>
      )}

      {/* 탭 */}
      <nav className="mb-6 flex flex-wrap gap-2 border-b border-line pb-3">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`rounded-full px-4 py-2 text-sm font-medium transition ${
              tab === t.key ? "bg-ink text-white" : "text-muted hover:bg-paper hover:text-ink"
            }`}
          >
            {t.label}
          </button>
        ))}
      </nav>
      <p className="mb-6 text-xs text-muted">{TABS.find((t) => t.key === tab)?.hint}</p>

      {/* 1. 원문 */}
      {tab === "raw" && (
        <section className="grid gap-5">
          {RAW_FIELDS.map((f) => (
            <label key={f.key} className="grid gap-1.5">
              <span className="text-sm font-semibold">{f.label}</span>
              <textarea
                value={(draft[f.key] as string | null) ?? ""}
                onChange={(e) => setField(f.key, e.target.value)}
                rows={f.rows}
                maxLength={4000}
                className="resize-y rounded-xl border border-line bg-card px-4 py-3 text-sm outline-none focus:border-ink"
              />
            </label>
          ))}
          <div className="rounded-2xl border border-line bg-card p-5">
            <p className="text-sm font-semibold">AI 구조화 초안</p>
            <p className="mt-1 text-sm text-muted">
              위 원문을 12칸으로 나누는 <b>초안</b>만 만듭니다. 점수·신뢰도·피벗 판정에는 관여하지
              않으며, 원문에 없는 내용은 비워 둡니다. 본인 API 키로 동작합니다.
            </p>
            <button
              onClick={runAi}
              disabled={aiBusy}
              className="mt-3 rounded-full bg-cobalt px-6 py-2 text-sm font-semibold text-white transition hover:opacity-90 disabled:opacity-50"
            >
              {aiBusy ? "초안 만드는 중…" : "AI로 구조화 초안 만들기"}
            </button>
            {aiError && (
              <div className="mt-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                <p className="font-semibold">AI 요청 실패</p>
                <p className="mt-1 break-words">{aiError}</p>
                <p className="mt-2 text-xs">
                  키·크레딧은 console.anthropic.com → Settings 에서 확인할 수 있습니다. AI 없이 아래
                  ② 구조화 탭을 직접 채워도 진단 결과는 동일합니다.
                </p>
              </div>
            )}
          </div>

          {/* AI 초안 검토 */}
          {aiDraft && (
            <div className="rounded-2xl border-2 border-cobalt bg-card p-5">
              <h3 className="text-sm font-bold">
                AI 초안 — 확인 후 반영하세요
                {aiModel && <span className="ml-2 text-xs font-normal text-muted">{aiModel}</span>}
              </h3>
              <p className="mt-1 text-xs text-muted">
                INFERRED로 표시된 칸은 원문에 없는 추측입니다. 반드시 직접 확인하세요.
              </p>
              <dl className="mt-4 grid gap-3">
                {STRUCTURE_FIELDS.map((f) => {
                  const val = (aiDraft[f.key as string] ?? "").trim();
                  const note = aiNotes.find((n) => n.field === f.key);
                  return (
                    <div key={f.key} className="rounded-xl bg-paper p-3">
                      <dt className="flex items-center gap-2 text-xs font-semibold">
                        {f.label}
                        {note && (
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] ${
                              note.origin === "INFERRED"
                                ? "bg-amber-100 text-amber-800"
                                : note.origin === "MISSING"
                                  ? "bg-paper text-muted"
                                  : "bg-lime/40 text-green-deep"
                            }`}
                          >
                            {note.origin}
                          </span>
                        )}
                      </dt>
                      <dd className="mt-1 text-sm">{val || <span className="text-muted">(비움)</span>}</dd>
                      {note?.reason && <p className="mt-1 text-xs text-muted">{note.reason}</p>}
                    </div>
                  );
                })}
              </dl>
              {aiUnknowns.length > 0 && (
                <div className="mt-4 rounded-xl border border-line p-3">
                  <p className="text-xs font-semibold">사람이 직접 확인해야 할 것</p>
                  <ul className="mt-1 list-disc space-y-0.5 pl-5 text-xs text-muted">
                    {aiUnknowns.map((u, i) => (
                      <li key={i}>{u}</li>
                    ))}
                  </ul>
                </div>
              )}
              <div className="mt-4 flex flex-wrap gap-2">
                <button
                  onClick={() => applyAiDraft(false)}
                  className="rounded-full bg-green px-5 py-2 text-sm font-semibold text-white transition hover:bg-green-deep"
                >
                  빈칸만 채우기
                </button>
                <button
                  onClick={() => applyAiDraft(true)}
                  className="rounded-full border border-line px-5 py-2 text-sm transition hover:border-ink"
                >
                  전부 덮어쓰기
                </button>
                <button
                  onClick={() => setAiDraft(null)}
                  className="rounded-full px-5 py-2 text-sm text-muted transition hover:text-ink"
                >
                  버리기
                </button>
              </div>
            </div>
          )}
        </section>
      )}

      {/* 2. 구조화 */}
      {tab === "structure" && (
        <section className="grid gap-5">
          {STRUCTURE_FIELDS.map((f) => {
            const value = ((draft[f.key] as string | null) ?? "").trim();
            const empty = f.required && value.length < 2;
            return (
              <label key={f.key} className="grid gap-1.5">
                <span className="flex items-center gap-2 text-sm font-semibold">
                  {f.label}
                  {f.required && <span className="text-xs text-red-600">필수</span>}
                  {empty && <span className="text-xs text-red-600">— 비어 있으면 관련 항목이 0점입니다</span>}
                </span>
                <span className="text-xs text-muted">{f.hint}</span>
                <textarea
                  id={`plan-field-${f.key}`}
                  value={(draft[f.key] as string | null) ?? ""}
                  onChange={(e) => setField(f.key, e.target.value)}
                  rows={f.rows ?? 1}
                  maxLength={4000}
                  className={`resize-y rounded-xl border bg-card px-4 py-3 text-sm outline-none focus:border-ink ${
                    empty ? "border-red-200" : "border-line"
                  }`}
                />
              </label>
            );
          })}
        </section>
      )}

      {/* 3. 근거 */}
      {tab === "evidence" && (
        <EvidenceSection
          projectId={Number(id)}
          evidence={detail.evidence}
          onChanged={load}
          onError={setError}
        />
      )}

      {/* 4. 진단 */}
      {tab === "diagnosis" && (
        <section className="grid gap-6">
          {!result ? (
            <p className="rounded-2xl border border-dashed border-line py-12 text-center text-muted">
              아직 진단하지 않았습니다. 위의 <b>진단 실행</b>을 눌러주세요.
            </p>
          ) : (
            <>
              {/* 지금 할 일 */}
              <div className="rounded-2xl border border-line bg-card p-5">
                <h3 className="text-sm font-bold">지금 할 일</h3>
                <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm">
                  {result.nextActions.map((a, i) => (
                    <li key={i}>{a}</li>
                  ))}
                </ol>
              </div>

              {/* 경고 */}
              {result.diagnosis.warnings.length > 0 && (
                <div className="grid gap-2">
                  <h3 className="text-sm font-bold">경고 {result.diagnosis.warnings.length}건</h3>
                  {result.diagnosis.warnings.map((w, i) => (
                    <div
                      key={i}
                      className={`rounded-xl border px-4 py-3 text-sm ${severityTone(w.severity)}`}
                    >
                      <p className="font-semibold">
                        [{w.severity === "CRITICAL" ? "치명" : w.severity === "WARN" ? "주의" : "참고"}]{" "}
                        {w.field && FIELD_LABEL[w.field] ? FIELD_LABEL[w.field] : w.code}
                      </p>
                      <p className="mt-1">{w.message}</p>
                      {w.recommendedAction && (
                        <p className="mt-1 text-xs opacity-80">→ {w.recommendedAction}</p>
                      )}
                      {w.field && FIELD_LABEL[w.field] && (
                        <button
                          onClick={() => focusField(w.field as string)}
                          className="mt-2 rounded-full bg-white/70 px-3 py-1 text-xs font-semibold underline-offset-2 hover:underline"
                        >
                          ✏️ 구조화 탭의 「{FIELD_LABEL[w.field]}」 칸에서 고치기
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* 항목별 점수 */}
              <div className="grid gap-2">
                <h3 className="text-sm font-bold">평가 항목</h3>
                {result.diagnosis.dimensions.map((d) => (
                  <div key={d.code} className="rounded-xl border border-line bg-card p-4">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-sm font-semibold">
                        {d.code} {d.label}
                      </span>
                      <span className="text-sm font-bold">{d.rawScore}/5</span>
                      <span className="text-xs text-muted">가중치 {d.weight}</span>
                      <span className="text-xs text-muted">
                        신뢰도 {(d.confidence * 100).toFixed(0)}%
                      </span>
                      <span className="ml-auto h-2 w-28 overflow-hidden rounded-full bg-paper">
                        <span
                          className="block h-full rounded-full bg-green"
                          style={{ width: `${(d.rawScore / 5) * 100}%` }}
                        />
                      </span>
                    </div>
                    <p className="mt-2 text-xs text-muted">{d.reason}</p>
                    {d.rawScore < 4 && (
                      <p className="mt-1 text-xs text-cobalt">→ {d.recommendedAction}</p>
                    )}
                    {d.missingEvidence.length > 0 && (
                      <p className="mt-1 text-xs text-amber-700">
                        부족한 근거: {d.missingEvidence.join(", ")}
                      </p>
                    )}
                  </div>
                ))}
              </div>

              {/* 유지·변경·삭제 */}
              <div className="grid gap-4 sm:grid-cols-3">
                <ListCard title="유지" items={result.pivot.keep} />
                <ListCard title="변경" items={result.pivot.change} />
                <ListCard title="삭제" items={result.pivot.remove} />
              </div>

              {/* 아직 모르는 것 */}
              <ListCard title="아직 모르는 것" items={result.diagnosis.unknowns} />

              {/* 내보내기 */}
              <div className="rounded-2xl border border-line bg-card p-5">
                <h3 className="text-sm font-bold">내보내기</h3>
                <div className="mt-3 flex flex-wrap gap-2">
                  <a
                    href={`/api/plan/projects/${id}/export?format=report`}
                    className="rounded-full border border-line px-5 py-2 text-sm transition hover:border-ink"
                  >
                    진단 보고서 (.md)
                  </a>
                  <a
                    href={`/api/plan/projects/${id}/export?format=techspec`}
                    className="rounded-full border border-line px-5 py-2 text-sm transition hover:border-ink"
                  >
                    기술 명세 TECHSPEC (.md)
                  </a>
                </div>
                <p className="mt-2 text-xs text-muted">
                  판정 엔진 {result.meta.engine} {result.meta.engineVersion} · 정책{" "}
                  {result.meta.policyVersion}
                </p>
              </div>

              {/* 이력 */}
              {detail.history.length > 1 && (
                <div className="rounded-2xl border border-line bg-card p-5">
                  <h3 className="text-sm font-bold">진단 이력</h3>
                  <ul className="mt-3 grid gap-1.5 text-sm">
                    {detail.history.map((h) => (
                      <li key={h.id} className="flex flex-wrap items-center gap-3">
                        <span className="text-xs text-muted">{fmtDateTime(h.createdAt)}</span>
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs font-semibold ${decisionTone(h.decision)}`}
                        >
                          {PLAN_PIVOT_LABEL[h.decision]}
                        </span>
                        <span className="text-xs">총점 {h.totalScore.toFixed(1)}</span>
                        <span className="text-xs text-muted">
                          신뢰도 {(h.overallConfidence * 100).toFixed(0)}%
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </>
          )}
        </section>
      )}

      {/* 5. 타깃 · MVP */}
      {tab === "plan" && (
        <section className="grid gap-6">
          {!result ? (
            <p className="rounded-2xl border border-dashed border-line py-12 text-center text-muted">
              진단을 먼저 실행하면 타깃 후보와 MVP 범위가 만들어집니다.
            </p>
          ) : (
            <>
              <div>
                <h3 className="text-sm font-bold">타깃 후보</h3>
                <p className="mt-1 text-xs text-muted">{result.targets.recommendationReason}</p>
                <div className="mt-3 grid gap-3">
                  {result.targets.candidates.map((c, i) => (
                    <div
                      key={i}
                      className={`rounded-2xl border bg-card p-5 ${
                        result.targets.recommendedCandidateIndex === i
                          ? "border-green"
                          : "border-line"
                      }`}
                    >
                      <p className="text-sm font-semibold">
                        {c.name}
                        {result.targets.recommendedCandidateIndex === i && (
                          <span className="ml-2 rounded-full bg-lime/40 px-2 py-0.5 text-xs text-green-deep">
                            추천
                          </span>
                        )}
                      </p>
                      <dl className="mt-2 grid gap-1 text-sm">
                        <Row label="사용자" value={c.user} />
                        <Row label="구매자" value={c.payer} />
                        <Row label="발생 상황" value={c.triggerSituation} />
                        <Row label="문제" value={c.problem} />
                        <Row label="현재 대체 방법" value={c.currentAlternative} />
                      </dl>
                      <p className="mt-2 text-xs text-amber-700">위험: {c.risks.join(" / ")}</p>
                      <p className="mt-1 text-xs text-cobalt">
                        권장 실험: {c.recommendedExperiment}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="rounded-2xl border border-line bg-card p-5">
                <h3 className="text-sm font-bold">MVP 범위</h3>
                <dl className="mt-3 grid gap-1 text-sm">
                  <Row label="핵심 가설" value={result.mvp.coreHypothesis} />
                  <Row label="행동 가설" value={result.mvp.behaviorHypothesis} />
                  <Row label="가치 가설" value={result.mvp.valueHypothesis} />
                  <Row label="재방문 가설" value={result.mvp.retentionHypothesis} />
                  {result.mvp.revenueHypothesis && (
                    <Row label="수익 가설" value={result.mvp.revenueHypothesis} />
                  )}
                </dl>
                <div className="mt-4 grid gap-4 sm:grid-cols-3">
                  <ListCard title="P0 (반드시)" items={result.mvp.p0Features} flat />
                  <ListCard title="P1 (최소한만)" items={result.mvp.p1Features} flat />
                  <ListCard title="이번엔 제외" items={result.mvp.excludedFeatures} flat />
                </div>
                <div className="mt-4">
                  <p className="text-xs font-semibold">핵심 사용자 흐름</p>
                  <ol className="mt-1 list-decimal space-y-0.5 pl-5 text-sm text-muted">
                    {result.mvp.coreUserFlow.map((s, i) => (
                      <li key={i}>{s}</li>
                    ))}
                  </ol>
                </div>
                <div className="mt-4">
                  <p className="text-xs font-semibold">측정 이벤트</p>
                  <p className="mt-1 text-sm text-muted">{result.mvp.metrics.join(", ")}</p>
                  <p className="mt-1 text-xs text-muted">
                    측정 이벤트가 연결되지 않은 기능은 이번 범위에 넣지 않습니다.
                  </p>
                </div>
              </div>
            </>
          )}
        </section>
      )}

      {/* 삭제 */}
      <div className="mt-12 border-t border-line pt-6">
        <button onClick={remove} className="text-sm text-red-600 hover:underline">
          이 아이디어 삭제
        </button>
      </div>
    </main>
  );
}

function Row({ label, value }: { label: string; value: string | null }) {
  return (
    <div className="flex gap-2">
      <dt className="w-24 shrink-0 text-xs text-muted">{label}</dt>
      <dd className="flex-1">{value?.trim() || <span className="text-muted">(미입력)</span>}</dd>
    </div>
  );
}

function ListCard({ title, items, flat }: { title: string; items: string[]; flat?: boolean }) {
  return (
    <div className={flat ? "" : "rounded-2xl border border-line bg-card p-5"}>
      <h4 className="text-xs font-bold">{title}</h4>
      {items.length === 0 ? (
        <p className="mt-1 text-sm text-muted">(없음)</p>
      ) : (
        <ul className="mt-1 list-disc space-y-1 pl-5 text-sm text-muted">
          {items.map((i, idx) => (
            <li key={idx}>{i}</li>
          ))}
        </ul>
      )}
    </div>
  );
}

// ── 근거 섹션 ──
function EvidenceSection({
  projectId,
  evidence,
  onChanged,
  onError,
}: {
  projectId: number;
  evidence: PlanEvidence[];
  onChanged: () => void | Promise<void>;
  onError: (m: string) => void;
}) {
  const [type, setType] = useState<PlanEvidenceType>("USER_INTERVIEW");
  const [title, setTitle] = useState("");
  const [summary, setSummary] = useState("");
  const [sampleSize, setSampleSize] = useState("");
  const [supports, setSupports] = useState<PlanDimensionCode[]>([]);
  const [contradicts, setContradicts] = useState<PlanDimensionCode[]>([]);
  const [busy, setBusy] = useState(false);

  const toggle = (
    code: PlanDimensionCode,
    list: PlanDimensionCode[],
    set: (v: PlanDimensionCode[]) => void,
  ) => {
    set(list.includes(code) ? list.filter((c) => c !== code) : [...list, code]);
  };

  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setBusy(true);
    const res = await api(`/api/plan/projects/${projectId}/evidence`, {
      method: "POST",
      body: JSON.stringify({
        evidenceType: type,
        title: title.trim(),
        summary: summary.trim(),
        sampleSize: sampleSize ? Number(sampleSize) : null,
        supports,
        contradicts,
      }),
    });
    setBusy(false);
    if (res.ok) {
      setTitle("");
      setSummary("");
      setSampleSize("");
      setSupports([]);
      setContradicts([]);
      await onChanged();
    } else {
      onError("근거를 저장하지 못했습니다.");
    }
  };

  const del = async (id: number) => {
    const res = await api(`/api/plan/evidence/${id}`, { method: "DELETE" });
    if (res.ok) await onChanged();
    else onError("삭제하지 못했습니다.");
  };

  return (
    <section className="grid gap-6">
      <div className="rounded-2xl border border-line bg-card p-5">
        <h3 className="text-sm font-bold">근거 등록</h3>
        <p className="mt-1 text-xs text-muted">
          AI는 근거를 만들지 않습니다. 여기 등록된 것은 전부 사람이 직접 확인한 것입니다. 근거가
          없으면 모든 항목의 신뢰도가 20%에 묶이고 판단은 <b>보류</b>가 됩니다.
        </p>
        <form onSubmit={add} className="mt-4 grid gap-3">
          <div className="flex flex-wrap gap-3">
            <select
              value={type}
              onChange={(e) => setType(e.target.value as PlanEvidenceType)}
              className="rounded-xl border border-line bg-paper px-4 py-2 text-sm"
            >
              {EVIDENCE_TYPES.map((t) => (
                <option key={t} value={t}>
                  {PLAN_EVIDENCE_LABEL[t]} ({(PLAN_EVIDENCE_CONFIDENCE[t] * 100).toFixed(0)}%)
                </option>
              ))}
            </select>
            <input
              value={sampleSize}
              onChange={(e) => setSampleSize(e.target.value.replace(/\D/g, ""))}
              placeholder="표본 수"
              inputMode="numeric"
              className="w-28 rounded-xl border border-line bg-paper px-4 py-2 text-sm outline-none focus:border-ink"
            />
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="근거 제목 (예: 30대 직장인 5명 인터뷰)"
              maxLength={200}
              className="min-w-52 flex-1 rounded-xl border border-line bg-paper px-4 py-2 text-sm outline-none focus:border-ink"
            />
          </div>
          <textarea
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            placeholder="무엇을 확인했는가 (사실만, 해석은 빼고)"
            rows={2}
            maxLength={2000}
            className="resize-y rounded-xl border border-line bg-paper px-4 py-2.5 text-sm outline-none focus:border-ink"
          />
          <div>
            <p className="text-xs font-semibold">이 근거가 <span className="text-green">지지</span>하는 항목</p>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {PLAN_DIMENSION_CODES.map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => toggle(c, supports, setSupports)}
                  className={`rounded-full border px-3 py-1 text-xs transition ${
                    supports.includes(c)
                      ? "border-green bg-lime/30 font-semibold text-green-deep"
                      : "border-line text-muted hover:border-ink"
                  }`}
                >
                  {c} {PLAN_DIMENSION_LABEL[c]}
                </button>
              ))}
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold">이 근거가 <span className="text-red-600">반박</span>하는 항목</p>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {PLAN_DIMENSION_CODES.map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => toggle(c, contradicts, setContradicts)}
                  className={`rounded-full border px-3 py-1 text-xs transition ${
                    contradicts.includes(c)
                      ? "border-red-300 bg-red-50 font-semibold text-red-700"
                      : "border-line text-muted hover:border-ink"
                  }`}
                >
                  {c}
                </button>
              ))}
            </div>
          </div>
          <div>
            <button
              type="submit"
              disabled={busy || !title.trim()}
              className="rounded-full bg-green px-6 py-2 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
            >
              {busy ? "저장 중…" : "근거 추가"}
            </button>
          </div>
        </form>
      </div>

      <div>
        <h3 className="mb-3 text-sm font-bold">등록된 근거 {evidence.length}건</h3>
        {evidence.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-line py-10 text-center text-muted">
            아직 근거가 없습니다.
          </p>
        ) : (
          <ul className="grid gap-2">
            {evidence.map((e) => (
              <li key={e.id} className="rounded-xl border border-line bg-card p-4">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="rounded-full bg-paper px-2.5 py-0.5 text-xs">
                    {PLAN_EVIDENCE_LABEL[e.evidenceType]}
                  </span>
                  <span className="text-sm font-semibold">{e.title}</span>
                  {e.sampleSize != null && (
                    <span className="text-xs text-muted">n={e.sampleSize}</span>
                  )}
                  <button
                    onClick={() => del(e.id)}
                    className="ml-auto text-xs text-muted hover:text-red-600"
                  >
                    삭제
                  </button>
                </div>
                {e.summary && <p className="mt-1.5 text-sm text-muted">{e.summary}</p>}
                <p className="mt-1.5 text-xs">
                  {e.supports.length > 0 && (
                    <span className="text-green-deep">지지: {e.supports.join(", ")}</span>
                  )}
                  {e.contradicts.length > 0 && (
                    <span className="ml-3 text-red-600">반박: {e.contradicts.join(", ")}</span>
                  )}
                </p>
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  );
}

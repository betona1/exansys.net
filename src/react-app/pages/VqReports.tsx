// VibeQuest 문제 신고 게시판 — 누구나 열람, staff 이상이 처리·용어 수정
import { useCallback, useEffect, useState } from "react";
import { api, type Me } from "../lib/api";

type Report = {
  id: number;
  termId: string;
  termKo: string;
  questionType: string | null;
  reason: "wrong_answer" | "typo" | "bad_explanation" | "other";
  detail: string | null;
  status: "open" | "fixed" | "rejected";
  createdAt: number;
  resolvedAt: number | null;
};

type VqTerm = {
  id: string;
  termKo: string;
  termEn: string;
  def: string;
  whyItMatters?: string;
  example?: string;
  difficulty?: number;
};

const REASON_LABEL: Record<Report["reason"], string> = {
  wrong_answer: "정답 오류",
  typo: "오타",
  bad_explanation: "설명 이상",
  other: "기타",
};

const STATUS_META: Record<Report["status"], { label: string; cls: string }> = {
  open: { label: "접수됨", cls: "bg-amber-100 text-amber-700" },
  fixed: { label: "수정 완료", cls: "bg-green/15 text-green-deep" },
  rejected: { label: "문제 없음", cls: "bg-paper text-muted" },
};

export default function VqReports({ me }: { me: Me }) {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<VqTerm | null>(null);
  const isStaff = Boolean(me && (me.role === "staff" || me.role === "admin"));

  const load = useCallback(async () => {
    const r = await api<{ reports: Report[] }>("/api/vibequest/reports");
    setLoading(false);
    if (r.ok) setReports(r.data.reports);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const setStatus = async (id: number, status: Report["status"]) => {
    const r = await api(`/api/vibequest/reports/${id}/status`, {
      method: "POST",
      body: JSON.stringify({ status }),
    });
    if (r.ok) void load();
  };

  const openEditor = async (termId: string) => {
    const r = await api<{ term: VqTerm }>(`/api/vibequest/terms/${termId}`);
    if (r.ok) setEditing(r.data.term);
    else window.alert("용어를 불러오지 못했습니다.");
  };

  const fmt = (ms: number) => new Date(ms).toLocaleDateString("ko-KR");

  return (
    <main className="mx-auto max-w-3xl px-6 py-14">
      <p className="mb-2 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">VIBEQUEST</p>
      <h1 className="font-display text-3xl font-extrabold tracking-tight">문제 신고 게시판</h1>
      <p className="mt-2 text-muted">
        VibeQuest 앱에서 접수된 문제 오류 신고입니다. 관리자가 확인해 수정하면 앱에 자동 반영됩니다.
      </p>

      {loading && <p className="mt-10 text-center text-muted">불러오는 중…</p>}
      {!loading && reports.length === 0 && (
        <div className="mt-10 rounded-2xl border border-dashed border-line p-10 text-center text-sm text-muted">
          아직 접수된 신고가 없습니다. 🐾
        </div>
      )}

      <div className="mt-8 space-y-4">
        {reports.map((r) => (
          <div key={r.id} className="rounded-2xl border border-line bg-card p-5">
            <div className="flex flex-wrap items-center gap-2">
              <span className={`rounded-full px-3 py-1 text-xs font-bold ${STATUS_META[r.status].cls}`}>
                {STATUS_META[r.status].label}
              </span>
              <span className="rounded-full bg-lime/20 px-3 py-1 text-xs font-bold text-green-deep">
                {REASON_LABEL[r.reason]}
              </span>
              <span className="ml-auto text-xs text-muted">#{r.id} · {fmt(r.createdAt)}</span>
            </div>
            <h3 className="font-display mt-3 text-lg font-bold">
              {r.termKo} <span className="text-sm font-normal text-muted">({r.termId})</span>
            </h3>
            {r.detail && <p className="mt-1.5 whitespace-pre-line text-[14.5px] text-ink/80">{r.detail}</p>}
            {isStaff && (
              <div className="mt-4 flex flex-wrap gap-2 border-t border-line pt-3">
                <button onClick={() => void openEditor(r.termId)}
                  className="rounded-full bg-ink px-4 py-1.5 text-xs font-semibold text-white hover:bg-green">
                  ✏️ 용어 수정
                </button>
                {(["fixed", "rejected", "open"] as const).map((s) => (
                  <button key={s} onClick={() => void setStatus(r.id, s)}
                    disabled={r.status === s}
                    className="rounded-full border border-line px-4 py-1.5 text-xs font-semibold hover:border-ink disabled:opacity-40">
                    {STATUS_META[s].label}로
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>

      {editing && <TermEditor term={editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); void load(); }} />}
    </main>
  );
}

function TermEditor({ term, onClose, onSaved }: { term: VqTerm; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    termKo: term.termKo,
    termEn: term.termEn,
    def: term.def,
    whyItMatters: term.whyItMatters ?? "",
    example: term.example ?? "",
    difficulty: term.difficulty ?? 2,
  });
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");
  const input = "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";

  const save = async () => {
    setSaving(true);
    setMsg("");
    const r = await api<{ contentVersion: number }>(`/api/vibequest/terms/${term.id}`, {
      method: "PUT",
      body: JSON.stringify(form),
    });
    setSaving(false);
    if (r.ok) {
      setMsg(`저장 완료 — 콘텐츠 버전 v${r.data.contentVersion}, 앱에 자동 반영됩니다.`);
      setTimeout(onSaved, 900);
    } else {
      setMsg(`오류: ${r.error}`);
    }
  };

  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-ink/40 p-4" onClick={onClose}>
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-card p-6" onClick={(e) => e.stopPropagation()}>
        <h2 className="font-display text-xl font-bold">용어 수정 — {term.id}</h2>
        <p className="mt-1 text-xs text-muted">저장하면 콘텐츠 버전이 올라가고 VibeQuest 앱이 다음 실행 때 받아갑니다.</p>
        <div className="mt-5 grid gap-3">
          <label className="text-xs font-semibold text-muted">용어(한국어)
            <input className={input} value={form.termKo} onChange={(e) => setForm({ ...form, termKo: e.target.value })} />
          </label>
          <label className="text-xs font-semibold text-muted">영문·부제
            <input className={input} value={form.termEn} onChange={(e) => setForm({ ...form, termEn: e.target.value })} />
          </label>
          <label className="text-xs font-semibold text-muted">정의
            <textarea className={`${input} h-24`} value={form.def} onChange={(e) => setForm({ ...form, def: e.target.value })} />
          </label>
          <label className="text-xs font-semibold text-muted">왜 중요한지
            <textarea className={`${input} h-20`} value={form.whyItMatters} onChange={(e) => setForm({ ...form, whyItMatters: e.target.value })} />
          </label>
          <label className="text-xs font-semibold text-muted">예시
            <textarea className={`${input} h-20`} value={form.example} onChange={(e) => setForm({ ...form, example: e.target.value })} />
          </label>
          <label className="text-xs font-semibold text-muted">난이도 (1 초급 ~ 4 심화)
            <select className={input} value={form.difficulty}
              onChange={(e) => setForm({ ...form, difficulty: Number(e.target.value) })}>
              {[1, 2, 3, 4].map((d) => <option key={d} value={d}>{d}</option>)}
            </select>
          </label>
        </div>
        <div className="mt-5 flex items-center gap-3">
          <button onClick={() => void save()} disabled={saving}
            className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white hover:bg-green-deep disabled:opacity-50">
            {saving ? "저장 중…" : "저장"}
          </button>
          <button onClick={onClose} className="text-sm font-semibold text-muted hover:text-ink">닫기</button>
          {msg && <span className="text-xs font-semibold text-green">{msg}</span>}
        </div>
      </div>
    </div>
  );
}

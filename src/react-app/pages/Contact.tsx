// 개발문의게시판 (CLAUDE.md 5-3절)
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, type Me } from "../lib/api";
import Turnstile from "../components/Turnstile";

type InquiryRow = {
  id: number;
  title: string;
  isPrivate: boolean;
  status: "open" | "answered";
  createdAt: string;
  authorName: string;
  mine: boolean;
};

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("ko-KR", { year: "numeric", month: "2-digit", day: "2-digit" });
}

export default function Contact({ me }: { me: Me }) {
  const [list, setList] = useState<InquiryRow[]>([]);
  const [siteKey, setSiteKey] = useState<string | null>(null);
  const [writing, setWriting] = useState(false);
  const [form, setForm] = useState({ title: "", body: "", contact: "", isPrivate: false });
  const [token, setToken] = useState("");
  const [msg, setMsg] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    const res = await api<{ inquiries: InquiryRow[] }>("/api/inquiries");
    if (res.ok) setList(res.data.inquiries);
  }, []);

  useEffect(() => {
    void load();
    void api<{ turnstileSiteKey: string | null }>("/api/config").then((res) => {
      if (res.ok) setSiteKey(res.data.turnstileSiteKey);
    });
  }, [load]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (siteKey && !token) {
      setMsg("스팸 방지 확인을 완료해 주세요.");
      return;
    }
    setSubmitting(true);
    setMsg("");
    const res = await api<{ id: number }>("/api/inquiries", {
      method: "POST",
      body: JSON.stringify({ ...form, contact: form.contact || null, turnstileToken: token }),
    });
    setSubmitting(false);
    if (res.ok) {
      setWriting(false);
      setForm({ title: "", body: "", contact: "", isPrivate: false });
      setToken("");
      void load();
    } else {
      setMsg(`오류: ${res.error}`);
    }
  };

  const input =
    "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";

  return (
    <main className="mx-auto max-w-4xl px-6 py-14">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">개발 문의</h1>
          <p className="mt-2 text-muted">
            앱 외주 개발, 파트너십, 서비스 문의 — 모든 글에 답변합니다.
          </p>
        </div>
        {me ? (
          <button
            onClick={() => setWriting(!writing)}
            className="rounded-full bg-green px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep"
          >
            {writing ? "닫기" : "문의 작성"}
          </button>
        ) : (
          <p className="text-sm text-muted">문의를 작성하려면 우측 상단에서 로그인해 주세요.</p>
        )}
      </div>

      {writing && me && (
        <form onSubmit={submit} className="mt-8 rounded-2xl border border-line bg-card p-6">
          <div className="grid gap-4">
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">제목</label>
              <input className={input} required minLength={2} maxLength={120} value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })} />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">내용</label>
              <textarea className={`${input} h-36`} required minLength={5} maxLength={5000} value={form.body}
                onChange={(e) => setForm({ ...form, body: e.target.value })}
                placeholder="만들고 싶은 앱, 일정, 예산 범위 등을 자유롭게 적어주세요." />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">연락처 (선택)</label>
              <input className={input} maxLength={200} value={form.contact} placeholder="이메일 또는 전화번호"
                onChange={(e) => setForm({ ...form, contact: e.target.value })} />
              <p className="mt-1 text-xs text-muted">연락처는 작성자 본인과 EXANSYS 직원에게만 보입니다.</p>
            </div>
            <label className="flex items-center gap-2 text-sm font-medium">
              <input type="checkbox" checked={form.isPrivate}
                onChange={(e) => setForm({ ...form, isPrivate: e.target.checked })}
                className="h-4 w-4 accent-green" />
              비공개 글 (작성자와 EXANSYS 직원만 열람)
            </label>
            {siteKey && <Turnstile siteKey={siteKey} onToken={setToken} />}
            <div className="flex items-center gap-3">
              <button type="submit" disabled={submitting}
                className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50">
                {submitting ? "등록 중…" : "등록"}
              </button>
              {msg && <span className="text-sm font-semibold text-red-600">{msg}</span>}
            </div>
          </div>
        </form>
      )}

      <div className="mt-8 overflow-hidden rounded-2xl border border-line bg-card">
        {list.length === 0 ? (
          <p className="p-8 text-center text-sm text-muted">아직 문의가 없습니다. 첫 문의를 남겨보세요!</p>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-paper text-left text-xs text-muted">
                <th className="px-5 py-3 font-semibold">제목</th>
                <th className="hidden px-4 py-3 font-semibold sm:table-cell">작성자</th>
                <th className="hidden px-4 py-3 font-semibold sm:table-cell">날짜</th>
                <th className="px-5 py-3 text-right font-semibold">상태</th>
              </tr>
            </thead>
            <tbody>
              {list.map((q) => (
                <tr key={q.id} className="border-b border-line last:border-0 hover:bg-paper/60">
                  <td className="px-5 py-3.5">
                    {q.isPrivate && !q.mine ? (
                      <span className="text-muted">🔒 {q.title}</span>
                    ) : (
                      <Link to={`/contact/${q.id}`} className="font-medium hover:text-green hover:underline">
                        {q.isPrivate && "🔒 "}
                        {q.title}
                      </Link>
                    )}
                  </td>
                  <td className="hidden px-4 py-3.5 text-muted sm:table-cell">{q.authorName}</td>
                  <td className="hidden px-4 py-3.5 text-muted sm:table-cell">{fmtDate(q.createdAt)}</td>
                  <td className="px-5 py-3.5 text-right">
                    {q.status === "answered" ? (
                      <span className="rounded-full bg-lime/25 px-2.5 py-1 text-xs font-semibold text-green-deep">답변완료</span>
                    ) : (
                      <span className="rounded-full bg-paper px-2.5 py-1 text-xs font-semibold text-muted">대기 중</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </main>
  );
}

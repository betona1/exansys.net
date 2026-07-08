import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api, type Me } from "../lib/api";

type Inquiry = {
  id: number;
  title: string;
  body: string;
  contact: string | null;
  isPrivate: boolean;
  status: "open" | "answered";
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  mine: boolean;
};
type Reply = {
  id: number;
  body: string;
  createdAt: string;
  authorName: string | null;
  authorRole: string | null;
};

function fmt(d: string) {
  return new Date(d).toLocaleString("ko-KR", {
    year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit",
  });
}

export default function ContactDetail({ me }: { me: Me }) {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [inquiry, setInquiry] = useState<Inquiry | null>(null);
  const [replies, setReplies] = useState<Reply[]>([]);
  const [error, setError] = useState("");
  const [replyBody, setReplyBody] = useState("");
  const isStaff = me && (me.role === "staff" || me.role === "admin");

  const load = useCallback(async () => {
    const res = await api<{ inquiry: Inquiry; replies: Reply[] }>(`/api/inquiries/${id}`);
    if (res.ok) {
      setInquiry(res.data.inquiry);
      setReplies(res.data.replies);
    } else {
      setError(res.error === "private_inquiry" ? "비공개 문의입니다." : "문의를 찾을 수 없습니다.");
    }
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  const submitReply = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await api(`/api/inquiries/${id}/replies`, {
      method: "POST",
      body: JSON.stringify({ body: replyBody }),
    });
    if (res.ok) {
      setReplyBody("");
      void load();
    }
  };

  const remove = async () => {
    if (!window.confirm("이 문의를 삭제할까요? 되돌릴 수 없습니다.")) return;
    const res = await api(`/api/inquiries/${id}`, { method: "DELETE" });
    if (res.ok) navigate("/contact");
  };

  if (error) {
    return (
      <main className="mx-auto max-w-4xl px-6 py-24 text-center">
        <p className="font-display text-2xl font-bold">{error}</p>
        <Link to="/contact" className="mt-4 inline-block font-semibold text-cobalt hover:underline">← 목록으로</Link>
      </main>
    );
  }
  if (!inquiry) {
    return <main className="mx-auto max-w-4xl px-6 py-24 text-center text-muted">불러오는 중…</main>;
  }

  return (
    <main className="mx-auto max-w-4xl px-6 py-14">
      <Link to="/contact" className="text-sm font-semibold text-muted hover:text-ink">← 목록으로</Link>

      <div className="mt-5 rounded-2xl border border-line bg-card p-7">
        <div className="flex flex-wrap items-center gap-3">
          <h1 className="font-display text-2xl font-extrabold">
            {inquiry.isPrivate && "🔒 "}
            {inquiry.title}
          </h1>
          {inquiry.status === "answered" ? (
            <span className="rounded-full bg-lime/25 px-3 py-1 text-xs font-semibold text-green-deep">답변완료</span>
          ) : (
            <span className="rounded-full bg-paper px-3 py-1 text-xs font-semibold text-muted">대기 중</span>
          )}
          {me?.role === "admin" && (
            <button onClick={() => void remove()} className="ml-auto text-xs font-semibold text-red-600 hover:underline">
              삭제
            </button>
          )}
        </div>
        <p className="mt-1.5 text-xs text-muted">
          {inquiry.authorName ?? "알 수 없음"} · {fmt(inquiry.createdAt)}
        </p>
        <p className="mt-5 whitespace-pre-line text-[15px] leading-relaxed">{inquiry.body}</p>
        {inquiry.contact && (
          <p className="mt-4 rounded-xl bg-paper px-4 py-3 text-sm">
            <span className="font-semibold">연락처</span> · {inquiry.contact}
          </p>
        )}
      </div>

      <h2 className="font-display mt-8 text-lg font-bold">답변 {replies.length}</h2>
      <div className="mt-3 space-y-3">
        {replies.map((r) => (
          <div key={r.id} className="rounded-2xl border border-lime/40 bg-lime/10 p-5">
            <p className="text-xs font-semibold">
              {r.authorName ?? "EXANSYS"}{" "}
              <span className="ml-1 rounded bg-ink px-1.5 py-0.5 text-[10px] font-bold text-lime">EXANSYS</span>
              <span className="ml-2 font-normal text-muted">{fmt(r.createdAt)}</span>
            </p>
            <p className="mt-2.5 whitespace-pre-line text-[15px] leading-relaxed">{r.body}</p>
          </div>
        ))}
        {replies.length === 0 && (
          <p className="rounded-2xl border border-dashed border-line p-5 text-sm text-muted">
            아직 답변이 없습니다. 보통 1~2일 내에 답변드립니다.
          </p>
        )}
      </div>

      {isStaff && (
        <form onSubmit={submitReply} className="mt-6 rounded-2xl border border-line bg-card p-5">
          <label className="mb-1.5 block text-xs font-semibold text-muted">답변 작성 (EXANSYS)</label>
          <textarea
            className="h-28 w-full rounded-xl border border-line bg-paper px-3.5 py-2.5 text-sm focus:border-green focus:outline-none"
            required value={replyBody} onChange={(e) => setReplyBody(e.target.value)}
          />
          <button type="submit"
            className="mt-3 rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep">
            답변 등록
          </button>
        </form>
      )}
    </main>
  );
}

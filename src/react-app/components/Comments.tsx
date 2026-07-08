// 앱별 문의 댓글 스레드 (CLAUDE.md 5-4절) — 대댓글 1단계, EXANSYS 뱃지
import { useCallback, useEffect, useState } from "react";
import { api, type Me } from "../lib/api";

type Comment = {
  id: number;
  parentId: number | null;
  body: string;
  deleted: boolean;
  createdAt: string;
  authorName: string;
  authorAvatar: string | null;
  isExansys: boolean;
  mine: boolean;
};

function fmt(d: string) {
  return new Date(d).toLocaleString("ko-KR", { month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" });
}

function CommentBody({ c, me, onReply, onDelete }: {
  c: Comment;
  me: Me;
  onReply?: () => void;
  onDelete: (id: number) => void;
}) {
  return (
    <div className="flex gap-3">
      {c.authorAvatar ? (
        <img src={c.authorAvatar} alt="" className="h-9 w-9 shrink-0 rounded-full" />
      ) : (
        <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-lime/30 text-sm font-bold">
          {c.deleted ? "×" : c.authorName.slice(0, 1)}
        </span>
      )}
      <div className="min-w-0 flex-1">
        <p className="text-xs font-semibold">
          {c.authorName}
          {c.isExansys && (
            <span className="ml-1.5 rounded bg-ink px-1.5 py-0.5 text-[10px] font-bold text-lime">EXANSYS</span>
          )}
          <span className="ml-2 font-normal text-muted">{fmt(c.createdAt)}</span>
        </p>
        <p className={`mt-1 whitespace-pre-line text-[14.5px] leading-relaxed ${c.deleted ? "italic text-muted" : ""}`}>
          {c.body}
        </p>
        <div className="mt-1.5 flex gap-3 text-xs font-semibold text-muted">
          {onReply && me && !c.deleted && (
            <button onClick={onReply} className="hover:text-ink">답글</button>
          )}
          {!c.deleted && me && (c.mine || me.role === "admin") && (
            <button onClick={() => onDelete(c.id)} className="text-red-500 hover:underline">삭제</button>
          )}
        </div>
      </div>
    </div>
  );
}

export default function Comments({ slug, me }: { slug: string; me: Me }) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [body, setBody] = useState("");
  const [replyTo, setReplyTo] = useState<number | null>(null);
  const [replyBody, setReplyBody] = useState("");

  const load = useCallback(async () => {
    const res = await api<{ comments: Comment[] }>(`/api/apps/${slug}/comments`);
    if (res.ok) setComments(res.data.comments);
  }, [slug]);

  useEffect(() => {
    void load();
  }, [load]);

  const post = async (text: string, parentId: number | null) => {
    const res = await api(`/api/apps/${slug}/comments`, {
      method: "POST",
      body: JSON.stringify({ body: text, parentId }),
    });
    if (res.ok) {
      setBody("");
      setReplyBody("");
      setReplyTo(null);
      void load();
    }
  };

  const remove = async (id: number) => {
    if (!window.confirm("댓글을 삭제할까요?")) return;
    const res = await api(`/api/comments/${id}`, { method: "DELETE" });
    if (res.ok) void load();
  };

  const roots = comments.filter((c) => c.parentId === null);
  const childrenOf = (id: number) => comments.filter((c) => c.parentId === id);

  const box =
    "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";

  return (
    <div className="mt-10 rounded-2xl border border-line bg-card p-7">
      <h3 className="font-display mb-5 text-lg font-bold">앱 문의 · 댓글 {comments.filter((c) => !c.deleted).length}</h3>

      {me ? (
        <form
          onSubmit={(e) => { e.preventDefault(); if (body.trim()) void post(body, null); }}
          className="mb-7"
        >
          <textarea className={`${box} h-20`} value={body} maxLength={2000}
            placeholder="이 앱에 대해 궁금한 점을 남겨주세요."
            onChange={(e) => setBody(e.target.value)} />
          <button type="submit"
            className="mt-2 rounded-full bg-green px-5 py-2 text-sm font-semibold text-white transition hover:bg-green-deep">
            댓글 등록
          </button>
        </form>
      ) : (
        <p className="mb-7 rounded-xl bg-paper px-4 py-3 text-sm text-muted">
          댓글을 작성하려면 우측 상단에서 로그인해 주세요.
        </p>
      )}

      <div className="space-y-6">
        {roots.length === 0 && <p className="text-sm text-muted">아직 댓글이 없습니다.</p>}
        {roots.map((c) => (
          <div key={c.id}>
            <CommentBody c={c} me={me} onDelete={(id) => void remove(id)}
              onReply={() => { setReplyTo(replyTo === c.id ? null : c.id); setReplyBody(""); }} />
            <div className="ml-12 mt-4 space-y-4 border-l-2 border-line pl-4">
              {childrenOf(c.id).map((child) => (
                <CommentBody key={child.id} c={child} me={me} onDelete={(id) => void remove(id)} />
              ))}
              {replyTo === c.id && me && (
                <form onSubmit={(e) => { e.preventDefault(); if (replyBody.trim()) void post(replyBody, c.id); }}>
                  <textarea className={`${box} h-16`} value={replyBody} maxLength={2000} autoFocus
                    placeholder={`${c.authorName}님에게 답글`}
                    onChange={(e) => setReplyBody(e.target.value)} />
                  <div className="mt-2 flex gap-2">
                    <button type="submit"
                      className="rounded-full bg-ink px-4 py-1.5 text-xs font-semibold text-white transition hover:bg-green">
                      답글 등록
                    </button>
                    <button type="button" onClick={() => setReplyTo(null)}
                      className="text-xs font-semibold text-muted hover:text-ink">
                      취소
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

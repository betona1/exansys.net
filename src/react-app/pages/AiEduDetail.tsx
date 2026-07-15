// AI교육 자료 상세 — 본문 + 첨부(다이나믹 HTML 샌드박스/이미지/PDF/링크) + 댓글
import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { marked } from "marked";
import DOMPurify from "dompurify";
import { api, type Me, type EduPostDetail, type EduAttachment } from "../lib/api";

function fmt(s: string) {
  return new Date(s).toLocaleString("ko-KR", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function AiEduDetail({ me }: { me: Me }) {
  const { id } = useParams<{ id: string }>();
  const nav = useNavigate();
  const [data, setData] = useState<EduPostDetail | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [comment, setComment] = useState("");
  const [posting, setPosting] = useState(false);

  const load = useCallback(async () => {
    const res = await api<EduPostDetail>(`/api/edu/posts/${id}`);
    if (res.ok) setData(res.data);
    else setNotFound(true);
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  async function submitComment() {
    if (comment.trim().length === 0) return;
    setPosting(true);
    const res = await api(`/api/edu/posts/${id}/comments`, {
      method: "POST",
      body: JSON.stringify({ body: comment.trim() }),
    });
    setPosting(false);
    if (res.ok) {
      setComment("");
      void load();
    }
  }

  async function deleteComment(cid: number) {
    const res = await api(`/api/edu/comments/${cid}`, { method: "DELETE" });
    if (res.ok) void load();
  }

  async function deletePost() {
    if (!confirm("이 자료를 삭제할까요? 첨부 파일도 함께 삭제됩니다.")) return;
    const res = await api(`/api/edu/posts/${id}`, { method: "DELETE" });
    if (res.ok) nav("/ai-edu");
  }

  if (notFound) {
    return (
      <main className="mx-auto max-w-2xl px-6 py-24 text-center">
        <p className="text-muted">자료를 찾을 수 없습니다.</p>
        <Link to="/ai-edu" className="mt-4 inline-block font-semibold text-green hover:underline">
          ← 목록으로
        </Link>
      </main>
    );
  }
  if (!data) return <main className="mx-auto max-w-4xl px-6 py-24 text-center text-muted">불러오는 중…</main>;

  const { post, attachments, comments, canComment, canManage } = data;
  const bodyHtml = post.body ? DOMPurify.sanitize(marked.parse(post.body) as string) : "";

  return (
    <main className="mx-auto max-w-4xl px-6 py-10">
      <Link to="/ai-edu" className="text-sm text-muted hover:text-ink">
        ← 교육 자료실
      </Link>

      <header className="mb-6 mt-3 flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">{post.title}</h1>
          <div className="mt-2 flex items-center gap-2 text-sm text-muted">
            {post.authorAvatar && <img src={post.authorAvatar} alt="" className="h-6 w-6 rounded-full" />}
            <span>{post.authorName ?? "EXANSYS"}</span>
            <span>· {fmt(post.createdAt)}</span>
          </div>
        </div>
        {canManage && (
          <button
            onClick={deletePost}
            className="rounded-full border border-red-200 px-4 py-1.5 text-sm font-semibold text-red-600 hover:bg-red-50"
          >
            삭제
          </button>
        )}
      </header>

      {bodyHtml && (
        <article
          className="prose prose-neutral mb-8 max-w-none dark:prose-invert"
          dangerouslySetInnerHTML={{ __html: bodyHtml }}
        />
      )}

      {/* 첨부 */}
      <div className="space-y-6">
        {attachments.map((a) => (
          <Attachment key={a.id} att={a} />
        ))}
      </div>

      {/* 댓글 */}
      <section className="mt-12">
        <h2 className="mb-4 text-lg font-bold">댓글 {comments.length}</h2>
        {canComment ? (
          <div className="mb-6 flex gap-2">
            <input
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && submitComment()}
              placeholder="댓글을 남겨보세요"
              className="flex-1 rounded-full border border-line bg-card px-5 py-2.5 text-sm outline-none focus:border-ink"
            />
            <button
              onClick={submitComment}
              disabled={posting}
              className="rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-green disabled:opacity-50"
            >
              등록
            </button>
          </div>
        ) : (
          <p className="mb-6 rounded-xl border border-line bg-card px-4 py-3 text-sm text-muted">
            댓글을 남기려면{" "}
            <Link to="/login" className="font-semibold text-cobalt hover:underline">
              로그인
            </Link>
            이 필요합니다.
          </p>
        )}
        <ul className="space-y-3">
          {comments.map((cm) => (
            <li key={cm.id} className="flex items-start gap-3 rounded-xl bg-card p-3">
              {cm.authorAvatar ? (
                <img src={cm.authorAvatar} alt="" className="h-8 w-8 rounded-full" />
              ) : (
                <span className="grid h-8 w-8 place-items-center rounded-full bg-lime/40 text-xs font-bold">
                  {(cm.authorName ?? "?").slice(0, 1)}
                </span>
              )}
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 text-xs text-muted">
                  <span className="font-semibold text-ink">{cm.authorName ?? "익명"}</span>
                  <span>{fmt(cm.createdAt)}</span>
                  {cm.mine && (
                    <button onClick={() => deleteComment(cm.id)} className="ml-auto text-red-500 hover:underline">
                      삭제
                    </button>
                  )}
                </div>
                <p className="mt-1 whitespace-pre-wrap break-words text-sm text-ink">{cm.body}</p>
              </div>
            </li>
          ))}
          {comments.length === 0 && <li className="py-6 text-center text-sm text-muted">첫 댓글을 남겨보세요.</li>}
        </ul>
      </section>
    </main>
  );
}

// ── 첨부 렌더 ──
function Attachment({ att }: { att: EduAttachment }) {
  const [expanded, setExpanded] = useState(false);
  if (!att.src) return null;

  if (att.kind === "html") {
    return (
      <div className="overflow-hidden rounded-2xl border border-line bg-card">
        <div className="flex items-center justify-between border-b border-line px-4 py-2.5">
          <span className="truncate text-sm font-semibold">🖥️ {att.name}</span>
          <div className="flex shrink-0 items-center gap-2 text-xs">
            <button onClick={() => setExpanded((v) => !v)} className="font-semibold text-muted hover:text-ink">
              {expanded ? "축소" : "크게 보기"}
            </button>
            <a href={att.src} target="_blank" rel="noreferrer" className="font-semibold text-green hover:underline">
              새 탭 ↗
            </a>
          </div>
        </div>
        {/* 샌드박스: allow-same-origin 없음 → 세션 쿠키 접근·API 호출 차단 */}
        <iframe
          src={att.src}
          title={att.name}
          sandbox="allow-scripts allow-popups allow-popups-to-escape-sandbox allow-forms allow-modals"
          className="w-full bg-white"
          style={{ height: expanded ? "80vh" : "540px" }}
          loading="lazy"
        />
      </div>
    );
  }

  if (att.kind === "image") {
    return (
      <a href={att.src} target="_blank" rel="noreferrer" className="block overflow-hidden rounded-2xl border border-line">
        <img src={att.src} alt={att.name} className="w-full" loading="lazy" />
      </a>
    );
  }

  if (att.kind === "pdf") {
    return (
      <div className="overflow-hidden rounded-2xl border border-line bg-card">
        <div className="flex items-center justify-between border-b border-line px-4 py-2.5">
          <span className="truncate text-sm font-semibold">📄 {att.name}</span>
          <a href={att.src} target="_blank" rel="noreferrer" className="shrink-0 text-xs font-semibold text-green hover:underline">
            새 탭에서 열기 ↗
          </a>
        </div>
        <iframe src={att.src} title={att.name} className="h-[600px] w-full" loading="lazy" />
      </div>
    );
  }

  // link
  return (
    <a
      href={att.src}
      target="_blank"
      rel="noreferrer"
      className="flex items-center gap-3 rounded-2xl border border-line bg-card p-4 transition hover:border-ink"
    >
      <span className="text-2xl">🔗</span>
      <span className="min-w-0 flex-1">
        <span className="block truncate font-semibold text-ink">{att.name}</span>
        <span className="block truncate text-xs text-muted">{att.src}</span>
      </span>
      <span className="shrink-0 text-sm text-green">열기 ↗</span>
    </a>
  );
}

import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api, type Me } from "../lib/api";

type Post = {
  id: number;
  title: string;
  body: string | null;
  linkUrl: string | null;
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  mine: boolean;
};
type Img = { id: number; imageUrl: string };
type Comment = {
  id: number;
  body: string;
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  mine: boolean;
};

function fmt(d: string) {
  return new Date(d).toLocaleString("ko-KR", {
    year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit",
  });
}

export default function CrewDetail({ me }: { me: Me }) {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [post, setPost] = useState<Post | null>(null);
  const [images, setImages] = useState<Img[]>([]);
  const [comments, setComments] = useState<Comment[]>([]);
  const [error, setError] = useState("");
  const [body, setBody] = useState("");

  const load = useCallback(async () => {
    const res = await api<{ post: Post; images: Img[]; comments: Comment[] }>(`/api/crew/posts/${id}`);
    if (res.ok) {
      setPost(res.data.post);
      setImages(res.data.images);
      setComments(res.data.comments);
    } else {
      setError(res.error === "forbidden" || res.error === "unauthorized" ? "크루 전용 게시글입니다." : "게시글을 찾을 수 없습니다.");
    }
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  const comment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!body.trim()) return;
    const res = await api(`/api/crew/posts/${id}/comments`, {
      method: "POST",
      body: JSON.stringify({ body }),
    });
    if (res.ok) {
      setBody("");
      void load();
    }
  };

  const removePost = async () => {
    if (!window.confirm("게시글을 삭제할까요? 이미지도 함께 삭제됩니다.")) return;
    const res = await api(`/api/crew/posts/${id}`, { method: "DELETE" });
    if (res.ok) navigate("/crew");
  };

  const removeComment = async (cid: number) => {
    if (!window.confirm("댓글을 삭제할까요?")) return;
    const res = await api(`/api/crew/comments/${cid}`, { method: "DELETE" });
    if (res.ok) void load();
  };

  if (error) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-24 text-center">
        <p className="font-display text-2xl font-bold">{error}</p>
        <Link to="/crew" className="mt-4 inline-block font-semibold text-cobalt hover:underline">← 갤러리로</Link>
      </main>
    );
  }
  if (!post) {
    return <main className="mx-auto max-w-3xl px-6 py-24 text-center text-muted">불러오는 중…</main>;
  }

  return (
    <main className="mx-auto max-w-3xl px-6 py-14">
      <Link to="/crew" className="text-sm font-semibold text-muted hover:text-ink">← 갤러리로</Link>

      <div className="mt-5 rounded-2xl border border-line bg-card p-7">
        <div className="flex items-start justify-between gap-3">
          <h1 className="font-display text-2xl font-extrabold">{post.title}</h1>
          {(post.mine || me?.role === "admin") && (
            <button onClick={() => void removePost()} className="shrink-0 text-xs font-semibold text-red-600 hover:underline">
              삭제
            </button>
          )}
        </div>
        <p className="mt-1.5 flex items-center gap-2 text-xs text-muted">
          {post.authorAvatar && <img src={post.authorAvatar} alt="" className="h-5 w-5 rounded-full" />}
          {post.authorName ?? "알 수 없음"} · {fmt(post.createdAt)}
        </p>

        {images.length > 0 && (
          <div className="mt-5 space-y-3">
            {images.map((img) => (
              <img key={img.id} src={img.imageUrl} alt="" className="w-full rounded-xl border border-line" />
            ))}
          </div>
        )}

        {post.body && <p className="mt-5 whitespace-pre-line text-[15px] leading-relaxed">{post.body}</p>}

        {post.linkUrl && (
          <a href={post.linkUrl} target="_blank" rel="noopener noreferrer"
            className="mt-5 inline-block rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green">
            🔗 앱 보러가기
          </a>
        )}
      </div>

      <h2 className="font-display mt-8 text-lg font-bold">댓글 {comments.length}</h2>
      {me && (me.role === "crew" || me.role === "staff" || me.role === "admin") ? (
        <form onSubmit={comment} className="mt-3">
          <textarea
            className="h-20 w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none"
            maxLength={1000} value={body} placeholder="응원과 피드백을 남겨주세요."
            onChange={(e) => setBody(e.target.value)}
          />
          <button type="submit"
            className="mt-2 rounded-full bg-green px-5 py-2 text-sm font-semibold text-white transition hover:bg-green-deep">
            댓글 등록
          </button>
        </form>
      ) : (
        <p className="mt-3 rounded-xl border border-line bg-card px-4 py-3 text-sm text-muted">
          댓글 작성은 크루 멤버만 가능합니다. 누구나 갤러리와 댓글은 볼 수 있어요.
        </p>
      )}

      <div className="mt-6 space-y-5">
        {comments.map((cm) => (
          <div key={cm.id} className="flex gap-3">
            {cm.authorAvatar ? (
              <img src={cm.authorAvatar} alt="" className="h-9 w-9 shrink-0 rounded-full" />
            ) : (
              <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-lime/30 text-sm font-bold">
                {(cm.authorName ?? "?").slice(0, 1)}
              </span>
            )}
            <div className="min-w-0 flex-1">
              <p className="text-xs font-semibold">
                {cm.authorName ?? "알 수 없음"}
                <span className="ml-2 font-normal text-muted">{fmt(cm.createdAt)}</span>
              </p>
              <p className="mt-1 whitespace-pre-line text-[14.5px] leading-relaxed">{cm.body}</p>
              {(cm.mine || me?.role === "admin") && (
                <button onClick={() => void removeComment(cm.id)}
                  className="mt-1 text-xs font-semibold text-red-500 hover:underline">
                  삭제
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </main>
  );
}

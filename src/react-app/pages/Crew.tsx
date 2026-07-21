// 크루 내부 갤러리 (CLAUDE.md 5-6절) — crew 이상 전용, 카드형 갤러리
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, type Me } from "../lib/api";
import { toWebp } from "../lib/image";

type PostCard = {
  id: number;
  title: string;
  body: string | null;
  linkUrl: string | null;
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  thumbnail: string | null;
  commentCount: number;
};

type Comment = {
  id: number;
  body: string;
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  mine?: boolean;
};

type Resource = {
  slug: string;
  title: string;
  description: string;
  emoji: string;
};

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

function isCrew(me: Me) {
  return Boolean(me && (me.role === "crew" || me.role === "staff" || me.role === "admin"));
}

function fmtDate(s: string) {
  const d = new Date(s);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, "0")}.${String(d.getDate()).padStart(2, "0")}`;
}

export default function Crew({ me, meLoading }: { me: Me; meLoading: boolean }) {
  const [posts, setPosts] = useState<PostCard[]>([]);
  const [resources, setResources] = useState<Resource[]>([]);
  const [writing, setWriting] = useState(false);
  const [form, setForm] = useState({ title: "", body: "", linkUrl: "" });
  const [files, setFiles] = useState<File[]>([]);
  const [msg, setMsg] = useState("");
  const [submitting, setSubmitting] = useState(false);
  // 목록 인라인 댓글
  const [openId, setOpenId] = useState<number | null>(null);
  const [commentsBy, setCommentsBy] = useState<Record<number, Comment[]>>({});
  const [draft, setDraft] = useState<Record<number, string>>({});
  const [posting, setPosting] = useState(false);

  const load = useCallback(async () => {
    // 갤러리 목록은 공개 열람
    const postsRes = await api<{ posts: PostCard[] }>("/api/crew/posts");
    if (postsRes.ok) setPosts(postsRes.data.posts);
    // 자료실은 크루 전용
    if (isCrew(me)) {
      const resourcesRes = await api<{ resources: Resource[] }>("/api/crew/resources");
      if (resourcesRes.ok) setResources(resourcesRes.data.resources);
    } else {
      setResources([]);
    }
  }, [me]);

  useEffect(() => {
    void load();
  }, [load]);

  if (meLoading) {
    return <main className="mx-auto max-w-6xl px-6 py-24 text-center text-muted">확인 중…</main>;
  }

  const crew = isCrew(me);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setMsg("");
    try {
      // 이미지 webp 변환 → 업로드 → 키 수집
      const imageKeys: string[] = [];
      for (const file of files.slice(0, 5)) {
        const webp = await toWebp(file);
        if (webp.size > MAX_IMAGE_BYTES) throw new Error("변환 후에도 5MB를 초과하는 이미지가 있습니다.");
        const res = await fetch("/api/crew/upload", {
          method: "POST",
          credentials: "same-origin",
          headers: { "Content-Type": "image/webp" },
          body: webp,
        });
        const json = (await res.json()) as { ok: boolean; data?: { key: string }; error?: string };
        if (!json.ok || !json.data) throw new Error(`업로드 실패: ${json.error ?? "unknown"}`);
        imageKeys.push(json.data.key);
      }

      const created = await api<{ id: number }>("/api/crew/posts", {
        method: "POST",
        body: JSON.stringify({ ...form, linkUrl: form.linkUrl || null, body: form.body || null, imageKeys }),
      });
      if (!created.ok) throw new Error(`등록 실패: ${created.error}`);

      setWriting(false);
      setForm({ title: "", body: "", linkUrl: "" });
      setFiles([]);
      void load();
    } catch (e) {
      setMsg(e instanceof Error ? e.message : "오류가 발생했습니다.");
    } finally {
      setSubmitting(false);
    }
  };

  const toggleComments = async (id: number) => {
    if (openId === id) {
      setOpenId(null);
      return;
    }
    setOpenId(id);
    if (!commentsBy[id]) {
      const res = await api<{ comments: Comment[] }>(`/api/crew/posts/${id}`);
      if (res.ok) setCommentsBy((m) => ({ ...m, [id]: res.data.comments }));
    }
  };

  const submitComment = async (id: number) => {
    const text = (draft[id] ?? "").trim();
    if (!text || posting) return;
    setPosting(true);
    const res = await api(`/api/crew/posts/${id}/comments`, { method: "POST", body: JSON.stringify({ body: text }) });
    setPosting(false);
    if (res.ok) {
      setDraft((m) => ({ ...m, [id]: "" }));
      const detail = await api<{ comments: Comment[] }>(`/api/crew/posts/${id}`);
      if (detail.ok) {
        setCommentsBy((m) => ({ ...m, [id]: detail.data.comments }));
        setPosts((ps) => ps.map((p) => (p.id === id ? { ...p, commentCount: detail.data.comments.length } : p)));
      }
    }
  };

  const input =
    "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";

  return (
    <main className="mx-auto max-w-6xl px-6 py-14">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">CREW</p>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">크루 라운지</h1>
          <p className="mt-2 text-muted">크루가 만든 앱을 구경하고, 서로 피드백을 나누는 공간이에요.</p>
        </div>
        {crew && (
          <button
            onClick={() => setWriting(!writing)}
            className="rounded-full bg-green px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep"
          >
            {writing ? "닫기" : "내 앱 올리기"}
          </button>
        )}
      </div>

      {!crew && (
        <div className="mt-6 rounded-2xl border border-line bg-card p-5 text-sm text-muted">
          누구나 크루 갤러리를 구경할 수 있어요. 직접 앱을 올리고 자료실을 이용하려면{" "}
          <Link to="/contact" className="font-semibold text-cobalt hover:underline">개발 문의 게시판</Link>
          에서 크루 참여를 신청해 주세요 (운영진 승인 후 크루 권한 부여).
        </div>
      )}

      {crew && writing && (
        <form onSubmit={submit} className="mt-8 rounded-2xl border border-line bg-card p-6">
          <div className="grid gap-4">
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">제목</label>
              <input className={input} required minLength={2} maxLength={80} value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="내 앱 이름 또는 소개 제목" />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">설명 (선택)</label>
              <textarea className={`${input} h-28`} maxLength={2000} value={form.body}
                onChange={(e) => setForm({ ...form, body: e.target.value })}
                placeholder="어떤 앱인지, 어떤 피드백이 필요한지 알려주세요." />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">링크 (선택)</label>
              <input className={input} type="url" maxLength={500} value={form.linkUrl}
                onChange={(e) => setForm({ ...form, linkUrl: e.target.value })}
                placeholder="https:// 스토어 또는 웹사이트 링크" />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-muted">
                이미지 (최대 5장 · 장당 5MB · 자동으로 webp 변환됩니다)
              </label>
              <input type="file" accept="image/*" multiple
                onChange={(e) => setFiles([...(e.target.files ?? [])].slice(0, 5))}
                className="block w-full text-sm text-muted file:mr-3 file:rounded-full file:border-0 file:bg-lime/25 file:px-4 file:py-2 file:text-sm file:font-semibold file:text-green-deep" />
              {files.length > 0 && (
                <p className="mt-1.5 text-xs text-muted">{files.map((f) => f.name).join(", ")}</p>
              )}
            </div>
            <div className="flex items-center gap-3">
              <button type="submit" disabled={submitting}
                className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50">
                {submitting ? "업로드 중…" : "게시"}
              </button>
              {msg && <span className="text-sm font-semibold text-red-600">{msg}</span>}
            </div>
          </div>
        </form>
      )}

      {resources.length > 0 && (
        <section className="mt-12">
          <div className="mb-4 flex items-baseline gap-3">
            <h2 className="font-display text-xl font-bold tracking-tight">자료실</h2>
            <span className="text-sm text-muted">크루가 함께 보는 학습 자료</span>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {resources.map((r) => (
              <a
                key={r.slug}
                href={`/api/crew/resources/${r.slug}`}
                target="_blank"
                rel="noopener noreferrer"
                className="group flex gap-4 rounded-2xl border border-line bg-card p-5 transition hover:-translate-y-1 hover:border-green/50 hover:shadow-xl hover:shadow-ink/8"
              >
                <span className="grid h-12 w-12 flex-none place-items-center rounded-xl bg-lime/25 text-2xl">
                  {r.emoji}
                </span>
                <div className="min-w-0">
                  <h3 className="font-display font-bold leading-snug transition group-hover:text-green-deep">
                    {r.title}
                  </h3>
                  <p className="mt-1 line-clamp-2 text-xs text-muted">{r.description}</p>
                  <span className="mt-2 inline-block text-xs font-semibold text-green">새 탭으로 열기 ↗</span>
                </div>
              </a>
            ))}
          </div>
        </section>
      )}

      <section className="mt-12">
        <div className="mb-5 flex items-baseline gap-3">
          <h2 className="font-display text-2xl font-extrabold tracking-tight">크루 갤러리</h2>
          <span className="text-sm text-muted">서로의 앱을 자랑하고, 피드백을 나눠요</span>
        </div>

        {posts.length === 0 && (
          <p className="rounded-2xl border border-dashed border-line p-10 text-center text-sm text-muted">
            아직 게시글이 없습니다. {crew ? "첫 번째로 앱을 자랑해 보세요!" : "곧 크루들의 앱이 올라올 거예요."}
          </p>
        )}

        <div className="mx-auto flex max-w-2xl flex-col gap-6">
          {posts.map((p) => {
            const cmts = commentsBy[p.id] ?? [];
            const open = openId === p.id;
            return (
              <article key={p.id} className="overflow-hidden rounded-3xl border border-line bg-card shadow-sm transition hover:shadow-md">
                {/* 작성자 */}
                <div className="flex items-center gap-3 px-5 pt-5">
                  {p.authorAvatar ? (
                    <img src={p.authorAvatar} alt="" className="h-9 w-9 rounded-full" />
                  ) : (
                    <span className="grid h-9 w-9 place-items-center rounded-full bg-lime/30 text-sm font-bold">
                      {(p.authorName ?? "?").slice(0, 1)}
                    </span>
                  )}
                  <div className="min-w-0">
                    <p className="truncate text-sm font-semibold">{p.authorName ?? "알 수 없음"}</p>
                    <p className="text-xs text-muted">{fmtDate(p.createdAt)}</p>
                  </div>
                </div>

                {/* 제목 + 본문 */}
                <div className="px-5 pt-3">
                  <h3 className="font-display text-lg font-bold">{p.title}</h3>
                  {p.body && (
                    <p className="mt-1.5 line-clamp-4 whitespace-pre-line text-[15px] leading-relaxed text-ink/90">{p.body}</p>
                  )}
                </div>

                {/* 이미지 */}
                {p.thumbnail && (
                  <Link to={`/crew/${p.id}`} className="mt-4 block bg-paper">
                    <img src={p.thumbnail} alt="" className="max-h-[440px] w-full object-cover" />
                  </Link>
                )}

                {/* 링크 */}
                {p.linkUrl && (
                  <div className="px-5 pt-4">
                    <a href={p.linkUrl} target="_blank" rel="noopener noreferrer"
                      className="inline-block rounded-full bg-ink px-4 py-2 text-sm font-semibold text-white transition hover:bg-green">
                      🔗 앱 보러가기
                    </a>
                  </div>
                )}

                {/* 액션 바 */}
                <div className="mt-4 flex items-center gap-4 border-t border-line px-5 py-3 text-sm">
                  <button onClick={() => void toggleComments(p.id)} className="font-semibold text-muted transition hover:text-green">
                    💬 댓글 {p.commentCount}{open ? " · 접기" : " · 보기"}
                  </button>
                  <Link to={`/crew/${p.id}`} className="ml-auto text-xs font-semibold text-cobalt hover:underline">
                    자세히 →
                  </Link>
                </div>

                {/* 인라인 댓글 */}
                {open && (
                  <div className="border-t border-line bg-paper/50 px-5 py-4">
                    {crew && (
                      <div className="mb-4 flex gap-2">
                        <input
                          value={draft[p.id] ?? ""}
                          onChange={(e) => setDraft((m) => ({ ...m, [p.id]: e.target.value }))}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") void submitComment(p.id);
                          }}
                          maxLength={1000}
                          placeholder="한 줄 댓글 달기…"
                          className="flex-1 rounded-full border border-line bg-card px-4 py-2 text-sm focus:border-green focus:outline-none"
                        />
                        <button onClick={() => void submitComment(p.id)} disabled={posting}
                          className="rounded-full bg-green px-4 py-2 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50">
                          등록
                        </button>
                      </div>
                    )}
                    {cmts.length === 0 ? (
                      <p className="text-sm text-muted">아직 댓글이 없어요.{crew ? " 첫 댓글을 남겨보세요!" : ""}</p>
                    ) : (
                      <div className="space-y-3">
                        {cmts.map((cm) => (
                          <div key={cm.id} className="flex gap-2.5">
                            {cm.authorAvatar ? (
                              <img src={cm.authorAvatar} alt="" className="h-7 w-7 shrink-0 rounded-full" />
                            ) : (
                              <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-lime/30 text-xs font-bold">
                                {(cm.authorName ?? "?").slice(0, 1)}
                              </span>
                            )}
                            <div className="min-w-0">
                              <p className="text-xs font-semibold">
                                {cm.authorName ?? "알 수 없음"}
                                <span className="ml-1 font-normal text-muted">{fmtDate(cm.createdAt)}</span>
                              </p>
                              <p className="mt-0.5 whitespace-pre-line text-sm leading-relaxed">{cm.body}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </article>
            );
          })}
        </div>
      </section>
    </main>
  );
}

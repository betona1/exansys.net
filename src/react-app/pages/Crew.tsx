// 크루 내부 갤러리 (CLAUDE.md 5-6절) — crew 이상 전용, 카드형 갤러리
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, type Me } from "../lib/api";
import { toWebp } from "../lib/image";

type PostCard = {
  id: number;
  title: string;
  linkUrl: string | null;
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  thumbnail: string | null;
  commentCount: number;
};

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

function isCrew(me: Me) {
  return Boolean(me && (me.role === "crew" || me.role === "staff" || me.role === "admin"));
}

export default function Crew({ me, meLoading }: { me: Me; meLoading: boolean }) {
  const [posts, setPosts] = useState<PostCard[]>([]);
  const [writing, setWriting] = useState(false);
  const [form, setForm] = useState({ title: "", body: "", linkUrl: "" });
  const [files, setFiles] = useState<File[]>([]);
  const [msg, setMsg] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    const res = await api<{ posts: PostCard[] }>("/api/crew/posts");
    if (res.ok) setPosts(res.data.posts);
  }, []);

  useEffect(() => {
    if (isCrew(me)) void load();
  }, [me, load]);

  if (meLoading) {
    return <main className="mx-auto max-w-6xl px-6 py-24 text-center text-muted">확인 중…</main>;
  }

  // 비로그인·member는 안내 페이지 (5-6절)
  if (!isCrew(me)) {
    return (
      <main className="mx-auto max-w-2xl px-6 py-24 text-center">
        <div className="mb-6 text-5xl">🐍</div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">크루 전용 공간입니다</h1>
        <p className="mx-auto mt-4 max-w-md text-muted">
          이곳은 EXANSYS와 함께하는 앱개발자 모임 <b>크루</b>의 내부 갤러리입니다.
          크루 멤버들이 서로의 앱을 공유하고 피드백을 나눕니다.
        </p>
        <div className="mt-8 rounded-2xl border border-line bg-card p-6 text-left text-sm text-muted">
          <p className="font-semibold text-ink">크루에 참여하려면</p>
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

  const input =
    "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";

  return (
    <main className="mx-auto max-w-6xl px-6 py-14">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 text-[13px] font-semibold uppercase tracking-[0.18em] text-green">CREW</p>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">크루 갤러리</h1>
          <p className="mt-2 text-muted">서로의 앱을 자랑하고, 피드백을 나눠요.</p>
        </div>
        <button
          onClick={() => setWriting(!writing)}
          className="rounded-full bg-green px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep"
        >
          {writing ? "닫기" : "내 앱 올리기"}
        </button>
      </div>

      {writing && (
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

      <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.length === 0 && (
          <p className="col-span-full rounded-2xl border border-dashed border-line p-10 text-center text-sm text-muted">
            아직 게시글이 없습니다. 첫 번째로 앱을 자랑해 보세요!
          </p>
        )}
        {posts.map((p) => (
          <Link key={p.id} to={`/crew/${p.id}`}
            className="group overflow-hidden rounded-2xl border border-line bg-card transition hover:-translate-y-1 hover:shadow-xl hover:shadow-ink/8">
            <div className="grid h-44 place-items-center overflow-hidden bg-paper">
              {p.thumbnail ? (
                <img src={p.thumbnail} alt="" className="h-full w-full object-cover transition group-hover:scale-105" />
              ) : (
                <span className="text-4xl">📱</span>
              )}
            </div>
            <div className="p-5">
              <h3 className="font-display truncate text-lg font-bold">{p.title}</h3>
              <p className="mt-1.5 flex items-center gap-2 text-xs text-muted">
                {p.authorAvatar && <img src={p.authorAvatar} alt="" className="h-5 w-5 rounded-full" />}
                {p.authorName ?? "알 수 없음"} · 💬 {p.commentCount}
              </p>
            </div>
          </Link>
        ))}
      </div>
    </main>
  );
}

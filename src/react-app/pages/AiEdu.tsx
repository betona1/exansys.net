// AI교육 게시판 — 교육 자료 목록 (열람 공개, 작성/업로드는 admin 전용)
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, type Me, type EduPostCard, type EduKind } from "../lib/api";
import { toWebp } from "../lib/image";

const KIND_BADGE: Record<EduKind, { label: string; emoji: string }> = {
  html: { label: "인터랙티브", emoji: "🖥️" },
  image: { label: "이미지", emoji: "🖼️" },
  pdf: { label: "PDF", emoji: "📄" },
  link: { label: "링크", emoji: "🔗" },
};

function fmtDate(s: string) {
  const d = new Date(s);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, "0")}.${String(d.getDate()).padStart(2, "0")}`;
}

type PendingAtt = { kind: EduKind; key?: string; url?: string; name: string; size?: number };

export default function AiEdu({ me }: { me: Me }) {
  const [posts, setPosts] = useState<EduPostCard[]>([]);
  const [loading, setLoading] = useState(true);
  const [writing, setWriting] = useState(false);
  const isAdmin = Boolean(me && me.role === "admin");

  const load = useCallback(async () => {
    const res = await api<{ posts: EduPostCard[] }>("/api/edu/posts");
    if (res.ok) setPosts(res.data.posts);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <header className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">AI 교육 자료실</h1>
          <p className="mt-2 text-muted">
            AI·앱 개발 학습 자료를 모아둔 공간입니다. 인터랙티브 HTML 자료, 문서, 이미지, 링크를 확인하세요.
          </p>
        </div>
        {isAdmin && (
          <button
            onClick={() => setWriting((v) => !v)}
            className="rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-green"
          >
            {writing ? "닫기" : "＋ 새 자료 올리기"}
          </button>
        )}
      </header>

      {isAdmin && writing && (
        <EduWriteForm
          onDone={() => {
            setWriting(false);
            void load();
          }}
        />
      )}

      {loading ? (
        <p className="py-24 text-center text-muted">불러오는 중…</p>
      ) : posts.length === 0 ? (
        <div className="rounded-2xl border border-line bg-card p-16 text-center text-muted">
          <div className="mb-3 text-4xl">📚</div>
          아직 등록된 교육 자료가 없습니다.
        </div>
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {posts.map((p) => (
            <li key={p.id}>
              <Link
                to={`/ai-edu/${p.id}`}
                className="flex h-full flex-col overflow-hidden rounded-2xl border border-line bg-card transition hover:border-ink hover:shadow-lg hover:shadow-ink/5"
              >
                <div className="grid h-40 place-items-center overflow-hidden bg-gradient-to-br from-paper to-lime/15">
                  {p.thumbnail ? (
                    <img src={p.thumbnail} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <span className="text-5xl">{p.kinds.includes("html") ? "🖥️" : "📚"}</span>
                  )}
                </div>
                <div className="flex flex-1 flex-col p-4">
                  <div className="mb-2 flex flex-wrap gap-1">
                    {p.kinds.map((k) => (
                      <span key={k} className="rounded-full bg-lime/25 px-2 py-0.5 text-[11px] font-semibold text-green-deep">
                        {KIND_BADGE[k].emoji} {KIND_BADGE[k].label}
                      </span>
                    ))}
                  </div>
                  <h2 className="line-clamp-2 flex-1 font-semibold text-ink">{p.title}</h2>
                  <div className="mt-3 flex items-center justify-between text-xs text-muted">
                    <span>{p.authorName ?? "EXANSYS"}</span>
                    <span>
                      {fmtDate(p.createdAt)}
                      {p.commentCount > 0 && ` · 💬 ${p.commentCount}`}
                    </span>
                  </div>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}

// ── 작성 폼 (admin) ──
function EduWriteForm({ onDone }: { onDone: () => void }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [atts, setAtts] = useState<PendingAtt[]>([]);
  const [linkUrl, setLinkUrl] = useState("");
  const [linkName, setLinkName] = useState("");
  const [busy, setBusy] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [msg, setMsg] = useState("");

  async function upload(path: string, contentType: string, data: BodyInit, kind: EduKind, name: string) {
    setBusy(name);
    setMsg("");
    try {
      const res = await fetch(path, {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": contentType },
        body: data,
      });
      const json = (await res.json()) as { ok: boolean; data?: { key: string; size: number }; error?: string };
      if (json.ok && json.data) {
        setAtts((a) => [...a, { kind, key: json.data!.key, name, size: json.data!.size }]);
      } else {
        setMsg(`업로드 실패: ${json.error ?? "error"}`);
      }
    } catch {
      setMsg("업로드 중 오류가 발생했습니다.");
    } finally {
      setBusy("");
    }
  }

  async function onHtml(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    e.target.value = "";
    if (!f) return;
    const buf = await f.arrayBuffer();
    await upload("/api/edu/upload/html", "text/html", buf, "html", f.name);
  }
  async function onImage(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    e.target.value = "";
    if (!f) return;
    try {
      const webp = await toWebp(f);
      await upload("/api/edu/upload/image", "image/webp", webp, "image", f.name.replace(/\.\w+$/, ".webp"));
    } catch {
      setMsg("이미지 변환에 실패했습니다.");
    }
  }
  async function onPdf(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    e.target.value = "";
    if (!f) return;
    await upload("/api/edu/upload/pdf", "application/pdf", f, "pdf", f.name);
  }
  function addLink() {
    if (!/^https?:\/\//.test(linkUrl)) {
      setMsg("올바른 링크(http/https)를 입력하세요.");
      return;
    }
    setAtts((a) => [...a, { kind: "link", url: linkUrl, name: linkName.trim() || linkUrl }]);
    setLinkUrl("");
    setLinkName("");
  }
  function removeAtt(i: number) {
    setAtts((a) => a.filter((_, idx) => idx !== i));
  }

  async function submit() {
    if (title.trim().length < 2) {
      setMsg("제목을 입력하세요.");
      return;
    }
    setSubmitting(true);
    setMsg("");
    const res = await api<{ id: number }>("/api/edu/posts", {
      method: "POST",
      body: JSON.stringify({
        title: title.trim(),
        body: body.trim() || null,
        attachments: atts.map((a) => ({ kind: a.kind, key: a.key, url: a.url, name: a.name })),
      }),
    });
    setSubmitting(false);
    if (res.ok) onDone();
    else setMsg("등록에 실패했습니다.");
  }

  const kindEmoji: Record<EduKind, string> = { html: "🖥️", image: "🖼️", pdf: "📄", link: "🔗" };

  return (
    <div className="mb-8 rounded-2xl border border-line bg-card p-6">
      <h2 className="mb-4 font-display text-lg font-bold">새 교육 자료</h2>
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="제목"
        className="mb-3 w-full rounded-xl border border-line bg-paper px-4 py-2.5 text-sm outline-none focus:border-ink"
      />
      <textarea
        value={body}
        onChange={(e) => setBody(e.target.value)}
        placeholder="설명 (마크다운 지원) — 자료에 대한 소개, 학습 포인트 등"
        rows={5}
        className="mb-4 w-full rounded-xl border border-line bg-paper px-4 py-2.5 text-sm outline-none focus:border-ink"
      />

      {/* 첨부 업로드 */}
      <div className="mb-4 flex flex-wrap gap-2">
        <label className="cursor-pointer rounded-full border border-line bg-paper px-4 py-2 text-sm font-semibold hover:border-ink">
          🖥️ HTML 자료
          <input type="file" accept=".html,text/html" onChange={onHtml} className="hidden" />
        </label>
        <label className="cursor-pointer rounded-full border border-line bg-paper px-4 py-2 text-sm font-semibold hover:border-ink">
          🖼️ 이미지
          <input type="file" accept="image/*" onChange={onImage} className="hidden" />
        </label>
        <label className="cursor-pointer rounded-full border border-line bg-paper px-4 py-2 text-sm font-semibold hover:border-ink">
          📄 PDF
          <input type="file" accept="application/pdf" onChange={onPdf} className="hidden" />
        </label>
        {busy && <span className="self-center text-sm text-muted">‘{busy}’ 업로드 중…</span>}
      </div>

      {/* 링크 추가 */}
      <div className="mb-4 flex flex-wrap gap-2">
        <input
          value={linkUrl}
          onChange={(e) => setLinkUrl(e.target.value)}
          placeholder="외부 링크 URL (https://…)"
          className="min-w-52 flex-1 rounded-xl border border-line bg-paper px-4 py-2 text-sm outline-none focus:border-ink"
        />
        <input
          value={linkName}
          onChange={(e) => setLinkName(e.target.value)}
          placeholder="링크 이름 (선택)"
          className="w-40 rounded-xl border border-line bg-paper px-4 py-2 text-sm outline-none focus:border-ink"
        />
        <button onClick={addLink} className="rounded-xl border border-line bg-paper px-4 py-2 text-sm font-semibold hover:border-ink">
          링크 추가
        </button>
      </div>

      {/* 첨부 목록 */}
      {atts.length > 0 && (
        <ul className="mb-4 space-y-1.5">
          {atts.map((a, i) => (
            <li key={i} className="flex items-center justify-between rounded-lg bg-paper px-3 py-2 text-sm">
              <span className="truncate">
                {kindEmoji[a.kind]} {a.name}
                {a.size ? <span className="ml-2 text-xs text-muted">{(a.size / 1024).toFixed(0)}KB</span> : null}
              </span>
              <button onClick={() => removeAtt(i)} className="ml-3 shrink-0 text-xs text-red-500 hover:underline">
                제거
              </button>
            </li>
          ))}
        </ul>
      )}

      {msg && <p className="mb-3 text-sm text-red-600">{msg}</p>}

      <div className="flex justify-end gap-2">
        <button
          onClick={submit}
          disabled={submitting || !!busy}
          className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
        >
          {submitting ? "등록 중…" : "게시하기"}
        </button>
      </div>
    </div>
  );
}

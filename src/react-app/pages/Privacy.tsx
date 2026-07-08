// 앱별 개인정보처리방침 (CLAUDE.md 5-5절)
// 공개 문서 뷰 + staff 이상 마크다운 편집기 + 버전 이력
import { useCallback, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { marked } from "marked";
import DOMPurify from "dompurify";
import { api, type Me } from "../lib/api";

type Policy = { version: number; bodyMd: string; updatedAt: string };
type AppInfo = { id: number; name: string; slug: string };
type Version = { version: number; updatedAt: string; updatedByName: string | null };

const TEMPLATE = `# {앱 이름} 개인정보처리방침

(주)엑사엔시스(이하 "회사")는 이용자의 개인정보를 소중히 여기며, 관련 법령을 준수합니다.

## 1. 수집하는 개인정보
- 수집 항목: (예: 없음 — 본 앱은 개인정보를 수집하지 않습니다)

## 2. 개인정보의 이용 목적
- (내용 작성)

## 3. 보관 및 파기
- (내용 작성)

## 4. 문의처
- 이메일: contact@exansys.net
`;

function fmt(d: string) {
  return new Date(d).toLocaleString("ko-KR", { year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" });
}

export default function Privacy({ me }: { me: Me }) {
  const { slug } = useParams<{ slug: string }>();
  const [app, setApp] = useState<AppInfo | null>(null);
  const [policy, setPolicy] = useState<Policy | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const [versions, setVersions] = useState<Version[]>([]);
  const [saving, setSaving] = useState(false);
  const isStaff = me && (me.role === "staff" || me.role === "admin");

  const load = useCallback(async () => {
    const res = await api<{ app: AppInfo; policy: Policy | null }>(`/api/apps/${slug}/privacy`);
    if (res.ok) {
      setApp(res.data.app);
      setPolicy(res.data.policy);
    } else {
      setNotFound(true);
    }
  }, [slug]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    if (isStaff) {
      void api<{ versions: Version[] }>(`/api/apps/${slug}/privacy/versions`).then((res) => {
        if (res.ok) setVersions(res.data.versions);
      });
    }
  }, [isStaff, slug, policy]);

  const save = async () => {
    setSaving(true);
    const res = await api<{ version: number }>(`/api/apps/${slug}/privacy`, {
      method: "PUT",
      body: JSON.stringify({ bodyMd: draft }),
    });
    setSaving(false);
    if (res.ok) {
      setEditing(false);
      void load();
    }
  };

  if (notFound) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-24 text-center">
        <p className="font-display text-2xl font-bold">앱을 찾을 수 없습니다.</p>
        <Link to="/" className="mt-4 inline-block font-semibold text-cobalt hover:underline">← 홈으로</Link>
      </main>
    );
  }
  if (!app) {
    return <main className="mx-auto max-w-3xl px-6 py-24 text-center text-muted">불러오는 중…</main>;
  }

  // XSS 방지: 마크다운 렌더 후 반드시 sanitize (CLAUDE.md 10절)
  const html = policy ? DOMPurify.sanitize(marked.parse(policy.bodyMd, { async: false })) : "";

  return (
    <main className="mx-auto max-w-3xl px-6 py-14">
      <Link to={`/apps/${app.slug}`} className="text-sm font-semibold text-muted hover:text-ink">
        ← {app.name}
      </Link>
      <div className="mt-4 flex flex-wrap items-center gap-3">
        <h1 className="font-display text-3xl font-extrabold tracking-tight">개인정보처리방침</h1>
        {policy && (
          <span className="rounded-full bg-paper px-3 py-1 text-xs font-semibold text-muted">
            v{policy.version} · {fmt(policy.updatedAt)}
          </span>
        )}
        {isStaff && !editing && (
          <button
            onClick={() => { setDraft(policy?.bodyMd ?? TEMPLATE.replace("{앱 이름}", app.name)); setEditing(true); }}
            className="ml-auto rounded-full border border-line bg-card px-4 py-1.5 text-sm font-semibold transition hover:border-ink"
          >
            ✏️ 편집
          </button>
        )}
      </div>

      {editing ? (
        <div className="mt-6">
          <textarea
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            className="h-[480px] w-full rounded-2xl border border-line bg-card p-5 font-mono text-sm leading-relaxed focus:border-green focus:outline-none"
          />
          <div className="mt-3 flex items-center gap-3">
            <button onClick={() => void save()} disabled={saving || draft.trim().length < 10}
              className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50">
              {saving ? "저장 중…" : "새 버전으로 저장"}
            </button>
            <button onClick={() => setEditing(false)} className="text-sm font-semibold text-muted hover:text-ink">
              취소
            </button>
          </div>
          <div className="prose-preview mt-6 rounded-2xl border border-dashed border-line bg-paper p-6">
            <p className="mb-3 text-xs font-bold text-muted">미리보기</p>
            <div className="privacy-doc" dangerouslySetInnerHTML={{
              __html: DOMPurify.sanitize(marked.parse(draft, { async: false })),
            }} />
          </div>
        </div>
      ) : policy ? (
        <div className="privacy-doc mt-6 rounded-2xl border border-line bg-card p-8"
          dangerouslySetInnerHTML={{ __html: html }} />
      ) : (
        <p className="mt-6 rounded-2xl border border-dashed border-line p-8 text-center text-sm text-muted">
          아직 등록된 개인정보처리방침이 없습니다.
          {isStaff && " 오른쪽 위 편집 버튼으로 작성해 주세요."}
        </p>
      )}

      {isStaff && versions.length > 0 && !editing && (
        <div className="mt-8 rounded-2xl border border-line bg-card p-6">
          <h2 className="font-display mb-3 text-base font-bold">버전 이력</h2>
          <ul className="space-y-1.5 text-sm text-muted">
            {versions.map((v) => (
              <li key={v.version}>
                v{v.version} · {fmt(v.updatedAt)} · {v.updatedByName ?? "?"}
              </li>
            ))}
          </ul>
        </div>
      )}
    </main>
  );
}

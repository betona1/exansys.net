import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, STATUS_LABEL, type AppRow, type Me } from "../lib/api";

type UserRow = {
  id: number;
  provider: string;
  name: string;
  avatarUrl: string | null;
  role: "member" | "crew" | "staff" | "admin";
};

const EMPTY_FORM = {
  slug: "",
  name: "",
  tagline: "",
  description: "",
  iconUrl: "",
  storeUrlAndroid: "",
  storeUrlIos: "",
  status: "development" as AppRow["status"],
};

export default function Admin({ me, meLoading }: { me: Me; meLoading: boolean }) {
  const [tab, setTab] = useState<"apps" | "users">("apps");
  const [apps, setApps] = useState<AppRow[]>([]);
  const [members, setMembers] = useState<UserRow[]>([]);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [msg, setMsg] = useState("");

  const isAdmin = me?.role === "admin";
  const canView = me && (me.role === "admin" || me.role === "staff");

  const loadApps = useCallback(async () => {
    const res = await api<{ apps: AppRow[] }>("/api/apps");
    if (res.ok) setApps(res.data.apps);
  }, []);

  const loadUsers = useCallback(async () => {
    const res = await api<{ users: UserRow[] }>("/api/admin/users");
    if (res.ok) setMembers(res.data.users);
  }, []);

  useEffect(() => {
    if (!canView) return;
    void loadApps();
    if (isAdmin) void loadUsers();
  }, [canView, isAdmin, loadApps, loadUsers]);

  if (meLoading) {
    return <main className="mx-auto max-w-6xl px-6 py-24 text-center text-muted">확인 중…</main>;
  }
  if (!canView) {
    return (
      <main className="mx-auto max-w-6xl px-6 py-24 text-center">
        <p className="font-display text-2xl font-bold">접근 권한이 없습니다.</p>
        <p className="mt-2 text-muted">관리자 페이지는 EXANSYS 직원 전용입니다.</p>
        <Link to="/" className="mt-4 inline-block font-semibold text-cobalt hover:underline">
          ← 홈으로
        </Link>
      </main>
    );
  }

  const input =
    "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";
  const label = "mb-1.5 block text-xs font-semibold text-muted";

  const submitApp = async (e: React.FormEvent) => {
    e.preventDefault();
    setMsg("");
    const res = editingId
      ? await api(`/api/admin/apps/${editingId}`, { method: "PUT", body: JSON.stringify(form) })
      : await api("/api/admin/apps", { method: "POST", body: JSON.stringify(form) });
    if (res.ok) {
      setMsg(editingId ? "수정되었습니다." : "등록되었습니다.");
      setForm(EMPTY_FORM);
      setEditingId(null);
      void loadApps();
    } else {
      setMsg(`오류: ${res.error}`);
    }
  };

  const startEdit = (app: AppRow) => {
    setEditingId(app.id);
    setForm({
      slug: app.slug,
      name: app.name,
      tagline: app.tagline ?? "",
      description: app.description ?? "",
      iconUrl: app.iconUrl ?? "",
      storeUrlAndroid: app.storeUrlAndroid ?? "",
      storeUrlIos: app.storeUrlIos ?? "",
      status: app.status,
    });
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const deleteApp = async (id: number) => {
    if (!window.confirm("이 앱을 삭제할까요? 되돌릴 수 없습니다.")) return;
    const res = await api(`/api/admin/apps/${id}`, { method: "DELETE" });
    if (res.ok) void loadApps();
  };

  const changeRole = async (id: number, role: string) => {
    const res = await api(`/api/admin/users/${id}/role`, {
      method: "PUT",
      body: JSON.stringify({ role }),
    });
    if (res.ok) void loadUsers();
    else window.alert(`오류: ${(res as { error: string }).error}`);
  };

  return (
    <main className="mx-auto max-w-6xl px-6 py-14">
      <h1 className="font-display text-3xl font-extrabold tracking-tight">관리자</h1>
      <p className="mt-1 text-sm text-muted">{me!.name} · {me!.role === "admin" ? "관리자" : "직원"}</p>

      <div className="mt-7 flex gap-1.5 border-b border-line">
        <button
          onClick={() => setTab("apps")}
          className={`rounded-t-lg px-4 py-2.5 text-sm font-semibold ${tab === "apps" ? "border border-b-0 border-line bg-card" : "text-muted"}`}
        >
          앱 관리
        </button>
        {isAdmin && (
          <button
            onClick={() => setTab("users")}
            className={`rounded-t-lg px-4 py-2.5 text-sm font-semibold ${tab === "users" ? "border border-b-0 border-line bg-card" : "text-muted"}`}
          >
            회원 관리
          </button>
        )}
      </div>

      {tab === "apps" && (
        <div className="mt-8 grid gap-8 lg:grid-cols-2">
          {isAdmin && (
            <form onSubmit={submitApp} className="rounded-2xl border border-line bg-card p-6">
              <h2 className="font-display mb-5 text-lg font-bold">
                {editingId ? `앱 수정 (#${editingId})` : "새 앱 등록"}
              </h2>
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <label className={label}>슬러그 (URL용, 영문 소문자)</label>
                  <input className={input} required value={form.slug} placeholder="my-app"
                    onChange={(e) => setForm({ ...form, slug: e.target.value })} />
                </div>
                <div>
                  <label className={label}>앱 이름</label>
                  <input className={input} required value={form.name} placeholder="My App"
                    onChange={(e) => setForm({ ...form, name: e.target.value })} />
                </div>
                <div className="sm:col-span-2">
                  <label className={label}>한 줄 소개</label>
                  <input className={input} value={form.tagline}
                    onChange={(e) => setForm({ ...form, tagline: e.target.value })} />
                </div>
                <div className="sm:col-span-2">
                  <label className={label}>설명</label>
                  <textarea className={`${input} h-28`} value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })} />
                </div>
                <div>
                  <label className={label}>아이콘 (이모지 또는 이미지 URL)</label>
                  <input className={input} value={form.iconUrl} placeholder="📱"
                    onChange={(e) => setForm({ ...form, iconUrl: e.target.value })} />
                </div>
                <div>
                  <label className={label}>상태</label>
                  <select className={input} value={form.status}
                    onChange={(e) => setForm({ ...form, status: e.target.value as AppRow["status"] })}>
                    <option value="planning">기획 중</option>
                    <option value="development">개발 중</option>
                    <option value="released">출시됨</option>
                  </select>
                </div>
                <div>
                  <label className={label}>Google Play URL</label>
                  <input className={input} value={form.storeUrlAndroid} placeholder="https://play.google.com/..."
                    onChange={(e) => setForm({ ...form, storeUrlAndroid: e.target.value })} />
                </div>
                <div>
                  <label className={label}>App Store URL</label>
                  <input className={input} value={form.storeUrlIos} placeholder="https://apps.apple.com/..."
                    onChange={(e) => setForm({ ...form, storeUrlIos: e.target.value })} />
                </div>
              </div>
              <div className="mt-5 flex items-center gap-3">
                <button type="submit"
                  className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep">
                  {editingId ? "수정 저장" : "등록"}
                </button>
                {editingId && (
                  <button type="button" className="text-sm font-semibold text-muted hover:text-ink"
                    onClick={() => { setEditingId(null); setForm(EMPTY_FORM); }}>
                    취소
                  </button>
                )}
                {msg && <span className="text-sm font-semibold text-green">{msg}</span>}
              </div>
            </form>
          )}

          <div className="space-y-3">
            <h2 className="font-display text-lg font-bold">등록된 앱 {apps.length}개</h2>
            {apps.length === 0 && (
              <p className="rounded-2xl border border-dashed border-line p-6 text-sm text-muted">
                아직 등록된 앱이 없습니다. 왼쪽 폼으로 첫 앱을 등록해 보세요.
              </p>
            )}
            {apps.map((app) => (
              <div key={app.id} className="flex items-center gap-4 rounded-2xl border border-line bg-card p-4">
                <div className="grid h-11 w-11 shrink-0 place-items-center overflow-hidden rounded-xl bg-lime/15 text-xl">
                  {app.iconUrl?.startsWith("http") ? (
                    <img src={app.iconUrl} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <span>{app.iconUrl || "📱"}</span>
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold">{app.name}</div>
                  <div className="text-xs text-muted">
                    /{app.slug} · {STATUS_LABEL[app.status]} · ⬇ {app.downloadCount.toLocaleString()}
                  </div>
                </div>
                <Link to={`/apps/${app.slug}`} className="text-xs font-semibold text-cobalt hover:underline">
                  보기
                </Link>
                {isAdmin && (
                  <>
                    <button onClick={() => startEdit(app)} className="text-xs font-semibold text-muted hover:text-ink">
                      수정
                    </button>
                    <button onClick={() => void deleteApp(app.id)} className="text-xs font-semibold text-red-600 hover:underline">
                      삭제
                    </button>
                  </>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {tab === "users" && isAdmin && (
        <div className="mt-8 space-y-3">
          <h2 className="font-display text-lg font-bold">회원 {members.length}명</h2>
          {members.map((u) => (
            <div key={u.id} className="flex items-center gap-4 rounded-2xl border border-line bg-card p-4">
              {u.avatarUrl ? (
                <img src={u.avatarUrl} alt="" className="h-10 w-10 rounded-full" />
              ) : (
                <span className="grid h-10 w-10 place-items-center rounded-full bg-lime/40 font-bold">
                  {u.name.slice(0, 1)}
                </span>
              )}
              <div className="min-w-0 flex-1">
                <div className="truncate font-semibold">{u.name}</div>
                <div className="text-xs text-muted">#{u.id} · {u.provider}</div>
              </div>
              {u.id === me!.id ? (
                <span className="rounded-full bg-lime/25 px-3 py-1 text-xs font-semibold text-green-deep">
                  나 ({u.role})
                </span>
              ) : (
                <select
                  value={u.role}
                  onChange={(e) => void changeRole(u.id, e.target.value)}
                  className="rounded-xl border border-line bg-card px-3 py-2 text-sm"
                >
                  <option value="member">member</option>
                  <option value="crew">crew</option>
                  <option value="staff">staff</option>
                  <option value="admin">admin</option>
                </select>
              )}
            </div>
          ))}
        </div>
      )}
    </main>
  );
}

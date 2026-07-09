// 관리자용 — 앱 스크린샷 업로드 + 테스트 APK 빌드 관리 (Admin 페이지에서 사용)
import { useCallback, useEffect, useRef, useState } from "react";
import { api, type AppRow } from "../lib/api";
import { toWebp } from "../lib/image";

type Screenshot = { id: number; imageUrl: string };
export type BuildRow = {
  id: number;
  version: string;
  fileSize: number;
  notes: string | null;
  downloadCount: number;
  createdAt: string;
};

const CHUNK = 25 * 1024 * 1024; // 워커 본문 100MB 제한 대비 25MB 조각

export function formatBytes(n: number): string {
  if (n >= 1024 * 1024 * 1024) return `${(n / (1024 * 1024 * 1024)).toFixed(2)}GB`;
  if (n >= 1024 * 1024) return `${(n / (1024 * 1024)).toFixed(1)}MB`;
  return `${Math.ceil(n / 1024)}KB`;
}

export default function AppAssets({ app, onClose }: { app: AppRow; onClose: () => void }) {
  const [shots, setShots] = useState<Screenshot[]>([]);
  const [builds, setBuilds] = useState<BuildRow[]>([]);
  const [version, setVersion] = useState("");
  const [notes, setNotes] = useState("");
  const [apkFile, setApkFile] = useState<File | null>(null);
  const [progress, setProgress] = useState<number | null>(null);
  const [msg, setMsg] = useState("");
  const shotInputRef = useRef<HTMLInputElement>(null);
  const apkInputRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    const detail = await api<{ screenshots: Screenshot[] }>(`/api/apps/${app.slug}`);
    if (detail.ok) setShots(detail.data.screenshots);
    const b = await api<{ builds: BuildRow[] }>(`/api/apps/${app.slug}/builds`);
    if (b.ok) setBuilds(b.data.builds);
  }, [app.slug]);

  useEffect(() => {
    void load();
  }, [load]);

  const uploadShots = async (files: FileList | null) => {
    if (!files?.length) return;
    setMsg("스크린샷 변환·업로드 중…");
    for (const file of Array.from(files)) {
      try {
        const webp = await toWebp(file, 2000);
        if (webp.size > 5 * 1024 * 1024) {
          setMsg(`오류: ${file.name} — 변환 후에도 5MB 초과`);
          continue;
        }
        const res = await fetch(`/api/admin/apps/${app.id}/screenshots`, {
          method: "POST",
          headers: { "Content-Type": "image/webp" },
          body: webp,
        });
        const j = (await res.json()) as { ok: boolean; error?: string };
        if (!j.ok) setMsg(`오류: ${j.error}`);
      } catch {
        setMsg(`오류: ${file.name} 변환 실패`);
      }
    }
    setMsg("스크린샷 업로드 완료");
    if (shotInputRef.current) shotInputRef.current.value = "";
    void load();
  };

  const deleteShot = async (id: number) => {
    const res = await api(`/api/admin/screenshots/${id}`, { method: "DELETE" });
    if (res.ok) void load();
  };

  const uploadApk = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!apkFile || !version.trim()) return;
    setProgress(0);
    setMsg("");

    const start = await api<{ key: string; uploadId: string }>(
      `/api/admin/apps/${app.id}/builds/start`,
      { method: "POST", body: JSON.stringify({ version: version.trim(), size: apkFile.size }) },
    );
    if (!start.ok) {
      setProgress(null);
      setMsg(`오류: ${start.error}`);
      return;
    }
    const { key, uploadId } = start.data;
    const totalParts = Math.ceil(apkFile.size / CHUNK);
    const parts: { partNumber: number; etag: string }[] = [];

    try {
      for (let i = 0; i < totalParts; i++) {
        const chunk = apkFile.slice(i * CHUNK, (i + 1) * CHUNK);
        const res = await fetch(
          `/api/admin/builds/part?key=${encodeURIComponent(key)}&uploadId=${encodeURIComponent(uploadId)}&part=${i + 1}`,
          { method: "PUT", body: chunk },
        );
        const j = (await res.json()) as {
          ok: boolean;
          data?: { partNumber: number; etag: string };
          error?: string;
        };
        if (!j.ok || !j.data) throw new Error(j.error ?? "part_failed");
        parts.push(j.data);
        setProgress(Math.round(((i + 1) / totalParts) * 95));
      }
      const done = await api(`/api/admin/apps/${app.id}/builds/complete`, {
        method: "POST",
        body: JSON.stringify({
          key,
          uploadId,
          parts,
          version: version.trim(),
          notes: notes.trim() || null,
          size: apkFile.size,
        }),
      });
      if (!done.ok) throw new Error(done.error);
      setProgress(null);
      setMsg("빌드 업로드 완료 — 회원들이 다운로드할 수 있습니다.");
      setVersion("");
      setNotes("");
      setApkFile(null);
      if (apkInputRef.current) apkInputRef.current.value = "";
      void load();
    } catch (err) {
      // 실패한 멀티파트 업로드는 R2에 조각이 남지 않게 중단 처리
      void api("/api/admin/builds/abort", {
        method: "POST",
        body: JSON.stringify({ key, uploadId }),
      });
      setProgress(null);
      setMsg(`업로드 실패: ${err instanceof Error ? err.message : "unknown"}`);
    }
  };

  const deleteBuild = async (id: number) => {
    if (!window.confirm("이 테스트 빌드를 삭제할까요? 파일도 함께 삭제됩니다.")) return;
    const res = await api(`/api/admin/builds/${id}`, { method: "DELETE" });
    if (res.ok) void load();
  };

  const input =
    "w-full rounded-xl border border-line bg-card px-3.5 py-2.5 text-sm focus:border-green focus:outline-none";

  return (
    <div className="rounded-2xl border-2 border-green/30 bg-card p-6">
      <div className="mb-5 flex items-center justify-between">
        <h2 className="font-display text-lg font-bold">
          {app.name} — 스크린샷 · 베타 빌드 관리
        </h2>
        <button onClick={onClose} className="text-sm font-semibold text-muted hover:text-ink">
          닫기 ✕
        </button>
      </div>

      <div className="grid gap-8 lg:grid-cols-2">
        {/* 스크린샷 */}
        <section>
          <h3 className="mb-3 text-sm font-bold">스크린샷 {shots.length}장</h3>
          <input
            ref={shotInputRef}
            type="file"
            accept="image/*"
            multiple
            onChange={(e) => void uploadShots(e.target.files)}
            className="block w-full text-sm text-muted file:mr-3 file:rounded-full file:border-0 file:bg-lime/25 file:px-4 file:py-2 file:text-sm file:font-semibold file:text-green-deep"
          />
          <p className="mt-1.5 text-xs text-muted">
            여러 장 선택 가능 · 자동으로 webp 변환 (장당 최대 5MB) · 앱 상세 페이지에 공개 표시
          </p>
          {shots.length > 0 && (
            <div className="mt-4 flex gap-3 overflow-x-auto pb-2">
              {shots.map((s) => (
                <div key={s.id} className="relative shrink-0">
                  <img src={s.imageUrl} alt="" className="h-40 rounded-xl border border-line" />
                  <button
                    onClick={() => void deleteShot(s.id)}
                    className="absolute right-1.5 top-1.5 rounded-full bg-ink/80 px-2 py-0.5 text-xs font-bold text-white hover:bg-red-600"
                    aria-label="스크린샷 삭제"
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* 베타 빌드 */}
        <section>
          <h3 className="mb-3 text-sm font-bold">테스트 APK 빌드 {builds.length}개</h3>
          <form onSubmit={(e) => void uploadApk(e)} className="space-y-3">
            <input
              ref={apkInputRef}
              type="file"
              accept=".apk"
              onChange={(e) => setApkFile(e.target.files?.[0] ?? null)}
              className="block w-full text-sm text-muted file:mr-3 file:rounded-full file:border-0 file:bg-lime/25 file:px-4 file:py-2 file:text-sm file:font-semibold file:text-green-deep"
            />
            <div className="flex gap-3">
              <input
                className={input}
                placeholder="버전 (예: 0.9.0-beta1)"
                value={version}
                onChange={(e) => setVersion(e.target.value)}
                required
              />
            </div>
            <textarea
              className={`${input} h-20`}
              placeholder="테스트 안내 / 변경 사항 (선택)"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
            <button
              type="submit"
              disabled={!apkFile || !version.trim() || progress !== null}
              className="rounded-full bg-green px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
            >
              {progress !== null ? `업로드 중… ${progress}%` : "빌드 업로드"}
            </button>
            {progress !== null && (
              <div className="h-2 overflow-hidden rounded-full bg-paper">
                <div className="h-full bg-green transition-all" style={{ width: `${progress}%` }} />
              </div>
            )}
          </form>
          <p className="mt-1.5 text-xs text-muted">최대 300MB · 25MB씩 나눠서 업로드됩니다</p>

          {builds.length > 0 && (
            <ul className="mt-4 space-y-2">
              {builds.map((b) => (
                <li
                  key={b.id}
                  className="flex items-center gap-3 rounded-xl border border-line px-4 py-3 text-sm"
                >
                  <span className="font-bold">v{b.version}</span>
                  <span className="text-xs text-muted">
                    {formatBytes(b.fileSize)} · ⬇ {b.downloadCount}
                  </span>
                  <span className="flex-1" />
                  <a
                    href={`/api/apps/${app.slug}/builds/${b.id}/download`}
                    className="text-xs font-semibold text-cobalt hover:underline"
                  >
                    받기
                  </a>
                  <button
                    onClick={() => void deleteBuild(b.id)}
                    className="text-xs font-semibold text-red-600 hover:underline"
                  >
                    삭제
                  </button>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      {msg && <p className="mt-4 text-sm font-semibold text-green">{msg}</p>}
    </div>
  );
}

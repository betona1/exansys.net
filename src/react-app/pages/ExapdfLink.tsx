import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import type { Me } from "../lib/api";

/**
 * ExaPDF 앱과 계정을 잇는 화면 (`/exapdf/link`).
 *
 * 앱이 보여 주는 여섯 자리 코드를 여기에 넣는다. 앱 안에 로그인 창을
 * 띄우지 않는 이유는 **앱이 비밀번호를 볼 일이 없어야** 하기 때문이다.
 * 로그인은 늘 브라우저에서, 이미 만들어 둔 소셜·이메일 로그인을 그대로 쓴다.
 */
export default function ExapdfLink({ me }: { me: Me }) {
  const [code, setCode] = useState("");
  const [state, setState] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);

  // 앱이 열어 준 주소에 코드가 실려 있으면 채워 준다 — 손으로 옮겨 적지 않게
  useEffect(() => {
    const q = new URLSearchParams(window.location.search).get("code");
    if (q) setCode(q.toUpperCase());
  }, []);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setState("sending");
    const res = await fetch("/api/exapdf/link/confirm", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ code: code.trim().toUpperCase() }),
    });
    const body = (await res.json().catch(() => null)) as { ok?: boolean; error?: string } | null;
    if (res.ok && body?.ok) {
      setState("done");
      return;
    }
    setState("idle");
    setError(
      body?.error === "expired"
        ? "코드가 만료됐거나 없는 코드입니다. 앱에서 새로 받아 주세요."
        : body?.error === "bad_code"
          ? "코드 모양이 맞지 않습니다. 앱 화면과 같은지 확인해 주세요."
          : "연결하지 못했습니다. 잠시 뒤 다시 시도해 주세요.",
    );
  }

  return (
    <main className="mx-auto max-w-lg px-6 py-16">
      <h1 className="font-display text-3xl font-extrabold tracking-tight">ExaPDF 앱 연결</h1>
      <p className="mt-3 text-muted">
        앱 화면에 뜬 여섯 자리 코드를 넣어 주세요. 연결하면 앱에서 Pro 기능을 쓸 수 있습니다.
      </p>

      {!me ? (
        <div className="mt-8 rounded-2xl border border-line bg-card p-6">
          <p className="text-[15px]">
            먼저 로그인해 주세요. 카카오·구글·깃허브·네이버 또는 이메일로 들어올 수 있습니다.
          </p>
          <Link
            to={`/login?next=${encodeURIComponent("/exapdf/link" + window.location.search)}`}
            className="mt-4 inline-block rounded-xl bg-ink px-6 py-3 font-semibold text-white transition hover:bg-green"
          >
            로그인하기
          </Link>
        </div>
      ) : state === "done" ? (
        <div className="mt-8 rounded-2xl border border-green/40 bg-green/10 p-6">
          <p className="font-semibold">연결됐습니다.</p>
          <p className="mt-2 text-[15px] text-muted">
            앱으로 돌아가시면 <b>{me.name}</b> 님으로 로그인돼 있습니다. 이 창은 닫으셔도 됩니다.
          </p>
        </div>
      ) : (
        <form onSubmit={submit} className="mt-8 rounded-2xl border border-line bg-card p-6">
          <label htmlFor="code" className="text-sm font-semibold">
            연결 코드
          </label>
          <input
            id="code"
            value={code}
            onChange={(e) => setCode(e.target.value.toUpperCase())}
            placeholder="ABC-123"
            autoComplete="off"
            autoCapitalize="characters"
            spellCheck={false}
            className="font-display mt-2 w-full rounded-xl border border-line bg-bg px-4 py-3 text-center text-2xl tracking-[0.3em]"
          />
          {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
          <button
            type="submit"
            disabled={state === "sending" || code.trim().length < 6}
            className="mt-4 w-full rounded-xl bg-ink px-6 py-3 font-semibold text-white transition hover:bg-green disabled:opacity-40"
          >
            {state === "sending" ? "연결하는 중…" : "연결하기"}
          </button>
          <p className="mt-4 text-xs text-muted">
            {me.name} 님으로 연결됩니다. 다른 계정에 붙이시려면 로그아웃 후 다시 들어와 주세요.
          </p>
        </form>
      )}

      <p className="mt-8 text-sm text-muted">
        ExaPDF 가 처음이시면 <a className="text-green-deep hover:underline" href="/exapdf-download/">안내 페이지</a>를 보세요.
      </p>
    </main>
  );
}

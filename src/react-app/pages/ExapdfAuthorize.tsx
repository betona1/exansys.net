import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";

import type { Me } from "../lib/api";

/**
 * 앱이 브라우저로 열어 주는 로그인 화면 (`/exapdf/authorize?device=...`).
 *
 * 사람이 옮겨 적을 것이 없다 — 앱이 기기 번호를 주소에 실어 보내므로
 * 로그인만 하면 바로 묶인다. 앱은 그동안 결과를 기다리고 있다.
 *
 * 앱 안에 소셜 버튼을 두지 않는 이유: 카카오·구글이 앱 내 웹뷰 로그인을
 * 막고, 무엇보다 **앱이 비밀번호를 볼 일이 없어야** 하기 때문이다.
 */
export default function ExapdfAuthorize({ me }: { me: Me }) {
  const [state, setState] = useState<"working" | "done" | "error">("working");
  const [error, setError] = useState<string | null>(null);
  const device = new URLSearchParams(window.location.search).get("device") ?? "";

  const bind = useCallback(async () => {
    setState("working");
    setError(null);
    const res = await fetch("/api/exapdf/link/confirm-device", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ device }),
    });
    const body = (await res.json().catch(() => null)) as { ok?: boolean; error?: string } | null;
    if (res.ok && body?.ok) {
      setState("done");
      return;
    }
    setState("error");
    setError(
      body?.error === "expired"
        ? "연결 시간이 지났습니다. 앱에서 로그인을 다시 눌러 주세요."
        : "연결하지 못했습니다. 앱에서 다시 시도해 주세요.",
    );
  }, [device]);

  useEffect(() => {
    if (me && device) void bind();
  }, [me, device, bind]);

  const next = encodeURIComponent(`/exapdf/authorize?device=${device}`);

  return (
    <main className="mx-auto max-w-lg px-6 py-16">
      <h1 className="font-display text-3xl font-extrabold tracking-tight">ExaPDF 로그인</h1>

      {!device ? (
        <p className="mt-4 text-muted">
          앱에서 열어 주신 주소가 아닙니다. 앱의 <b>로그인</b> 버튼을 눌러 주세요.
        </p>
      ) : !me ? (
        <div className="mt-8 rounded-2xl border border-line bg-card p-6">
          <p className="text-[15px]">
            카카오 · 구글 · 깃허브 · 네이버 또는 이메일로 들어오실 수 있습니다.
            로그인하시면 앱이 자동으로 연결됩니다.
          </p>
          <Link
            to={`/login?next=${next}`}
            className="mt-5 inline-block w-full rounded-xl bg-ink px-6 py-3.5 text-center font-semibold text-white transition hover:bg-green"
          >
            로그인하고 앱 연결하기
          </Link>
        </div>
      ) : state === "done" ? (
        <div className="mt-8 rounded-2xl border border-green/40 bg-green/10 p-6">
          <p className="font-semibold">연결됐습니다.</p>
          <p className="mt-2 text-[15px] text-muted">
            <b>{me.name}</b> 님으로 앱에 로그인됐습니다. 앱으로 돌아가시면 됩니다 —
            이 창은 닫으셔도 됩니다.
          </p>
        </div>
      ) : state === "error" ? (
        <div className="mt-8 rounded-2xl border border-line bg-card p-6">
          <p className="text-[15px]">{error}</p>
          <button
            type="button"
            onClick={() => void bind()}
            className="mt-4 rounded-xl bg-ink px-6 py-3 font-semibold text-white transition hover:bg-green"
          >
            다시 시도
          </button>
        </div>
      ) : (
        <p className="mt-8 text-muted">연결하는 중…</p>
      )}

      <p className="mt-8 text-sm text-muted">
        코드를 손으로 넣으시려면{" "}
        <Link className="text-green-deep hover:underline" to="/exapdf/link">
          코드로 연결
        </Link>
        을 쓰세요.
      </p>
    </main>
  );
}

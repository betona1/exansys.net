// 로그인 페이지 — 소셜 간편로그인 + 이메일 인증코드(패스워드리스)
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import BrandLogo from "../components/BrandLogo";
import Mascot from "../components/Mascot";
import Turnstile from "../components/Turnstile";
import { api, type Me } from "../lib/api";

const SOCIAL: Record<string, { label: string; cls: string; icon: string }> = {
  google: {
    label: "Google로 계속하기",
    cls: "border border-line bg-card text-ink hover:border-ink",
    icon: "G",
  },
  kakao: {
    label: "카카오로 계속하기",
    cls: "bg-[#FEE500] text-[#191919] hover:brightness-95",
    icon: "K",
  },
  naver: {
    label: "네이버로 계속하기",
    cls: "bg-[#03C75A] text-white hover:brightness-95",
    icon: "N",
  },
  github: {
    label: "GitHub로 계속하기",
    cls: "bg-ink text-white hover:bg-green",
    icon: "GH",
  },
};

export default function Login({ me, refresh }: { me: Me; refresh: () => Promise<void> }) {
  const navigate = useNavigate();

  // 로그인 뒤 돌아갈 곳. 앱 연결(/exapdf/authorize)처럼 원래 화면으로
  // 돌아가야 일이 끝나는 흐름이 있다. 우리 사이트 안 경로만 받는다
  const nextPath = (() => {
    const raw = new URLSearchParams(window.location.search).get("next") ?? "/";
    if (raw.startsWith("/") && !raw.startsWith("//")) return raw;
    // 우리 서브도메인(exapdf.exansys.net 등)도 받는다 — 브라우저 저장소가
    // 출처마다 따로라 그 주소로 돌아가야 서재가 보인다
    try {
      const u = new URL(raw);
      if (u.protocol === "https:" && (u.hostname === "exansys.net" || u.hostname.endsWith(".exansys.net"))) {
        return u.toString();
      }
    } catch {
      /* 주소 모양이 아니면 홈으로 */
    }
    return "/";
  })();
  const [providers, setProviders] = useState<string[]>([]);
  const [emailLogin, setEmailLogin] = useState(false);
  const [siteKey, setSiteKey] = useState<string | null>(null);
  const [step, setStep] = useState<"email" | "code">("email");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [token, setToken] = useState("");
  const [msg, setMsg] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void api<{ providers: string[]; emailLogin: boolean }>("/api/auth/providers").then((res) => {
      if (res.ok) {
        setProviders(res.data.providers);
        setEmailLogin(res.data.emailLogin);
      }
    });
    void api<{ turnstileSiteKey: string | null }>("/api/config").then((res) => {
      if (res.ok) setSiteKey(res.data.turnstileSiteKey);
    });
  }, []);

  // 이미 로그인된 경우 홈으로
  useEffect(() => {
    if (me) navigate("/", { replace: true });
  }, [me, navigate]);

  const sendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (siteKey && !token) {
      setMsg("스팸 방지 확인을 완료해 주세요.");
      return;
    }
    setBusy(true);
    setMsg("");
    const res = await api("/api/auth/email/start", {
      method: "POST",
      body: JSON.stringify({ email, turnstileToken: token }),
    });
    setBusy(false);
    if (res.ok) {
      setStep("code");
      setMsg("");
    } else {
      setMsg(
        res.error === "too_many_requests"
          ? "요청이 너무 많습니다. 1시간 후 다시 시도해 주세요."
          : `발송 실패: ${res.error}`,
      );
    }
  };

  const verifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setMsg("");
    const res = await api("/api/auth/email/verify", {
      method: "POST",
      body: JSON.stringify({ email, code }),
    });
    setBusy(false);
    if (res.ok) {
      await refresh();
      // 다른 출처(서브도메인)면 라우터가 아니라 통째로 옮겨 가야 한다
      if (nextPath.startsWith("http")) window.location.replace(nextPath);
      else navigate(nextPath, { replace: true });
    } else {
      setMsg(
        res.error === "wrong_code"
          ? "코드가 올바르지 않습니다."
          : res.error === "code_expired"
            ? "코드가 만료됐습니다. 다시 발송해 주세요."
            : `오류: ${res.error}`,
      );
    }
  };

  const input =
    "w-full rounded-xl border border-line bg-paper px-4 py-3 text-sm focus:border-green focus:outline-none";

  return (
    <main className="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center px-6 py-16">
      <div className="rounded-[2rem] border border-line bg-card p-8 shadow-sm">
        <div className="mb-6 flex justify-center">
          <Link to="/">
            <span className="inline-flex items-end gap-3">
              <BrandLogo variant="full" size={96} />
              <Mascot variant="full" size={120} float />
            </span>
          </Link>
        </div>
        <h1 className="font-display text-center text-2xl font-extrabold tracking-tight">
          EXANSYS 로그인
        </h1>
        <p className="mt-2 text-center text-sm text-muted">
          간편하게 로그인하고 문의와 댓글을 남겨보세요.
        </p>

        <div className="mt-7 space-y-2.5">
          {providers.map((p) => {
            const s = SOCIAL[p];
            if (!s) return null;
            return (
              <a
                key={p}
                href={`/api/auth/${p}/start?next=${encodeURIComponent(nextPath)}`}
                className={`flex w-full items-center justify-center gap-2.5 rounded-xl px-4 py-3 text-sm font-semibold transition ${s.cls}`}
              >
                <span className="grid h-5 w-5 place-items-center rounded text-[10px] font-extrabold">
                  {s.icon}
                </span>
                {s.label}
              </a>
            );
          })}
        </div>

        {emailLogin && (
          <>
            <div className="my-6 flex items-center gap-3 text-xs text-muted">
              <span className="h-px flex-1 bg-line" />
              또는 이메일로
              <span className="h-px flex-1 bg-line" />
            </div>

            {step === "email" ? (
              <form onSubmit={sendCode} className="space-y-3">
                <input
                  type="email"
                  required
                  className={input}
                  placeholder="your@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
                {siteKey && <Turnstile siteKey={siteKey} onToken={setToken} />}
                <button
                  type="submit"
                  disabled={busy}
                  className="w-full rounded-xl bg-green px-4 py-3 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
                >
                  {busy ? "발송 중…" : "인증코드 받기"}
                </button>
              </form>
            ) : (
              <form onSubmit={verifyCode} className="space-y-3">
                <p className="text-center text-sm text-muted">
                  <b className="text-ink">{email}</b> 로 보낸
                  <br />
                  6자리 코드를 입력해 주세요. (10분 유효)
                </p>
                <input
                  inputMode="numeric"
                  pattern="\d{6}"
                  maxLength={6}
                  required
                  autoFocus
                  className={`${input} text-center text-2xl font-bold tracking-[0.5em]`}
                  placeholder="······"
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
                />
                <button
                  type="submit"
                  disabled={busy || code.length !== 6}
                  className="w-full rounded-xl bg-green px-4 py-3 text-sm font-semibold text-white transition hover:bg-green-deep disabled:opacity-50"
                >
                  {busy ? "확인 중…" : "로그인"}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setStep("email");
                    setCode("");
                    setMsg("");
                  }}
                  className="w-full text-center text-xs font-semibold text-muted hover:text-ink"
                >
                  ← 이메일 다시 입력
                </button>
              </form>
            )}
          </>
        )}

        {msg && <p className="mt-4 text-center text-sm font-semibold text-red-600">{msg}</p>}

        <p className="mt-7 text-center text-xs text-muted">
          로그인하면 비밀번호 없이 소셜 계정 또는 이메일 인증만 사용합니다.
          <br />
          문의: contact@exansys.net
        </p>
      </div>
    </main>
  );
}

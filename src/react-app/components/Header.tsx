import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import SnakeLogo from "./SnakeLogo";
import { api, type Me } from "../lib/api";

const PROVIDER_LABEL: Record<string, string> = {
  google: "Google로 계속하기",
  github: "GitHub로 계속하기",
  kakao: "카카오로 계속하기",
};

export default function Header({ me, logout }: { me: Me; logout: () => Promise<void> }) {
  const [open, setOpen] = useState(false);
  const [providers, setProviders] = useState<string[]>([]);
  const [dark, setDark] = useState(() => document.documentElement.classList.contains("dark"));
  const menuRef = useRef<HTMLLIElement>(null);

  const toggleTheme = () => {
    const next = !dark;
    setDark(next);
    document.documentElement.classList.toggle("dark", next);
    try {
      localStorage.setItem("theme", next ? "dark" : "light");
    } catch {
      /* ignore */
    }
  };

  useEffect(() => {
    void api<{ providers: string[] }>("/api/auth/providers").then((res) => {
      if (res.ok) setProviders(res.data.providers);
    });
  }, []);

  useEffect(() => {
    const close = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, []);

  return (
    <header className="sticky top-0 z-50 border-b border-line bg-paper/85 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
        <Link to="/" aria-label="EXANSYS 홈">
          <SnakeLogo size={34} />
        </Link>
        <nav aria-label="주 메뉴">
          <ul className="flex items-center gap-6 text-[15px] font-medium">
            <li className="hidden sm:block">
              <Link className="text-muted transition hover:text-ink" to="/#apps">앱</Link>
            </li>
            <li className="hidden sm:block">
              <Link className="text-muted transition hover:text-ink" to="/#about">소개</Link>
            </li>
            {me && (me.role === "crew" || me.role === "staff" || me.role === "admin") && (
              <li className="hidden sm:block">
                <Link className="font-semibold text-green transition hover:text-green-deep" to="/crew">
                  크루
                </Link>
              </li>
            )}
            <li className="hidden sm:block">
              <Link
                className="rounded-full bg-ink px-4.5 py-2 font-semibold text-white transition hover:bg-green"
                to="/contact"
              >
                개발 문의
              </Link>
            </li>
            <li>
              <button
                onClick={toggleTheme}
                aria-label={dark ? "라이트 모드로 전환" : "다크 모드로 전환"}
                title={dark ? "라이트 모드" : "다크 모드"}
                className="grid h-9 w-9 place-items-center rounded-full border border-line bg-card text-base transition hover:border-ink"
              >
                {dark ? "☀️" : "🌙"}
              </button>
            </li>
            <li className="relative" ref={menuRef}>
              {me ? (
                <>
                  <button
                    onClick={() => setOpen(!open)}
                    className="flex items-center gap-2 rounded-full border border-line bg-card py-1.5 pl-2 pr-3.5 transition hover:border-ink"
                    aria-haspopup="menu"
                    aria-expanded={open}
                  >
                    {me.avatarUrl ? (
                      <img src={me.avatarUrl} alt="" className="h-7 w-7 rounded-full" />
                    ) : (
                      <span className="grid h-7 w-7 place-items-center rounded-full bg-lime/40 text-xs font-bold">
                        {me.name.slice(0, 1)}
                      </span>
                    )}
                    <span className="max-w-24 truncate text-sm font-semibold">{me.name}</span>
                  </button>
                  {open && (
                    <div className="absolute right-0 top-full mt-2 w-48 rounded-xl border border-line bg-card p-1.5 shadow-xl shadow-ink/8">
                      <div className="px-3 py-2 text-xs text-muted">
                        {me.role === "admin" ? "관리자" : me.role === "staff" ? "직원" : me.role === "crew" ? "크루" : "회원"} 계정
                      </div>
                      {(me.role === "admin" || me.role === "staff") && (
                        <Link
                          to="/admin"
                          onClick={() => setOpen(false)}
                          className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper"
                        >
                          관리자 페이지
                        </Link>
                      )}
                      <button
                        onClick={() => {
                          void logout();
                          setOpen(false);
                        }}
                        className="block w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-red-600 hover:bg-paper"
                      >
                        로그아웃
                      </button>
                    </div>
                  )}
                </>
              ) : (
                <>
                  <button
                    onClick={() => setOpen(!open)}
                    className="rounded-full border border-line bg-card px-4.5 py-2 text-sm font-semibold transition hover:border-ink"
                    aria-haspopup="menu"
                    aria-expanded={open}
                  >
                    로그인
                  </button>
                  {open && (
                    <div className="absolute right-0 top-full mt-2 w-56 rounded-xl border border-line bg-card p-1.5 shadow-xl shadow-ink/8">
                      {providers.length === 0 ? (
                        <div className="px-3 py-2 text-sm text-muted">로그인 준비 중입니다</div>
                      ) : (
                        providers.map((p) => (
                          <a
                            key={p}
                            href={`/api/auth/${p}/start`}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-paper"
                          >
                            {PROVIDER_LABEL[p] ?? p}
                          </a>
                        ))
                      )}
                    </div>
                  )}
                </>
              )}
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}

import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import BrandLogo from "./BrandLogo";
import { type Me } from "../lib/api";
import { useLang } from "../lib/i18n";

export default function Header({ me, logout }: { me: Me; logout: () => Promise<void> }) {
  const [open, setOpen] = useState(false);
  // 기본이 다크다. 라이트를 고른 경우에만 html 에 light 클래스가 붙는다.
  const [dark, setDark] = useState(() => !document.documentElement.classList.contains("light"));
  const menuRef = useRef<HTMLLIElement>(null);
  const { lang, setLang, t } = useLang();

  const toggleTheme = () => {
    const next = !dark;
    setDark(next);
    document.documentElement.classList.toggle("light", !next);
    try {
      localStorage.setItem("theme", next ? "dark" : "light");
    } catch {
      /* ignore */
    }
  };

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
          <BrandLogo size={30} />
        </Link>
        <nav aria-label="주 메뉴">
          <ul className="flex items-center gap-6 text-[15px] font-medium">
            <li className="hidden sm:block">
              <Link className="text-muted transition hover:text-ink" to="/#apps">{t("nav.apps")}</Link>
            </li>
            <li className="hidden sm:block">
              <Link className="text-muted transition hover:text-ink" to="/#about">{t("nav.about")}</Link>
            </li>
            <li className="hidden sm:block">
              <Link className="text-muted transition hover:text-ink" to="/ai-edu">{t("nav.edu")}</Link>
            </li>
            <li className="hidden sm:block">
              <Link className="text-muted transition hover:text-ink" to="/techdex?tab=dex">{t("nav.terms")}</Link>
            </li>
            {me && (
              <li className="hidden sm:block">
                <Link className="text-muted transition hover:text-ink" to="/app-plan">{t("nav.plan")}</Link>
              </li>
            )}
            {me && (me.role === "crew" || me.role === "staff" || me.role === "admin") && (
              <>
                <li className="hidden sm:block">
                  <Link className="font-semibold text-green transition hover:text-green-deep" to="/crew">
                    {t("nav.gallery")}
                  </Link>
                </li>
                <li className="hidden sm:block">
                  <Link className="text-muted transition hover:text-ink" to="/appreview">
                    {t("nav.review")}
                  </Link>
                </li>
              </>
            )}
            <li className="hidden sm:block">
              <Link
                className="rounded-full bg-ink px-4.5 py-2 font-semibold text-white transition hover:bg-green"
                to="/contact"
              >
                {t("nav.contact")}
              </Link>
            </li>
            <li>
              <button
                onClick={() => setLang(lang === "ko" ? "en" : "ko")}
                title={t("lang.toggle")}
                aria-label={t("lang.toggle")}
                className="rounded-full border border-line bg-card px-3 py-1.5 text-xs font-bold tracking-wide transition hover:border-ink"
              >
                <span className={lang === "en" ? "text-ink" : "text-muted"}>EN</span>
                <span className="mx-1 text-muted">|</span>
                <span className={lang === "ko" ? "text-ink" : "text-muted"}>KO</span>
              </button>
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
                        {me.role === "admin" ? "관리자" : me.role === "staff" ? "직원" : me.role === "crew" ? "앱튜버" : "회원"} 계정
                      </div>
                      {/* 모바일에선 상단 메뉴가 숨겨지므로 프로필 메뉴에서 이동 */}
                      <Link
                        to="/#apps"
                        onClick={() => setOpen(false)}
                        className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper sm:hidden"
                      >
                        앱
                      </Link>
                      <Link
                        to="/ai-edu"
                        onClick={() => setOpen(false)}
                        className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper sm:hidden"
                      >
                        AI교육
                      </Link>
                      <Link
                        to="/techdex?tab=dex"
                        onClick={() => setOpen(false)}
                        className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper sm:hidden"
                      >
                        용어검색
                      </Link>
                      <Link
                        to="/app-plan"
                        onClick={() => setOpen(false)}
                        className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper"
                      >
                        앱기획
                      </Link>
                      {(me.role === "crew" || me.role === "staff" || me.role === "admin") && (
                        <>
                          <Link
                            to="/crew"
                            onClick={() => setOpen(false)}
                            className="block rounded-lg px-3 py-2 text-sm font-medium text-green hover:bg-paper sm:hidden"
                          >
                            앱튜버갤러리
                          </Link>
                          <Link
                            to="/appreview"
                            onClick={() => setOpen(false)}
                            className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper"
                          >
                            앱 리뷰 분석
                          </Link>
                        </>
                      )}
                      <Link
                        to="/contact"
                        onClick={() => setOpen(false)}
                        className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper sm:hidden"
                      >
                        개발 문의
                      </Link>
                      {(me.role === "admin" || me.role === "staff") && (
                        <Link
                          to="/admin"
                          onClick={() => setOpen(false)}
                          className="block rounded-lg px-3 py-2 text-sm font-medium hover:bg-paper"
                        >
                          {t("nav.admin")}
                        </Link>
                      )}
                      <button
                        onClick={() => {
                          void logout();
                          setOpen(false);
                        }}
                        className="block w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-red-600 hover:bg-paper"
                      >
                        {t("nav.logout")}
                      </button>
                    </div>
                  )}
                </>
              ) : (
                <Link
                  to="/login"
                  className="rounded-full border border-line bg-card px-4.5 py-2 text-sm font-semibold transition hover:border-ink"
                >
                  {t("nav.login")}
                </Link>
              )}
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}

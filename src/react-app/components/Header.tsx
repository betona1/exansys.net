import { useEffect, useRef, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import BrandLogo from "./BrandLogo";
import { type Me } from "../lib/api";
import { useLang } from "../lib/i18n";

/** 지금 보고 있는 메뉴에 밑줄을 그어 어디에 있는지 알려준다.
 *  해시 링크(/#apps)는 홈에 있을 때만, 경로 링크는 그 경로로 들어갔을 때 활성이다. */
function NavItem({
  to,
  label,
  active,
  accent = false,
}: {
  to: string;
  label: string;
  active: boolean;
  accent?: boolean;
}) {
  return (
    <Link
      to={to}
      aria-current={active ? "page" : undefined}
      className={`relative py-1 transition after:absolute after:-bottom-0.5 after:left-0 after:h-0.5 after:rounded-full after:bg-green after:transition-all after:content-[''] ${
        active
          ? "font-semibold text-ink after:w-full"
          : `after:w-0 hover:after:w-full ${accent ? "font-semibold text-green hover:text-green-deep" : "text-muted hover:text-ink"}`
      }`}
    >
      {label}
    </Link>
  );
}

/** 드롭다운 항목 — 현재 위치면 배경과 왼쪽 막대로 표시한다 */
function dropClass(active: boolean, accent = false): string {
  const base = "block rounded-lg px-3 py-2 text-sm font-medium transition";
  if (active) return `${base} border-l-2 border-green bg-green/10 font-semibold text-ink`;
  return `${base} hover:bg-paper ${accent ? "text-green" : ""}`;
}

export default function Header({ me, logout }: { me: Me; logout: () => Promise<void> }) {
  const { pathname, hash } = useLocation();
  const onHome = pathname === "/";
  /** 경로 링크: 해당 경로로 들어와 있으면 활성 */
  const at = (p: string) => pathname === p || pathname.startsWith(p + "/");
  /** 해시 링크: 홈에서 그 섹션을 보고 있을 때 활성 */
  const atHash = (h: string) => onHome && hash === h;
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
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-5">
        <Link to="/" aria-label="EXANSYS 홈">
          <BrandLogo size={30} />
        </Link>
        <nav aria-label="주 메뉴" className="min-w-0">
          <ul className="flex items-center gap-4 overflow-x-auto whitespace-nowrap text-[14px] font-medium [scrollbar-width:none] lg:gap-5 [&::-webkit-scrollbar]:hidden">
            <li className="hidden sm:block">
              <NavItem to="/#apps" label={t("nav.apps")} active={atHash("#apps")} />
            </li>
            <li className="hidden sm:block">
              <NavItem to="/#about" label={t("nav.about")} active={atHash("#about")} />
            </li>
            <li className="hidden xl:block">
              <NavItem to="/ai-edu" label={t("nav.edu")} active={at("/ai-edu")} />
            </li>
            <li className="hidden xl:block">
              <NavItem to="/techdex?tab=dex" label={t("nav.terms")} active={at("/techdex")} />
            </li>
            {me && (
              <li className="hidden md:block">
                <NavItem to="/app-plan" label={t("nav.plan")} active={at("/app-plan")} />
              </li>
            )}
            {me && (me.role === "crew" || me.role === "staff" || me.role === "admin") && (
              <>
                <li className="hidden md:block">
                  <NavItem to="/crew" label={t("nav.gallery")} active={at("/crew")} accent />
                </li>
                <li className="hidden md:block">
                  <NavItem to="/appreview" label={t("nav.review")} active={at("/appreview")} />
                </li>
              </>
            )}
            <li className="hidden sm:block">
              <Link
                aria-current={at("/contact") ? "page" : undefined}
                className={`rounded-full px-4.5 py-2 font-semibold transition ${
                  at("/contact")
                    ? "bg-green text-white ring-2 ring-green/40 ring-offset-2 ring-offset-paper"
                    : "bg-ink text-white hover:bg-green"
                }`}
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
            {/* 관리자 단추는 프로필 메뉴 안에 묻지 않는다.
                묻어 두면 관리자조차 관리 화면이 있는 줄 모른다 */}
            {(me?.role === "admin" || me?.role === "staff") && (
              <li>
                <Link
                  to="/admin"
                  title={me.role === "admin" ? "관리자" : "직원"}
                  className={`flex items-center gap-1.5 rounded-full px-3.5 py-2 text-sm font-semibold transition ${
                    at("/admin")
                      ? "bg-ink text-white"
                      : "border border-green/40 bg-green/10 text-green-deep hover:bg-green/20"
                  }`}
                >
                  <span aria-hidden>⚙</span>
                  <span className="hidden sm:inline">{t("nav.admin")}</span>
                </Link>
              </li>
            )}
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
                    <span className="hidden max-w-24 truncate text-sm font-semibold sm:inline">{me.name}</span>
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
                        {t("nav.apps")}
                      </Link>
                      <Link
                        to="/ai-edu"
                        onClick={() => setOpen(false)}
                        className={`${dropClass(at("/ai-edu"))} xl:hidden`}
                      >
                        {t("nav.edu")}
                      </Link>
                      <Link
                        to="/techdex?tab=dex"
                        onClick={() => setOpen(false)}
                        className={`${dropClass(at("/techdex"))} xl:hidden`}
                      >
                        {t("nav.terms")}
                      </Link>
                      <Link
                        to="/app-plan"
                        onClick={() => setOpen(false)}
                        className={dropClass(at("/app-plan"))}
                      >
                        {t("nav.plan")}
                      </Link>
                      {(me.role === "crew" || me.role === "staff" || me.role === "admin") && (
                        <>
                          <Link
                            to="/crew"
                            onClick={() => setOpen(false)}
                            className={dropClass(at("/crew"), true)}
                          >
                            {t("nav.gallery")}
                          </Link>
                          <Link
                            to="/appreview"
                            onClick={() => setOpen(false)}
                            className={dropClass(at("/appreview"))}
                          >
                            {t("nav.review")}
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

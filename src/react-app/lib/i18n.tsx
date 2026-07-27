// 영어 기본 + 한글 전환.
//
// 범위는 방문자가 보는 얼굴 — 홈·소개·앱 소개·헤더·푸터다. 게시판·앱기획·관리자 같은
// 내부 기능은 한글 그대로 둔다. 문구를 여기 한곳에 모아 두면 새 문장을 추가할 때
// 두 벌을 같이 쓰게 되어 한쪽만 빠지는 일이 없다.
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

export type Lang = "en" | "ko";

const STORAGE_KEY = "lang";

/** 문구 사전 — 값이 [영어, 한글] 쌍이다 */
const DICT = {
  // ── 헤더 ──
  "nav.apps": ["Apps", "앱"],
  "nav.about": ["About", "소개"],
  "nav.edu": ["AI Edu", "AI교육"],
  "nav.terms": ["Glossary", "용어검색"],
  "nav.plan": ["App Planner", "앱기획"],
  "nav.gallery": ["Builders Gallery", "앱튜버갤러리"],
  "nav.review": ["App Review", "앱리뷰"],
  "nav.contact": ["Contact", "개발 문의"],
  "nav.login": ["Sign in", "로그인"],
  "nav.logout": ["Sign out", "로그아웃"],
  "nav.admin": ["Admin", "관리자"],

  // ── 히어로 ──
  "hero.featured": ["FEATURED APP", "대표 앱"],
  "hero.viewApps": ["See our apps", "우리 앱 보기"],
  "hero.playVideo": ["Watch the film", "홍보영상 보기"],
  "hero.contact": ["Start a project", "개발 문의하기"],
  "hero.scroll": ["SCROLL DOWN ↓", "SCROLL DOWN ↓"],
  "hero.fallbackTagline": [
    "Apps built to be opened every day.",
    "매일 열게 되는 앱을 만듭니다.",
  ],

  // ── 슬로건 ──
  "slogan.main": ["THINK AT EXA SCALE.", "THINK AT EXA SCALE."],
  "slogan.sub": [
    "One app at a time — engineered at exa scale.",
    "하나의 앱을, 엑사 규모의 기준으로.",
  ],

  // ── 갤러리 ──
  "gallery.label": ["OUR APPS", "OUR APPS"],
  "gallery.line1": ["Everything we build,", "우리가 만든 앱을"],
  "gallery.accent": ["in one place.", "영상으로 보세요"],
  "gallery.all": ["All", "전체"],
  "gallery.watch": ["Film", "영상"],
  "gallery.details": ["View details", "자세히 보기"],
  "gallery.visitStore": ["Get it on the store", "스토어에서 보기"],
  "gallery.copyLink": ["Copy share link", "공유 링크 복사"],
  "gallery.copied": ["Copied ✓", "복사됨 ✓"],
  "gallery.inquiry": ["Work with us", "협업 문의하기"],
  "gallery.noVideo": ["Film coming soon", "홍보영상 준비 중"],
  "gallery.empty": ["No apps published yet.", "아직 등록된 앱이 없습니다."],

  // ── 소개 ──
  "about.headline1": [
    "Built by a team that has kept systems running",
    "2016년부터 시스템을 지켜온 팀이 만드는",
  ],
  "about.headline2": ["since 2016.", "신뢰할 수 있는 앱"],
  "about.body": [
    "We are building apps for the start and the end of your day.\nTen years of infrastructure discipline, carried straight into mobile.",
    "하루의 시작과 끝에 함께할 앱을 준비하고 있습니다.\n10년의 IT 인프라 운영 규율을 그대로 모바일에 담습니다.",
  ],
  "stats.founded": ["Founded in Seoul", "서울에서 창립"],
  "stats.experience": ["Years in IT systems & infrastructure", "IT 시스템·인프라 경력 (년)"],
  "stats.projects": ["Projects in progress", "진행 중인 프로젝트"],

  // ── 크래프트 ──
  "craft.label": ["OUR CRAFT", "OUR CRAFT"],
  "craft.line1": ["Good apps are the ones", "오래 쓰여야"],
  "craft.accent": ["you keep using.", "좋은 앱이니까"],

  // ── 문의 ──
  "contact.title": ["Have an app in mind?", "함께 만들 앱이 있나요?"],
  "contact.body": [
    "Questions about our apps, partnerships, a project you want built — we reply to every message.",
    "앱에 대한 질문, 파트너십, 만들고 싶은 프로젝트 — 모든 메일에 답장합니다.",
  ],
  "contact.board": ["Go to the inquiry board →", "문의 게시판 가기 →"],


  // ── 출시 배너 ──
  "banner.new": ["🎉 NEW RELEASE", "🎉 새 앱 출시"],
  "banner.getPlay": ["Get it on Google Play", "Google Play에서 받기"],
  "banner.qrAlt": ["Google Play install QR code", "Google Play 설치 QR 코드"],
  "banner.scan": ["📷 Scan with your phone to install", "📷 폰으로 스캔하면 바로 설치"],

  // ── 원칙 ──
  "craft.1.title": ["No ads. Ever.", "광고 없음, 영원히"],
  "craft.1.body": [
    "No ads, no dark patterns — honest pricing only. We will not start your morning with an advertisement.",
    "광고와 다크 패턴 없이 정직한 가격으로만 운영합니다. 사용자의 아침을 광고로 시작하게 하지 않습니다.",
  ],
  "craft.2.title": ["Offline first", "오프라인 우선"],
  "craft.2.body": [
    "Opens and works with no network. Speed is not negotiable.",
    "네트워크가 없어도 바로 열리고 바로 쓰입니다. 빠른 실행 속도는 협상하지 않습니다.",
  ],
  "craft.3.title": ["Shipping is the start", "출시 후가 진짜"],
  "craft.3.body": [
    "With ten years of infrastructure discipline, what we ship keeps getting updated and maintained.",
    "10년간 인프라를 지켜온 규율로, 출시한 앱은 꾸준히 업데이트하고 관리합니다.",
  ],

  // ── 공지·게시판 ──
  "notice.title": ["Notices", "공지"],
  "board.title": ["Project inquiry board", "개발 문의게시판"],
  "board.body": [
    "We take app and partnership inquiries on the board. Private posts are supported, and every inquiry gets a reply.",
    "앱 외주 개발·파트너십 문의를 게시판으로 받습니다. 비공개 글도 지원하며, 모든 문의에 답변합니다.",
  ],

  // ── FAQ ──
  "faq.line1": ["Frequently asked", "자주 묻는"],
  "faq.accent": ["questions.", "질문들"],
  "faq.q1": ["What is EXANSYS?", "EXANSYS는 어떤 회사인가요?"],
  "faq.a1": [
    "A mobile app studio founded in Seoul in 2016. We spent ten years on computer systems maintenance and network infrastructure, and now bring that sense of reliability to mobile apps.",
    "2016년 서울에서 창립한 모바일 앱 전문 개발사입니다. 10년간 컴퓨터 시스템 유지보수와 통신망 구축 등 IT 인프라를 다뤄왔고, 지금은 그 신뢰성의 감각으로 모바일 앱을 만드는 데 집중하고 있습니다.",
  ],
  "faq.q2": ["When does the first app ship?", "첫 앱은 언제 출시되나요?"],
  "faq.a2": [
    "We are building a daily productivity companion targeting a 2026 release. Release news lands here first.",
    "데일리 생산성 컴패니언 앱을 2026년 출시 목표로 개발하고 있습니다. 출시 소식은 이 홈페이지 공지에서 가장 먼저 알려드립니다.",
  ],
  "faq.q3": ["Do you build apps for clients?", "앱 외주 개발도 하나요?"],
  "faq.a3": [
    "Yes — from shaping the idea through planning, design, development and store launch. Tell us what you want to build at the email below.",
    "네. 아이디어 정리부터 기획·디자인·개발·스토어 출시까지 전 과정을 함께합니다. 아래 이메일로 만들고 싶은 앱을 알려주세요.",
  ],
  "faq.q4": ["Are the apps really ad-free?", "앱은 정말 광고가 없나요?"],
  "faq.a4": [
    "Yes. Apps we build ourselves carry no ads and no dark patterns. When a business model is needed, it is an honest subscription or purchase.",
    "네. 저희가 직접 만드는 앱에는 광고와 다크 패턴을 넣지 않습니다. 필요한 경우 정직한 구독/구매 모델로만 운영합니다.",
  ],
  "faq.q5": ["Where are the privacy policies?", "출시된 앱의 개인정보처리방침은 어디서 보나요?"],
  "faq.a5": [
    "Each app detail page publishes it as a public document, and the same link is registered on Google Play and the App Store.",
    "각 앱 상세 페이지에서 공개 문서로 제공합니다. Google Play·App Store 등록 정보에서도 같은 링크를 확인할 수 있습니다.",
  ],

  // ── 언어 토글 ──
  "lang.toggle": ["한국어로 보기", "View in English"],
} as const;

export type MsgKey = keyof typeof DICT;

function readLang(): Lang {
  try {
    return localStorage.getItem(STORAGE_KEY) === "ko" ? "ko" : "en";
  } catch {
    return "en";
  }
}

type Ctx = { lang: Lang; setLang: (l: Lang) => void; t: (k: MsgKey) => string };

const LangContext = createContext<Ctx>({ lang: "en", setLang: () => {}, t: (k) => DICT[k][0] });

export function LangProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLangState] = useState<Lang>(readLang);

  useEffect(() => {
    document.documentElement.lang = lang;
  }, [lang]);

  const setLang = useCallback((l: Lang) => {
    setLangState(l);
    try {
      localStorage.setItem(STORAGE_KEY, l);
    } catch {
      /* ignore */
    }
  }, []);

  const t = useCallback((k: MsgKey) => DICT[k][lang === "ko" ? 1 : 0], [lang]);

  const value = useMemo(() => ({ lang, setLang, t }), [lang, setLang, t]);
  return <LangContext.Provider value={value}>{children}</LangContext.Provider>;
}

export function useLang(): Ctx {
  return useContext(LangContext);
}

/** 영어/한글 두 벌이 있는 데이터에서 현재 언어를 고른다 */
export function pick(lang: Lang, en: string | null | undefined, ko: string | null | undefined) {
  const a = lang === "ko" ? ko : en;
  return (a ?? en ?? ko ?? "").trim();
}

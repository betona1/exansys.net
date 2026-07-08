// Phase 1: 정적 데이터. Phase 2부터 D1 + /api 로 대체된다.

export type AppStatus = "development" | "planning" | "available";

export const APPS: {
  name: string;
  emoji: string;
  tint: string;
  description: string;
  status: AppStatus;
  statusLabel: string;
}[] = [
  {
    name: "첫 번째 앱 (가칭)",
    emoji: "📱",
    tint: "rgba(14,87,65,0.10)",
    description:
      "매일 쓰는 생산성 컴패니언. 오프라인 우선, 광고 없음, 다크 패턴 없음 — 2026년 출시를 목표로 개발 중입니다.",
    status: "development",
    statusLabel: "개발 중 · 2026 출시 목표",
  },
  {
    name: "유틸리티 라인",
    emoji: "🛠️",
    tint: "rgba(155,225,93,0.18)",
    description:
      "한 가지 일을 아주 잘하는 가벼운 단일 목적 도구들. 빨리 열리고, 바로 쓰고, 믿을 수 있게.",
    status: "planning",
    statusLabel: "기획 중",
  },
  {
    name: "맞춤 앱 개발",
    emoji: "🤝",
    tint: "rgba(39,66,245,0.08)",
    description:
      "비즈니스에 필요한 앱을 아이디어부터 스토어 출시까지. 기획·디자인·개발·런칭을 함께합니다.",
    status: "available",
    statusLabel: "의뢰 가능",
  },
];

export const NOTICES = [
  { date: "2026-07", text: "exansys.net 홈페이지 리뉴얼을 진행하고 있습니다." },
  { date: "2026-07", text: "앱 쇼케이스·문의게시판 기능을 준비 중입니다." },
  { date: "2026", text: "첫 자체 앱을 2026년 출시 목표로 개발하고 있습니다." },
];

export const STATS = [
  { value: 2016, label: "서울에서 창립", plain: true },
  { value: 10, suffix: "+", label: "IT 시스템·인프라 경력 (년)" },
  { value: 3, suffix: "", label: "진행 중인 프로젝트" },
];

export const COMPANY = {
  nameEn: "EXANSYS Co., Ltd.",
  nameKo: "(주)엑사엔시스",
  ceo: "Seongwook Lee",
  bizNo: "587-86-00398",
  addressEn: "16 Myeonmok-ro 74-gil, 3F #317, Jungnang-gu, Seoul, Republic of Korea",
  email: "contact@exansys.net",
};

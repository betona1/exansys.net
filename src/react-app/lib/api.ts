export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };

export async function api<T>(path: string, init?: RequestInit): Promise<ApiResult<T>> {
  try {
    const res = await fetch(path, {
      credentials: "same-origin",
      headers: init?.body ? { "Content-Type": "application/json" } : undefined,
      ...init,
    });
    return (await res.json()) as ApiResult<T>;
  } catch {
    return { ok: false, error: "network_error" };
  }
}

export type Me = {
  id: number;
  name: string;
  avatarUrl: string | null;
  role: "member" | "crew" | "staff" | "admin";
  provider: string;
} | null;

export type AppRow = {
  id: number;
  slug: string;
  name: string;
  tagline: string | null;
  description?: string | null;
  iconUrl: string | null;
  status: "planning" | "development" | "released";
  downloadCount: number;
  storeUrlAndroid: string | null;
  storeUrlIos: string | null;
};

export const STATUS_LABEL: Record<AppRow["status"], string> = {
  planning: "기획 중",
  development: "개발 중",
  released: "출시됨",
};

// ── App Review 분석 ──
export type StoreKind = "play" | "apple";

export type AppHit = {
  store: StoreKind;
  appId: string;
  title: string;
  iconUrl: string | null;
  score: number | null;
  ratings: number | null;
  installs: string | null;
  realInstalls: number | null;
  developer: string | null;
  url: string | null;
};

export type ReviewItem = {
  score: number;
  content: string;
  at: number | null;
  thumbsUp: number;
  userName: string | null;
  version: string | null;
};

export type KeywordCount = { word: string; count: number };

export type ReviewAnalysis = {
  total: number;
  avgScore: number;
  distribution: number[];
  distributionPct: number[];
  positive: number;
  neutral: number;
  negative: number;
  negativeRate: number;
  avgThumbsUp: number;
  complaintKeywords: KeywordCount[];
  praiseKeywords: KeywordCount[];
  monthlyTrend: { month: string; count: number; avg: number }[];
  versionBreakdown: { version: string; count: number; avg: number }[];
};

export type CollectResult = {
  cached: boolean;
  fetchedAt: number;
  app: {
    store: StoreKind;
    appId: string;
    region: string;
    title: string;
    iconUrl: string | null;
    score: number | null;
    ratings: number | null;
    installs: string | null;
    realInstalls: number | null;
    reviewCount: number;
    fetchedAt: number;
  };
  reviews: ReviewItem[];
  analysis: ReviewAnalysis;
};

export const REVIEW_REGIONS: { code: string; label: string }[] = [
  { code: "kr", label: "한국" },
  { code: "us", label: "미국" },
  { code: "jp", label: "일본" },
  { code: "gb", label: "영국" },
  { code: "de", label: "독일" },
  { code: "in", label: "인도" },
  { code: "vn", label: "베트남" },
  { code: "sg", label: "싱가포르" },
  { code: "tw", label: "대만" },
  { code: "hk", label: "홍콩" },
  { code: "ru", label: "러시아" },
];

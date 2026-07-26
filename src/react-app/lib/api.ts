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
  ownerId?: number | null; // 관리자 목록(/api/admin/apps-list)에서만 채워짐
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

// ── AI교육 게시판 ──
export type EduKind = "html" | "image" | "pdf" | "link";

export type EduPostCard = {
  id: number;
  title: string;
  createdAt: string;
  authorName: string | null;
  authorAvatar: string | null;
  thumbnail: string | null;
  kinds: EduKind[];
  commentCount: number;
};

export type EduAttachment = {
  id: number;
  kind: EduKind;
  name: string;
  size: number | null;
  src: string | null;
};

export type EduComment = {
  id: number;
  body: string;
  createdAt: string;
  userId: number;
  authorName: string | null;
  authorAvatar: string | null;
  mine: boolean;
};

export type EduPostDetail = {
  post: {
    id: number;
    userId: number;
    title: string;
    body: string | null;
    createdAt: string;
    updatedAt: string;
    authorName: string | null;
    authorAvatar: string | null;
  };
  attachments: EduAttachment[];
  comments: EduComment[];
  canComment: boolean;
  canManage: boolean;
};

// ── TechDex (용어 학습 게임) ──
export type TechdexCollection = "ai" | "app" | "vibe" | "user";

export type TechdexSuggestion = {
  id: number;
  term: string;
  sub: string | null;
  def: string | null;
  category: string | null;
  note: string | null;
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  userName?: string | null;
};

export type TechdexTerm = {
  id: number;
  slug: string;
  term: string;
  sub: string | null;
  def: string;
  collection: TechdexCollection;
  category: string;
  difficulty: number;
  vibeCore: boolean;
};

export type TechdexQuizQuestion = {
  slug: string;
  prompt: string;
  choices: string[];
  answer: string;
  answerIndex: number;
  reveal: { term: string; sub: string | null; category: string; collection: TechdexCollection };
};

export type TechdexStats = {
  total: number;
  byCollection: { collection: TechdexCollection; count: number }[];
  vibeCore: number;
};

export type CrosswordEntry = {
  num: number;
  row: number;
  col: number;
  dir: "across" | "down";
  answer: string;
  len: number;
  clue: string;
  term: string;
  sub: string | null;
};
export type CrosswordPuzzle = { rows: number; cols: number; entries: CrosswordEntry[] };

export type TechdexMyStats = {
  streak: number;
  bestStreak: number;
  freezes: number;
  xp: number;
  level: number;
  lastDailyDate: string | null;
  today: string;
  badges: string[];
};
export type TechdexProgress = {
  stats: { streak: number; bestStreak: number; freezes: number; xp: number; level: number; lastDailyDate: string | null };
  gainedXp: number;
  streakEvent: string;
  newBadges: string[];
};

export const TECHDEX_BADGES: Record<string, { emoji: string; label: string }> = {
  onboard: { emoji: "🌱", label: "첫 발걸음" },
  first_correct: { emoji: "✅", label: "첫 정답" },
  streak3: { emoji: "🔥", label: "3일 연속" },
  streak10: { emoji: "🔥", label: "10일 연속" },
  streak30: { emoji: "🏅", label: "30일 연속" },
  streak100: { emoji: "🏆", label: "100일 연속" },
  level5: { emoji: "⭐", label: "레벨 5" },
  level10: { emoji: "🌟", label: "레벨 10" },
};

// XP → 레벨 명칭 (용어 테마)
export const TECHDEX_LEVEL_TITLES = ["뉴비", "프롬프트 유저", "컨텍스트 러너", "하네스 빌더", "에이전트 마스터"];
export function techdexLevelTitle(level: number): string {
  return TECHDEX_LEVEL_TITLES[Math.min(TECHDEX_LEVEL_TITLES.length - 1, Math.floor((level - 1) / 3))];
}

export const TECHDEX_COLLECTION_LABEL: Record<TechdexCollection, string> = {
  ai: "AI·앱 용어",
  app: "앱 개발 용어",
  vibe: "바이브코딩 용어",
  user: "사용자 추가",
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

// ── 앱기획 (AppCompass) ──
export type PlanDimensionCode =
  | "D01" | "D02" | "D03" | "D04" | "D05"
  | "D06" | "D07" | "D08" | "D09" | "D10";

export type PlanEvidenceType =
  | "FOUNDER_ASSUMPTION"
  | "DESK_RESEARCH"
  | "USER_INTERVIEW"
  | "PROTOTYPE_TEST"
  | "BEHAVIOR_DATA"
  | "EXPERT_REVIEW";

export type PlanPivotDecision =
  | "KEEP" | "REFINE" | "TARGET_PIVOT" | "PROBLEM_PIVOT" | "SOLUTION_PIVOT"
  | "CHANNEL_PIVOT" | "REVENUE_PIVOT" | "RETENTION_REDESIGN" | "HOLD";

export type PlanStage = "IDEA" | "RESEARCH" | "PROTOTYPE" | "MVP" | "LIVE" | "PAUSED" | "ARCHIVED";

export const PLAN_STAGE_LABEL: Record<PlanStage, string> = {
  IDEA: "아이디어",
  RESEARCH: "리서치",
  PROTOTYPE: "프로토타입",
  MVP: "MVP",
  LIVE: "운영 중",
  PAUSED: "중단",
  ARCHIVED: "보관",
};

export const PLAN_EVIDENCE_LABEL: Record<PlanEvidenceType, string> = {
  FOUNDER_ASSUMPTION: "창업자 가정",
  DESK_RESEARCH: "데스크리서치",
  USER_INTERVIEW: "사용자 인터뷰",
  PROTOTYPE_TEST: "프로토타입 테스트",
  BEHAVIOR_DATA: "행동 데이터",
  EXPERT_REVIEW: "전문가 검토",
};

// 근거 유형별 기본 신뢰도 (표시용 — 실제 계산은 서버 규칙 엔진이 한다)
export const PLAN_EVIDENCE_CONFIDENCE: Record<PlanEvidenceType, number> = {
  FOUNDER_ASSUMPTION: 0.2,
  DESK_RESEARCH: 0.35,
  USER_INTERVIEW: 0.5,
  PROTOTYPE_TEST: 0.7,
  BEHAVIOR_DATA: 1.0,
  EXPERT_REVIEW: 0.45,
};

export const PLAN_PIVOT_LABEL: Record<PlanPivotDecision, string> = {
  KEEP: "유지",
  REFINE: "보완",
  TARGET_PIVOT: "타깃 피벗",
  PROBLEM_PIVOT: "문제 피벗",
  SOLUTION_PIVOT: "해결책 피벗",
  CHANNEL_PIVOT: "채널 피벗",
  REVENUE_PIVOT: "수익 피벗",
  RETENTION_REDESIGN: "재방문 재설계",
  HOLD: "판단 보류",
};

export const PLAN_DIMENSION_LABEL: Record<PlanDimensionCode, string> = {
  D01: "문제 구체성",
  D02: "문제 강도·빈도",
  D03: "타깃 명확성",
  D04: "사용자·구매자 구분",
  D05: "가치 제안",
  D06: "첫 성공 경험",
  D07: "반복 사용 이유",
  D08: "차별성",
  D09: "유입 가능성",
  D10: "구현 가능성",
};

export const PLAN_DIMENSION_CODES: PlanDimensionCode[] = [
  "D01", "D02", "D03", "D04", "D05", "D06", "D07", "D08", "D09", "D10",
];

export type PlanProjectSummary = {
  id: number;
  appName: string;
  stage: PlanStage;
  status: string;
  createdAt: number;
  updatedAt: number;
  latest: {
    totalScore: number;
    overallConfidence: number;
    decision: PlanPivotDecision;
    createdAt: number;
  } | null;
};

export type PlanProject = {
  id: number;
  userId: number;
  appName: string;
  stage: PlanStage;
  status: string;
  rawIdea: string | null;
  targetUserRaw: string | null;
  problemRaw: string | null;
  solutionRaw: string | null;
  revenueModelRaw: string | null;
  distributionChannelRaw: string | null;
  targetUser: string | null;
  payer: string | null;
  influencer: string | null;
  problemSituation: string | null;
  currentSolution: string | null;
  currentSolutionProblem: string | null;
  coreAction: string | null;
  expectedResult: string | null;
  firstSuccess: string | null;
  retentionReason: string | null;
  revenueModel: string | null;
  distributionChannel: string | null;
  aiAssistedAt: number | null;
  aiModel: string | null;
  createdAt: number;
  updatedAt: number;
};

export type PlanEvidence = {
  id: number;
  evidenceType: PlanEvidenceType;
  title: string;
  summary: string;
  sourceReference: string | null;
  sampleSize: number | null;
  confidenceOverride: number | null;
  supports: PlanDimensionCode[];
  contradicts: PlanDimensionCode[];
};

export type PlanDimensionScore = {
  code: PlanDimensionCode;
  label: string;
  rawScore: number;
  weight: number;
  normalizedScore: number;
  reason: string;
  missingEvidence: string[];
  recommendedAction: string;
  confidence: number;
};

export type PlanWarning = {
  code: string;
  message: string;
  severity: "INFO" | "WARN" | "CRITICAL";
  field: string | null;
  recommendedAction: string;
};

export type PlanTargetCandidate = {
  name: string;
  user: string;
  payer: string | null;
  influencer: string | null;
  triggerSituation: string;
  problem: string;
  currentAlternative: string | null;
  whyPromising: string[];
  risks: string[];
  validationQuestions: string[];
  recommendedExperiment: string;
};

export type PlanAnalysisResult = {
  meta: {
    engine: string;
    engineVersion: string;
    policyVersion: string;
    schemaVersion: string;
    createdAt: string;
    modelProvider: string | null;
    modelName: string | null;
  };
  diagnosis: {
    totalScore: number;
    overallConfidence: number;
    dimensions: PlanDimensionScore[];
    warnings: PlanWarning[];
    criticalRisks: string[];
    unknowns: string[];
  };
  targets: {
    candidates: PlanTargetCandidate[];
    recommendedCandidateIndex: number | null;
    recommendationReason: string;
  };
  mvp: {
    coreHypothesis: string;
    problemHypothesis: string;
    behaviorHypothesis: string;
    valueHypothesis: string;
    retentionHypothesis: string;
    revenueHypothesis: string | null;
    p0Features: string[];
    p1Features: string[];
    excludedFeatures: string[];
    firstSuccessExperience: string;
    coreUserFlow: string[];
    metrics: string[];
    risks: string[];
  };
  pivot: {
    decision: PlanPivotDecision;
    confidence: number;
    reasonCodes: string[];
    rationale: string;
    wouldBeDecision: PlanPivotDecision | null;
    keep: string[];
    change: string[];
    remove: string[];
    nextActions: string[];
    requiresHumanApproval: boolean;
  };
  nextActions: string[];
};

export type PlanHistoryItem = {
  id: number;
  totalScore: number;
  overallConfidence: number;
  decision: PlanPivotDecision;
  wouldBeDecision: PlanPivotDecision | null;
  createdAt: number;
};

export type PlanDetail = {
  project: PlanProject;
  evidence: PlanEvidence[];
  latestResult: PlanAnalysisResult | null;
  history: PlanHistoryItem[];
};

/** AI 키는 브라우저 localStorage 에만 둔다. 서버 DB에는 절대 저장하지 않는다. */
const PLAN_KEY_STORAGE = "exansys.plan.anthropicKey";

export function getPlanApiKey(): string {
  try {
    return localStorage.getItem(PLAN_KEY_STORAGE) ?? "";
  } catch {
    return "";
  }
}

export function setPlanApiKey(key: string) {
  try {
    if (key.trim()) localStorage.setItem(PLAN_KEY_STORAGE, key.trim());
    else localStorage.removeItem(PLAN_KEY_STORAGE);
  } catch {
    /* ignore */
  }
}

/** 앱기획 AI 요청 — 사용자 본인 키를 헤더로만 전달한다 (요청 처리 후 서버에서 폐기) */
export async function planAi<T>(path: string, apiKey: string): Promise<ApiResult<T>> {
  try {
    const res = await fetch(path, {
      method: "POST",
      credentials: "same-origin",
      headers: { "Content-Type": "application/json", "x-anthropic-key": apiKey },
      body: "{}",
    });
    return (await res.json()) as ApiResult<T>;
  } catch {
    return { ok: false, error: "network_error" };
  }
}

export const PLAN_AI_ERROR_MESSAGE: Record<string, string> = {
  api_key_required: "API 키를 먼저 입력해 주세요.",
  invalid_api_key_format: "Anthropic API 키 형식이 아닙니다. sk-ant- 로 시작해야 합니다.",
  api_key_invalid: "API 키가 유효하지 않습니다. Anthropic 콘솔에서 다시 확인해 주세요.",
  api_key_forbidden: "이 API 키에는 해당 모델 권한이 없습니다.",
  api_rate_limited: "요청이 몰렸습니다. 잠시 후 다시 시도해 주세요.",
  ai_refused: "AI가 이 내용의 처리를 거절했습니다. 원문을 다시 확인해 주세요.",
  ai_output_truncated: "AI 응답이 잘렸습니다. 원문을 줄여서 다시 시도해 주세요.",
  ai_empty_response: "AI 응답이 비어 있습니다. 다시 시도해 주세요.",
  ai_request_failed: "AI 요청에 실패했습니다. 네트워크와 키를 확인해 주세요.",
};

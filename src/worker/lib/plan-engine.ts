// 앱기획 진단 규칙 엔진 — betona1/appcompass-ai 의 core 계층을 TypeScript로 포팅.
//
// 원칙(원본 ADR-0002 / ADR-0003 유지):
//  - 점수·신뢰도·피벗 판단은 전부 이 파일의 순수 함수가 결정한다. LLM은 관여하지 않는다.
//  - 같은 입력이면 항상 같은 출력이 나온다. now 를 주입받아 완전히 결정론적이다.
//  - AI는 구조화 초안만 도우며, 근거(Evidence)는 사람이 등록한 것만 존재한다.

// ─────────────────────────────────────────────────────────────
// Enum / 라벨
// ─────────────────────────────────────────────────────────────

export const DIMENSION_CODES = [
  "D01",
  "D02",
  "D03",
  "D04",
  "D05",
  "D06",
  "D07",
  "D08",
  "D09",
  "D10",
] as const;
export type DimensionCode = (typeof DIMENSION_CODES)[number];

export const DIMENSION_LABELS: Record<DimensionCode, string> = {
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

export const EVIDENCE_TYPES = [
  "FOUNDER_ASSUMPTION",
  "DESK_RESEARCH",
  "USER_INTERVIEW",
  "PROTOTYPE_TEST",
  "BEHAVIOR_DATA",
  "EXPERT_REVIEW",
] as const;
export type EvidenceType = (typeof EVIDENCE_TYPES)[number];

export const EVIDENCE_TYPE_LABELS: Record<EvidenceType, string> = {
  FOUNDER_ASSUMPTION: "창업자 가정",
  DESK_RESEARCH: "데스크리서치",
  USER_INTERVIEW: "사용자 인터뷰",
  PROTOTYPE_TEST: "프로토타입 테스트",
  BEHAVIOR_DATA: "행동 데이터",
  EXPERT_REVIEW: "전문가 검토",
};

export type Severity = "INFO" | "WARN" | "CRITICAL";

export type WarningCode =
  | "BROAD_TARGET"
  | "NO_TRIGGER_SITUATION"
  | "NO_CURRENT_ALTERNATIVE"
  | "NO_PAYER_DEFINED"
  | "NO_FIRST_SUCCESS"
  | "NO_RETENTION_REASON"
  | "NO_MEASURABLE_RESULT"
  | "FEATURE_FIRST_IDEA"
  | "UNSUPPORTED_CLAIM"
  | "LOW_EVIDENCE"
  | "CONFLICTING_EVIDENCE";

export type PivotDecision =
  | "KEEP"
  | "REFINE"
  | "TARGET_PIVOT"
  | "PROBLEM_PIVOT"
  | "SOLUTION_PIVOT"
  | "CHANNEL_PIVOT"
  | "REVENUE_PIVOT"
  | "RETENTION_REDESIGN"
  | "HOLD";

export const PIVOT_LABELS: Record<PivotDecision, string> = {
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

export const PROJECT_STAGES = [
  "IDEA",
  "RESEARCH",
  "PROTOTYPE",
  "MVP",
  "LIVE",
  "PAUSED",
  "ARCHIVED",
] as const;
export type ProjectStage = (typeof PROJECT_STAGES)[number];

// ─────────────────────────────────────────────────────────────
// 정책 (가중치·임계치) — 전역 상수로 흩뿌리지 않고 한 객체에 모은다
// ─────────────────────────────────────────────────────────────

export type EvaluationPolicy = {
  version: string;
  weights: Record<DimensionCode, number>; // 합계 100
  evidenceConfidence: Record<EvidenceType, number>;
  noEvidenceConfidenceCap: number;
  conflictPenalty: number;
  holdThreshold: number;
  problemPivotThreshold: number;
  targetPivotThreshold: number;
  solutionPivotThreshold: number;
  retentionPivotThreshold: number;
  channelPivotThreshold: number;
  revenuePivotThreshold: number;
  keepScoreThreshold: number;
};

export const DEFAULT_POLICY: EvaluationPolicy = {
  version: "policy-0.1.0",
  weights: {
    D01: 15,
    D02: 10,
    D03: 10,
    D04: 5,
    D05: 10,
    D06: 10,
    D07: 10,
    D08: 10,
    D09: 10,
    D10: 10,
  },
  evidenceConfidence: {
    FOUNDER_ASSUMPTION: 0.2,
    DESK_RESEARCH: 0.35,
    USER_INTERVIEW: 0.5,
    PROTOTYPE_TEST: 0.7,
    BEHAVIOR_DATA: 1.0,
    EXPERT_REVIEW: 0.45,
  },
  noEvidenceConfidenceCap: 0.2,
  conflictPenalty: 0.3,
  holdThreshold: 0.35,
  problemPivotThreshold: 2.0,
  targetPivotThreshold: 3.0,
  solutionPivotThreshold: 2.5,
  retentionPivotThreshold: 2.5,
  channelPivotThreshold: 2.0,
  revenuePivotThreshold: 2.0,
  keepScoreThreshold: 75.0,
};

export const ENGINE_NAME = "RULE_ENGINE";
export const ENGINE_VERSION = "0.1.0";
export const SCHEMA_VERSION = "analysis-result-0.1.0";

// ─────────────────────────────────────────────────────────────
// 값 객체
// ─────────────────────────────────────────────────────────────

export type IdeaStructure = {
  appName: string;
  targetUser: string;
  payer: string | null;
  influencer: string | null;
  problemSituation: string;
  currentSolution: string | null;
  currentSolutionProblem: string | null;
  coreAction: string;
  expectedResult: string;
  firstSuccess: string | null;
  retentionReason: string | null;
  revenueModel: string | null;
  distributionChannel: string | null;
};

export type EvidenceItem = {
  id: number;
  evidenceType: EvidenceType;
  title: string;
  summary: string;
  sourceReference: string | null;
  sampleSize: number | null;
  confidenceOverride: number | null;
  supports: DimensionCode[];
  contradicts: DimensionCode[];
};

export type DiagnosisWarning = {
  code: WarningCode;
  message: string;
  severity: Severity;
  field: string | null;
  recommendedAction: string;
};

export type DimensionScore = {
  code: DimensionCode;
  label: string;
  rawScore: number; // 0~5
  weight: number;
  normalizedScore: number; // (raw/5) * weight
  reason: string;
  missingEvidence: string[];
  recommendedAction: string;
  confidence: number;
};

export type TargetCandidate = {
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

export type TargetCandidateSet = {
  candidates: TargetCandidate[];
  recommendedCandidateIndex: number | null;
  recommendationReason: string;
};

export type MvpPlan = {
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

export type PivotResult = {
  decision: PivotDecision;
  confidence: number;
  reasonCodes: string[];
  rationale: string;
  wouldBeDecision: PivotDecision | null;
  keep: string[];
  change: string[];
  remove: string[];
  nextActions: string[];
  requiresHumanApproval: boolean;
};

export type AnalysisResult = {
  meta: {
    engine: string;
    engineVersion: string;
    policyVersion: string;
    schemaVersion: string;
    createdAt: string;
    modelProvider: string | null;
    modelName: string | null;
  };
  idea: IdeaStructure;
  diagnosis: {
    totalScore: number;
    overallConfidence: number;
    dimensions: DimensionScore[];
    warnings: DiagnosisWarning[];
    criticalRisks: string[];
    unknowns: string[];
  };
  targets: TargetCandidateSet;
  mvp: MvpPlan;
  pivot: PivotResult;
  nextActions: string[];
};

// ─────────────────────────────────────────────────────────────
// 텍스트 신호 사전 — 어떤 신호가 걸렸는지 그대로 이유 문구에 쓴다
// ─────────────────────────────────────────────────────────────

const BROAD_TARGET_PHRASES = [
  "모든 사람",
  "모든사람",
  "누구나",
  "누구든",
  "전 국민",
  "전국민",
  "전체 사용자",
  "모든 사용자",
  "관심 있는 사람",
  "관심있는 사람",
  "관심 있는 모든",
  "학생 모두",
  "학생 전체",
  "모든 학생",
  "아이들 전체",
  "모든 아이",
  "전 연령",
  "남녀노소",
  "일반인",
  "대중",
  "모두를 위한",
  "누구를 위한",
];

const GROUP_NOUNS =
  "(?:사람|분|이들|누구|사용자|유저|학생|아이|아동|어린이|초등학생|개발자|직장인|고객)";

const BROAD_TARGET_PATTERNS: RegExp[] = [
  new RegExp(`(?:배우고|알고|하고|쓰고|만들고)\\s*싶은\\s*(?:모든\\s*)?${GROUP_NOUNS}`),
  new RegExp(`에\\s*관심\\s*(?:이\\s*)?있는\\s*(?:모든\\s*)?${GROUP_NOUNS}`),
  new RegExp(`${GROUP_NOUNS}들?\\s*(?:전체|전부|모두)`),
  new RegExp(`(?:모든|전체|모든\\s*연령의|온)\\s*${GROUP_NOUNS}`),
];

const PAIN_SIGNALS = [
  "중단", "막힘", "막혀", "막힌", "포기", "실패", "회피", "피하",
  "불안", "좌절", "짜증", "헤매", "시간이 오래", "복잡", "비용",
  "어려", "모르겠", "헷갈", "이해 못", "틀리", "귀찮",
];

const FREQUENCY_SIGNALS = [
  "매일", "하루", "자주", "반복", "항상", "매번", "주 ", "주간",
  "수시로", "계속", "번씩", "번에 한", "회씩",
];

const MEASURABLE_SIGNALS = [
  "%", "퍼센트", "분 이내", "초 이내", "분 안에", "회 이상", "명 이상",
  "완료율", "정답률", "재방문", "전환율", "감소", "증가", "단축",
  "이상", "이하", "배 ", "점 ",
];

const RETENTION_SIGNALS = [
  "매일", "주간", "진도", "복습", "성장", "기록", "누적", "연속",
  "알림", "리포트", "요약", "도감", "레벨", "습관",
];

const CHANNEL_SIGNALS = [
  "커뮤니티", "카페", "오픈채팅", "유튜브", "블로그", "검색",
  "aso", "seo", "앱스토어", "플레이스토어", "인스타", "쓰레드",
  "트위터", "디스코드", "학원", "학교", "교사", "학부모", "추천", "제휴",
  "광고", "인플루언서", "뉴스레터", "레딧", "슬랙", "링크드인",
];

const FEATURE_FIRST_SIGNALS = [
  "기능", "화면", "버튼", "챗봇", "ai로", "gpt", "블록체인", "메타버스",
  "대시보드", "랭킹", "게시판",
];

const CHILD_SIGNALS = [
  "어린이", "아이", "아동", "초등", "유치", "학생", "꼬맹", "자녀", "미취학",
];

const TRIGGER_SIGNALS = ["때", "중", "하다가", "하면서", "상황", "과정", "단계", "후"];

function normalize(text: string | null | undefined): string {
  if (!text) return "";
  return text.replace(/\s+/g, " ").trim().toLowerCase();
}

function hasText(text: string | null | undefined, minLen = 1): boolean {
  return Boolean(text) && (text as string).trim().length >= minLen;
}

function matchedSignals(text: string | null | undefined, signals: string[]): string[] {
  const norm = normalize(text);
  if (!norm) return [];
  return signals.filter((s) => s.trim() && norm.includes(s.toLowerCase()));
}

function hasSignal(text: string | null | undefined, signals: string[]): boolean {
  return matchedSignals(text, signals).length > 0;
}

/** 넓은 타깃 표현. 문자열 규칙만 쓰지 않고 패턴도 함께 본다. */
function broadTargetHits(text: string | null | undefined): string[] {
  const norm = normalize(text);
  if (!norm) return [];
  const hits = BROAD_TARGET_PHRASES.filter((p) => norm.includes(p.toLowerCase()));
  for (const pattern of BROAD_TARGET_PATTERNS) {
    const m = pattern.exec(norm);
    if (m) hits.push(m[0].trim());
  }
  return [...new Set(hits)];
}

/** 타깃 문장이 담고 있는 구체성 신호 개수 (0~4): 상황·현재 행동·중단 원인·길이 */
function targetSpecificityScore(targetUser: string | null | undefined): number {
  const norm = normalize(targetUser);
  if (!norm) return 0;
  let score = 0;
  if (norm.length >= 20) score += 1;
  if (hasSignal(norm, ["상황", "때", "중", "하다가", "하면서", "과정", "단계"])) score += 1;
  if (hasSignal(norm, PAIN_SIGNALS)) score += 1;
  if (hasSignal(norm, ["사용", "쓰고", "쓰는", "이용", "만들", "배우", "풀", "하고 있", "진행"]))
    score += 1;
  return score;
}

// ─────────────────────────────────────────────────────────────
// 규칙 엔진 — 누락과 위험 표현을 경고로 바꾼다
// ─────────────────────────────────────────────────────────────

export const REQUIRED_STRUCTURE_FIELDS: {
  key: keyof IdeaStructure;
  label: string;
  why: string;
}[] = [
  {
    key: "targetUser",
    label: "사용자",
    why: "누가 겪는 문제인지 없으면 타깃 평가가 전부 0점이 됩니다.",
  },
  { key: "problemSituation", label: "문제 상황", why: "문제가 없으면 진단할 대상이 없습니다." },
  { key: "coreAction", label: "핵심 행동", why: "무엇을 하게 할지 없으면 MVP를 만들 수 없습니다." },
  {
    key: "expectedResult",
    label: "기대 결과",
    why: "무엇이 달라지는지 없으면 성공을 판정할 수 없습니다.",
  },
];

const MIN_REQUIRED_LENGTH = 2;

export function missingRequiredFields(idea: IdeaStructure) {
  return REQUIRED_STRUCTURE_FIELDS.filter(
    (f) => !hasText(idea[f.key] as string | null, MIN_REQUIRED_LENGTH),
  );
}

function warn(
  code: WarningCode,
  message: string,
  severity: Severity,
  field: string | null,
  recommendedAction: string,
): DiagnosisWarning {
  return { code, message, severity, field, recommendedAction };
}

export function detectWarnings(idea: IdeaStructure): DiagnosisWarning[] {
  const warnings: DiagnosisWarning[] = [];

  // ── BROAD_TARGET ──
  const hits = broadTargetHits(idea.targetUser);
  const specificity = targetSpecificityScore(idea.targetUser);
  if (hits.length > 0) {
    warnings.push(
      warn(
        "BROAD_TARGET",
        `타깃 정의에 넓은 표현이 있습니다: ${hits.join(", ")}. 나이·직업만이 아니라 상황 + 문제 + 현재 행동 + 중단 원인을 포함해야 합니다.`,
        "CRITICAL",
        "targetUser",
        "타깃을 '어떤 상황에서 무엇을 하다가 왜 멈추는 사람'으로 다시 씁니다.",
      ),
    );
  } else if (hasText(idea.targetUser) && specificity <= 1) {
    warnings.push(
      warn(
        "BROAD_TARGET",
        "넓은 표현은 없지만 타깃 문장에 상황·현재 행동·중단 원인이 거의 없습니다. 행동으로 정의된 타깃으로 보기 어렵습니다.",
        "WARN",
        "targetUser",
        "타깃이 지금 무엇을 하고 있고 어디서 멈추는지 한 문장을 추가합니다.",
      ),
    );
  }

  // ── 필수 누락 ──
  if (!hasText(idea.problemSituation, 5)) {
    warnings.push(
      warn(
        "NO_TRIGGER_SITUATION",
        "문제가 발생하는 구체적인 상황이 없습니다.",
        "CRITICAL",
        "problemSituation",
        "'언제, 무엇을 하다가' 문제가 생기는지 상황을 적습니다.",
      ),
    );
  } else if (!hasSignal(idea.problemSituation, TRIGGER_SIGNALS)) {
    warnings.push(
      warn(
        "NO_TRIGGER_SITUATION",
        "문제 서술은 있으나 문제가 발생하는 시점(트리거)이 드러나지 않습니다.",
        "WARN",
        "problemSituation",
        "문제가 터지는 순간을 시간·행동 기준으로 명시합니다.",
      ),
    );
  }

  if (!hasText(idea.currentSolution, 2)) {
    warnings.push(
      warn(
        "NO_CURRENT_ALTERNATIVE",
        "사용자가 지금 쓰고 있는 대체 방법이 없습니다. 대체재가 없다면 문제가 없을 가능성이 큽니다.",
        "WARN",
        "currentSolution",
        "지금은 이 문제를 어떻게 넘기고 있는지 적습니다(검색, 지인, 수기, 방치 포함).",
      ),
    );
  }

  if (!hasText(idea.coreAction, 2)) {
    warnings.push(
      warn(
        "FEATURE_FIRST_IDEA",
        "핵심 행동이 정의되지 않았습니다.",
        "CRITICAL",
        "coreAction",
        "사용자가 앱에서 반드시 완료해야 하는 행동 하나를 적습니다.",
      ),
    );
  }

  if (!hasText(idea.expectedResult, 2)) {
    warnings.push(
      warn(
        "NO_MEASURABLE_RESULT",
        "핵심 행동 후의 기대 결과가 없습니다.",
        "CRITICAL",
        "expectedResult",
        "핵심 행동을 마치면 사용자에게 무엇이 달라지는지 적습니다.",
      ),
    );
  } else if (!hasSignal(idea.expectedResult, MEASURABLE_SIGNALS)) {
    warnings.push(
      warn(
        "NO_MEASURABLE_RESULT",
        "기대 결과가 측정 가능한 표현이 아닙니다. 추천 기능은 지표와 연결되어야 합니다.",
        "WARN",
        "expectedResult",
        "기대 결과를 '무엇이 몇 % / 몇 분 / 몇 회 달라지는가'로 바꿉니다.",
      ),
    );
  }

  if (!hasText(idea.firstSuccess, 2)) {
    warnings.push(
      warn(
        "NO_FIRST_SUCCESS",
        "첫 성공 경험이 정의되지 않았습니다. 활성화 지점이 없으면 이탈 원인을 못 찾습니다.",
        "WARN",
        "firstSuccess",
        "처음 진입한 사용자가 몇 분 안에 무엇을 해내야 하는지 적습니다.",
      ),
    );
  }

  if (!hasText(idea.retentionReason, 2)) {
    warnings.push(
      warn(
        "NO_RETENTION_REASON",
        "다시 돌아올 이유가 없습니다.",
        "WARN",
        "retentionReason",
        "사용자가 내일 다시 열어야 하는 이유를 적습니다.",
      ),
    );
  }

  // ── 결제자 분리 ──
  const childContext =
    hasSignal(idea.targetUser, CHILD_SIGNALS) || hasSignal(idea.problemSituation, CHILD_SIGNALS);
  if (!hasText(idea.payer, 2)) {
    if (childContext) {
      warnings.push(
        warn(
          "NO_PAYER_DEFINED",
          "어린이·교육 맥락인데 사용자와 구매자가 분리되지 않았습니다. 쓰는 사람과 결제하는 사람이 다릅니다.",
          "CRITICAL",
          "payer",
          "사용자(아이), 구매자(부모), 영향자(교사)를 각각 적습니다.",
        ),
      );
    } else {
      warnings.push(
        warn(
          "NO_PAYER_DEFINED",
          "구매자가 정의되지 않았습니다. 사용자와 결제자가 같은지 확인이 필요합니다.",
          "WARN",
          "payer",
          "결제 결정을 내리는 주체를 명시합니다. 같다면 '사용자와 동일'로 적습니다.",
        ),
      );
    }
  }

  // ── 기능 우선 아이디어 ──
  if (
    hasSignal(idea.coreAction, FEATURE_FIRST_SIGNALS) &&
    !hasSignal(idea.problemSituation, PAIN_SIGNALS)
  ) {
    warnings.push(
      warn(
        "FEATURE_FIRST_IDEA",
        "문제의 고통 신호 없이 기능·기술 중심으로 서술되어 있습니다.",
        "WARN",
        "coreAction",
        "기능 대신 사용자가 겪는 손해를 먼저 씁니다.",
      ),
    );
  }

  // ── 근거 없는 차별성 단정 ──
  if (hasText(idea.currentSolution, 2) && !hasText(idea.currentSolutionProblem, 5)) {
    warnings.push(
      warn(
        "UNSUPPORTED_CLAIM",
        "대체 방법은 있으나 그것이 왜 부족한지가 없습니다. 차별성 주장이 근거 없이 남습니다.",
        "WARN",
        "currentSolutionProblem",
        "현재 방법이 시간·복잡성·실패·불안·비용 중 무엇 때문에 부족한지 적습니다.",
      ),
    );
  }

  return warnings;
}

const SEVERITY_ORDER: Record<Severity, number> = { CRITICAL: 0, WARN: 1, INFO: 2 };

/** 같은 (코드, 필드) 조합은 가장 심각한 것 하나만 남긴다. */
export function dedupeWarnings(warnings: DiagnosisWarning[]): DiagnosisWarning[] {
  const best = new Map<string, DiagnosisWarning>();
  for (const w of warnings) {
    const key = `${w.code}::${w.field ?? ""}`;
    const current = best.get(key);
    if (!current || SEVERITY_ORDER[w.severity] < SEVERITY_ORDER[current.severity]) {
      best.set(key, w);
    }
  }
  return [...best.values()];
}

function baseUnknowns(idea: IdeaStructure): string[] {
  const unknowns: string[] = [];
  if (!hasText(idea.currentSolution, 2))
    unknowns.push("사용자가 지금 이 문제를 실제로 어떻게 넘기고 있는가");
  if (!hasText(idea.firstSuccess, 2))
    unknowns.push("첫 진입 사용자가 몇 분 안에 무엇을 성공해야 남는가");
  if (!hasText(idea.retentionReason, 2)) unknowns.push("사용자가 다음 날 다시 열 이유는 무엇인가");
  if (!hasText(idea.payer, 2))
    unknowns.push("결제를 결정하는 주체는 누구이며 무엇을 보고 결정하는가");
  if (!hasText(idea.distributionChannel, 2))
    unknowns.push("첫 100명의 사용자를 어디서 데려올 것인가");
  unknowns.push("이 문제가 실제로 얼마나 자주, 얼마나 크게 발생하는가");
  return [...new Set(unknowns)];
}

// ─────────────────────────────────────────────────────────────
// 신뢰도 — 근거가 없는 항목은 상한을 넘지 못한다
// ─────────────────────────────────────────────────────────────

function evidenceConfidence(item: EvidenceItem, policy: EvaluationPolicy): number {
  if (item.confidenceOverride !== null && item.confidenceOverride !== undefined) {
    return Math.max(0, Math.min(1, item.confidenceOverride));
  }
  return policy.evidenceConfidence[item.evidenceType] ?? policy.noEvidenceConfidenceCap;
}

/** 표본 보정 계수 (0.6~1.0). 표본이 커도 근거 유형의 상한을 넘기지는 못한다. */
function sampleFactor(sampleSize: number | null): number {
  if (sampleSize === null || sampleSize === undefined || sampleSize <= 0) return 0.8;
  if (sampleSize < 3) return 0.6;
  if (sampleSize < 5) return 0.8;
  if (sampleSize < 10) return 0.9;
  return 1.0;
}

function round4(n: number): number {
  return Math.round(n * 10000) / 10000;
}

export function computeConfidence(
  evidence: EvidenceItem[],
  policy: EvaluationPolicy,
): { perDimension: Record<DimensionCode, number>; overall: number; warnings: DiagnosisWarning[] } {
  const perDimension = {} as Record<DimensionCode, number>;
  const warnings: DiagnosisWarning[] = [];

  for (const code of DIMENSION_CODES) {
    const supporting = evidence.filter((e) => e.supports.includes(code));
    const contradicting = evidence.filter((e) => e.contradicts.includes(code));

    if (supporting.length === 0) {
      let base = policy.noEvidenceConfidenceCap;
      if (contradicting.length > 0) base *= 0.5;
      perDimension[code] = round4(base);
      continue;
    }

    // 근거 신뢰도의 가중 평균 (가중치 = 근거 신뢰도 × 표본 보정)
    let numerator = 0;
    let denominator = 0;
    for (const item of supporting) {
      const conf = evidenceConfidence(item, policy);
      const weight = conf * sampleFactor(item.sampleSize);
      numerator += conf * weight;
      denominator += weight;
    }
    let value = denominator ? numerator / denominator : policy.noEvidenceConfidenceCap;

    if (contradicting.length > 0) {
      const strongestContra = Math.max(...contradicting.map((e) => evidenceConfidence(e, policy)));
      value *= Math.max(0, 1 - policy.conflictPenalty * strongestContra);
      warnings.push(
        warn(
          "CONFLICTING_EVIDENCE",
          `${code} 항목에 지지 근거 ${supporting.length}건과 반박 근거 ${contradicting.length}건이 함께 있습니다.`,
          "WARN",
          code,
          "상충 원인을 좁히는 실험을 먼저 설계합니다.",
        ),
      );
    }

    perDimension[code] = round4(Math.max(0, Math.min(1, value)));
  }

  let overall = 0;
  for (const code of DIMENSION_CODES) overall += perDimension[code] * policy.weights[code];
  overall = round4(Math.max(0, Math.min(1, overall / 100)));

  if (overall < policy.holdThreshold) {
    warnings.push(
      warn(
        "LOW_EVIDENCE",
        `전체 근거 신뢰도가 ${overall.toFixed(2)}로 기준치 ${policy.holdThreshold.toFixed(2)} 미만입니다. 판단을 확정할 수 없습니다.`,
        "CRITICAL",
        null,
        "가장 약한 항목부터 인터뷰·프로토타입 근거를 등록합니다.",
      ),
    );
  }

  return { perDimension, overall, warnings };
}

// ─────────────────────────────────────────────────────────────
// 점수 — 어떤 조건으로 몇 점이 붙었는지 reason 에 남긴다
// ─────────────────────────────────────────────────────────────

const MAX_RAW_SCORE = 5;

class Trace {
  points = 0;
  notes: string[] = [];

  add(condition: boolean, delta: number, note: string) {
    if (condition) {
      this.points += delta;
      this.notes.push(`+${delta} ${note}`);
    }
  }

  cap(ceiling: number, note: string) {
    if (this.points > ceiling) {
      this.points = ceiling;
      this.notes.push(`상한 ${ceiling} 적용: ${note}`);
    }
  }

  zero(note: string) {
    this.points = 0;
    this.notes = [`0점: ${note}`];
  }

  result(): [number, string] {
    const score = Math.max(0, Math.min(MAX_RAW_SCORE, this.points));
    return [score, this.notes.length ? this.notes.join(" / ") : "판단 근거 없음"];
  }
}

function evidenceFor(evidence: EvidenceItem[], code: DimensionCode): EvidenceItem[] {
  return evidence.filter((e) => e.supports.includes(code));
}

function hasStrongEvidence(
  evidence: EvidenceItem[],
  code: DimensionCode,
  policy: EvaluationPolicy,
  minimum = 0.5,
): boolean {
  return evidenceFor(evidence, code).some((e) => evidenceConfidence(e, policy) >= minimum);
}

type Scorer = (
  idea: IdeaStructure,
  warns: Set<WarningCode>,
  ev: EvidenceItem[],
  policy: EvaluationPolicy,
) => [number, string];

const SCORERS: Record<DimensionCode, Scorer> = {
  // D01 문제 구체성
  D01: (idea, warns) => {
    const t = new Trace();
    if (!hasText(idea.problemSituation, 5)) {
      t.zero("문제 상황이 비어 있음");
      return t.result();
    }
    const text = idea.problemSituation;
    t.add(true, 1, "문제 상황 서술 있음");
    t.add(text.trim().length >= 30, 1, "문제 서술이 30자 이상");
    t.add(text.trim().length >= 80, 1, "문제 서술이 80자 이상으로 구체적");
    t.add(hasText(idea.currentSolutionProblem, 5), 1, "현재 방법의 한계가 서술됨");
    t.add(hasSignal(text, PAIN_SIGNALS), 1, "고통 신호(중단·실패·불안 등) 포함");
    if (warns.has("NO_TRIGGER_SITUATION")) t.cap(3, "문제 발생 트리거가 불명확");
    return t.result();
  },

  // D02 문제 강도·빈도
  D02: (idea, _warns, ev, policy) => {
    const t = new Trace();
    if (!hasText(idea.problemSituation, 5)) {
      t.zero("문제 상황이 비어 있어 강도를 판단할 수 없음");
      return t.result();
    }
    t.add(true, 1, "문제 서술 있음");
    t.add(hasSignal(idea.problemSituation, FREQUENCY_SIGNALS), 1, "발생 빈도 신호 포함");
    t.add(hasSignal(idea.problemSituation, PAIN_SIGNALS), 1, "심각도 신호 포함");
    t.add(evidenceFor(ev, "D02").length > 0, 1, "문제 강도를 지지하는 근거 등록됨");
    t.add(hasStrongEvidence(ev, "D02", policy), 1, "인터뷰 이상 수준의 근거 존재");
    return t.result();
  },

  // D03 타깃 명확성
  D03: (idea, warns) => {
    const t = new Trace();
    if (!hasText(idea.targetUser, 2)) {
      t.zero("타깃이 비어 있음");
      return t.result();
    }
    const spec = targetSpecificityScore(idea.targetUser);
    t.add(true, 1, "타깃 서술 있음");
    t.add(spec >= 2, 1, `구체성 신호 ${spec}개`);
    t.add(spec >= 3, 1, "상황·행동·중단 원인이 함께 드러남");
    t.add(hasText(idea.currentSolution, 2), 1, "현재 행동(대체 방법)이 정의됨");
    t.add(!warns.has("BROAD_TARGET"), 1, "넓은 타깃 표현 없음");
    if (warns.has("BROAD_TARGET")) t.cap(2, "넓은 타깃 경고 발생");
    return t.result();
  },

  // D04 사용자·구매자 구분
  D04: (idea) => {
    const t = new Trace();
    if (!hasText(idea.targetUser, 2)) {
      t.zero("사용자가 비어 있음");
      return t.result();
    }
    t.add(true, 2, "사용자 정의됨");
    t.add(hasText(idea.payer, 2), 2, "구매자 정의됨");
    t.add(hasText(idea.influencer, 2), 1, "영향자 정의됨");
    if (!hasText(idea.payer, 2)) t.cap(2, "구매자 미정의");
    return t.result();
  },

  // D05 가치 제안
  D05: (idea) => {
    const t = new Trace();
    if (!hasText(idea.coreAction, 2)) {
      t.zero("핵심 행동이 비어 있음");
      return t.result();
    }
    t.add(true, 2, "핵심 행동 정의됨");
    t.add(idea.coreAction.trim().length >= 15, 1, "핵심 행동이 구체적");
    t.add(hasText(idea.expectedResult, 2), 1, "기대 결과 정의됨");
    t.add(hasSignal(idea.expectedResult, MEASURABLE_SIGNALS), 1, "기대 결과가 측정 가능");
    return t.result();
  },

  // D06 첫 성공 경험
  D06: (idea) => {
    const t = new Trace();
    if (!hasText(idea.firstSuccess, 2)) {
      t.zero("첫 성공 경험이 정의되지 않음");
      return t.result();
    }
    t.add(true, 2, "첫 성공 경험 정의됨");
    t.add((idea.firstSuccess as string).trim().length >= 20, 1, "첫 성공 서술이 구체적");
    t.add(
      hasSignal(idea.firstSuccess, ["분", "초", "단계", "첫", "한 번", "바로", "즉시"]),
      1,
      "도달 시점이 명시됨",
    );
    t.add(hasText(idea.coreAction, 2), 1, "핵심 행동과 연결 가능");
    return t.result();
  },

  // D07 반복 사용 이유
  D07: (idea, _warns, ev) => {
    const t = new Trace();
    if (!hasText(idea.retentionReason, 2)) {
      t.zero("재방문 이유가 정의되지 않음");
      return t.result();
    }
    t.add(true, 2, "재방문 이유 정의됨");
    t.add((idea.retentionReason as string).trim().length >= 20, 1, "재방문 이유가 구체적");
    t.add(hasSignal(idea.retentionReason, RETENTION_SIGNALS), 1, "반복 사용 장치 포함");
    t.add(evidenceFor(ev, "D07").length > 0, 1, "재방문을 지지하는 근거 등록됨");
    return t.result();
  },

  // D08 차별성
  D08: (idea, _warns, ev, policy) => {
    const t = new Trace();
    if (!hasText(idea.currentSolution, 2)) {
      t.zero("대체 방법이 없어 차별성을 판단할 수 없음");
      return t.result();
    }
    t.add(true, 1, "대체 방법 정의됨");
    t.add(hasText(idea.currentSolutionProblem, 5), 1, "대체 방법의 한계 서술됨");
    t.add(hasText(idea.currentSolutionProblem, 30), 1, "대체 방법의 한계가 30자 이상으로 구체적");
    t.add(evidenceFor(ev, "D08").length > 0, 1, "차별성을 지지하는 근거 등록됨");
    t.add(
      hasStrongEvidence(ev, "D08", policy, 0.35),
      1,
      "데스크리서치 이상 수준의 근거 존재",
    );
    return t.result();
  },

  // D09 유입 가능성
  D09: (idea, _warns, ev) => {
    const t = new Trace();
    if (!hasText(idea.distributionChannel, 2)) {
      t.zero("유입 경로가 정의되지 않음");
      return t.result();
    }
    t.add(true, 2, "유입 경로 정의됨");
    t.add((idea.distributionChannel as string).trim().length >= 15, 1, "유입 경로가 구체적");
    t.add(hasSignal(idea.distributionChannel, CHANNEL_SIGNALS), 1, "식별 가능한 채널 언급");
    t.add(evidenceFor(ev, "D09").length > 0, 1, "유입을 지지하는 근거 등록됨");
    return t.result();
  },

  // D10 구현 가능성 — 범위가 좁을수록 높다
  D10: (idea) => {
    const t = new Trace();
    if (!hasText(idea.coreAction, 2)) {
      t.zero("핵심 행동이 없어 구현 범위를 판단할 수 없음");
      return t.result();
    }
    t.add(true, 2, "핵심 행동이 있어 범위 산정 가능");
    t.add(hasText(idea.expectedResult, 2), 1, "완료 조건이 정의됨");
    t.add(hasText(idea.firstSuccess, 2), 1, "첫 성공 기준으로 범위를 좁힐 수 있음");
    t.add(idea.coreAction.trim().length <= 120, 1, "핵심 행동이 하나로 압축되어 있음");
    return t.result();
  },
};

const MISSING_EVIDENCE_HINTS: Record<DimensionCode, string[]> = {
  D01: ["문제 상황을 직접 관찰하거나 진술한 인터뷰"],
  D02: ["문제 발생 빈도와 심각도를 물은 인터뷰", "이탈·중단 행동 데이터"],
  D03: ["타깃 후보별 스크리닝 인터뷰"],
  D04: ["결제 결정자 인터뷰"],
  D05: ["가치 제안 문구 반응 테스트"],
  D06: ["첫 세션 완료율 프로토타입 테스트"],
  D07: ["재방문 코호트 행동 데이터"],
  D08: ["경쟁·대체재 데스크리서치", "대체재 사용자 인터뷰"],
  D09: ["채널별 유입 테스트(랜딩 페이지 등)"],
  D10: ["기술 검증 프로토타입"],
};

const RECOMMENDED_ACTIONS: Record<DimensionCode, string> = {
  D01: "문제가 발생하는 순간을 시간·행동 단위로 다시 씁니다.",
  D02: "대상 5명에게 '최근 한 달에 몇 번 겪었는지'를 직접 묻습니다.",
  D03: "타깃을 상황 + 현재 행동 + 중단 원인으로 다시 정의합니다.",
  D04: "사용자·구매자·영향자를 분리해 각각의 판단 기준을 적습니다.",
  D05: "핵심 행동 하나와 그 결과를 측정 가능한 문장으로 씁니다.",
  D06: "첫 3분 안에 끝나는 성공 경험 하나를 설계합니다.",
  D07: "다음 날 다시 열 이유를 제품 안의 장치로 만듭니다.",
  D08: "현재 대체재가 실패하는 지점을 근거와 함께 정리합니다.",
  D09: "첫 100명을 만날 채널 한 곳을 정하고 소규모로 테스트합니다.",
  D10: "MVP를 P0 + 최소한의 P1로 잘라냅니다.",
};

export function scoreDimensions(
  idea: IdeaStructure,
  warnings: DiagnosisWarning[],
  evidence: EvidenceItem[],
  policy: EvaluationPolicy,
  confidences: Record<DimensionCode, number>,
): DimensionScore[] {
  const warnCodes = new Set(warnings.map((w) => w.code));
  return DIMENSION_CODES.map((code) => {
    const [raw, reason] = SCORERS[code](idea, warnCodes, evidence, policy);
    const weight = policy.weights[code];
    return {
      code,
      label: DIMENSION_LABELS[code],
      rawScore: raw,
      weight,
      normalizedScore: (raw / MAX_RAW_SCORE) * weight,
      reason,
      missingEvidence: evidenceFor(evidence, code).length === 0 ? MISSING_EVIDENCE_HINTS[code] : [],
      recommendedAction: RECOMMENDED_ACTIONS[code],
      confidence: confidences[code] ?? 0,
    };
  });
}

// ─────────────────────────────────────────────────────────────
// 피벗 판정
// 1.신뢰도 부족 → HOLD  2.문제 약함 → PROBLEM  3.타깃 불명확 → TARGET
// 4.핵심 행동 실패 → SOLUTION  5.재방문 실패 → RETENTION
// 6.유입 실패 → CHANNEL  7.차별성 약함 → REVENUE  8.문제 없음 → KEEP/REFINE
// ─────────────────────────────────────────────────────────────

type Diagnosis = AnalysisResult["diagnosis"];

function dim(diagnosis: Diagnosis, code: DimensionCode): DimensionScore {
  return diagnosis.dimensions.find((d) => d.code === code) as DimensionScore;
}

function avg(diagnosis: Diagnosis, ...codes: DimensionCode[]): number {
  if (codes.length === 0) return 0;
  return codes.reduce((s, c) => s + dim(diagnosis, c).rawScore, 0) / codes.length;
}

function hasWarning(diagnosis: Diagnosis, code: WarningCode): boolean {
  return diagnosis.warnings.some((w) => w.code === code);
}

function decideWithoutConfidence(
  diagnosis: Diagnosis,
  policy: EvaluationPolicy,
): [PivotDecision, string[], string] {
  const problem = avg(diagnosis, "D01", "D02");
  if (problem < policy.problemPivotThreshold) {
    return [
      "PROBLEM_PIVOT",
      ["WEAK_PROBLEM"],
      `문제 구체성·강도 평균이 ${problem.toFixed(1)}로 기준 ${policy.problemPivotThreshold.toFixed(1)} 미만입니다. 해결책보다 문제를 다시 정의해야 합니다.`,
    ];
  }

  const target = dim(diagnosis, "D03").rawScore;
  if (hasWarning(diagnosis, "BROAD_TARGET") || target < policy.targetPivotThreshold) {
    const reasonCodes: string[] = [];
    if (hasWarning(diagnosis, "BROAD_TARGET")) reasonCodes.push("BROAD_TARGET");
    if (target < policy.targetPivotThreshold) reasonCodes.push("UNCLEAR_TARGET");
    return [
      "TARGET_PIVOT",
      reasonCodes,
      "문제는 살아 있으나 타깃이 넓거나 행동으로 정의되지 않았습니다. 먼저 좁은 타깃 하나를 골라 검증해야 합니다.",
    ];
  }

  const behavior = avg(diagnosis, "D05", "D06");
  if (behavior < policy.solutionPivotThreshold) {
    return [
      "SOLUTION_PIVOT",
      ["CORE_ACTION_NOT_COMPLETED"],
      `가치 제안·첫 성공 평균이 ${behavior.toFixed(1)}입니다. 관심은 있으나 핵심 행동이 완료되지 않는 구조입니다.`,
    ];
  }

  const retention = dim(diagnosis, "D07").rawScore;
  if (retention < policy.retentionPivotThreshold) {
    return [
      "RETENTION_REDESIGN",
      ["LOW_RETENTION"],
      "핵심 행동은 성립하지만 다시 돌아올 이유가 약합니다. 재방문 장치를 재설계해야 합니다.",
    ];
  }

  const channel = dim(diagnosis, "D09").rawScore;
  if (channel < policy.channelPivotThreshold) {
    return [
      "CHANNEL_PIVOT",
      ["WEAK_CHANNEL"],
      "유지 조건은 갖췄으나 유입 경로가 약합니다. 채널을 먼저 검증해야 합니다.",
    ];
  }

  const differentiation = dim(diagnosis, "D08").rawScore;
  if (differentiation < policy.revenuePivotThreshold) {
    return [
      "REVENUE_PIVOT",
      ["WEAK_DIFFERENTIATION"],
      "사용은 성립하지만 대체재 대비 차별성이 약해 지불 근거가 부족합니다.",
    ];
  }

  if (diagnosis.totalScore >= policy.keepScoreThreshold) {
    return [
      "KEEP",
      ["NO_CRITICAL_RISK"],
      `총점 ${diagnosis.totalScore.toFixed(1)}로 기준 ${policy.keepScoreThreshold.toFixed(1)} 이상이며 우선 처리할 위험이 없습니다. 현재 방향을 유지하고 실행 품질을 높입니다.`,
    ];
  }

  return [
    "REFINE",
    ["MINOR_GAPS"],
    `치명적 위험은 없으나 총점 ${diagnosis.totalScore.toFixed(1)}로 보완 여지가 있습니다. 가장 낮은 항목부터 다듬습니다.`,
  ];
}

const NEXT_ACTIONS_MAP: Record<PivotDecision, string[]> = {
  PROBLEM_PIVOT: [
    "대상 5명에게 문제 발생 빈도와 최근 사례를 묻는 인터뷰를 진행합니다.",
    "문제 정의 문장을 다시 작성하고 새 버전을 만듭니다.",
  ],
  TARGET_PIVOT: [
    "타깃 후보 3개 중 하나를 골라 스크리닝 인터뷰를 진행합니다.",
    "선택한 타깃으로 문제 정의를 다시 씁니다.",
  ],
  SOLUTION_PIVOT: [
    "핵심 행동만 남긴 클릭더미로 완료율을 측정합니다.",
    "첫 성공 경험을 3분 이내로 다시 설계합니다.",
  ],
  RETENTION_REDESIGN: ["재방문 이유를 제품 내 장치로 설계하고 코호트 유지율을 측정합니다."],
  CHANNEL_PIVOT: ["채널 한 곳을 정해 랜딩 페이지 유입 테스트를 진행합니다."],
  REVENUE_PIVOT: ["대체재 대비 차별점을 근거와 함께 정리하고 가격 반응을 테스트합니다."],
  KEEP: ["현재 가설을 유지한 채 실행 품질과 측정 이벤트를 점검합니다."],
  REFINE: ["가장 낮은 평가 항목 두 개를 보완한 새 버전을 만듭니다."],
  HOLD: [],
};

function buildActionLists(diagnosis: Diagnosis, decision: PivotDecision) {
  const keep = diagnosis.dimensions
    .filter((d) => d.rawScore >= 4)
    .map((d) => `${d.label}: ${d.reason}`);
  const change = diagnosis.dimensions
    .filter((d) => d.rawScore >= 1 && d.rawScore <= 3)
    .map((d) => `${d.label}: ${d.recommendedAction}`);
  const remove: string[] = [];
  for (const w of diagnosis.warnings) {
    if (w.code === "BROAD_TARGET") remove.push("넓은 타깃 표현을 기획서에서 제거합니다.");
    if (w.code === "FEATURE_FIRST_IDEA")
      remove.push("문제와 연결되지 않은 기능 서술을 제거합니다.");
  }
  return {
    keep,
    change,
    remove: [...new Set(remove)],
    nextActions: NEXT_ACTIONS_MAP[decision] ?? [],
  };
}

export function decidePivot(diagnosis: Diagnosis, policy: EvaluationPolicy): PivotResult {
  const [contentDecision, reasonCodes, rationale] = decideWithoutConfidence(diagnosis, policy);
  const { keep, change, remove, nextActions } = buildActionLists(diagnosis, contentDecision);

  if (diagnosis.overallConfidence < policy.holdThreshold) {
    return {
      decision: "HOLD",
      confidence: diagnosis.overallConfidence,
      reasonCodes: [...new Set(["LOW_EVIDENCE", ...reasonCodes])],
      rationale: `전체 근거 신뢰도 ${diagnosis.overallConfidence.toFixed(2)}가 기준 ${policy.holdThreshold.toFixed(2)} 미만이라 판단을 확정하지 않습니다. 현재 내용만 보면 ${PIVOT_LABELS[contentDecision]} 방향이며, 사유는 다음과 같습니다. ${rationale}`,
      wouldBeDecision: contentDecision,
      keep,
      change,
      remove,
      nextActions: ["판단을 확정하려면 근거를 먼저 등록합니다.", ...nextActions],
      requiresHumanApproval: true,
    };
  }

  return {
    decision: contentDecision,
    confidence: diagnosis.overallConfidence,
    reasonCodes: [...new Set(reasonCodes)],
    rationale,
    wouldBeDecision: null,
    keep,
    change,
    remove,
    nextActions,
    requiresHumanApproval: true,
  };
}

// ─────────────────────────────────────────────────────────────
// 타깃 후보 / MVP 계획
// ─────────────────────────────────────────────────────────────

function currentTargetAsCandidate(
  idea: IdeaStructure,
  diagnosis: Diagnosis,
): TargetCandidate | null {
  if (!hasText(idea.targetUser, 2)) return null;

  const risks: string[] = [];
  if (hasWarning(diagnosis, "BROAD_TARGET"))
    risks.push("타깃 표현이 넓어 실험 대상을 특정할 수 없습니다.");
  if (dim(diagnosis, "D04").rawScore <= 2) risks.push("사용자와 구매자가 분리되지 않았습니다.");
  if (!hasText(idea.currentSolution, 2))
    risks.push("현재 대체 방법이 없어 문제 존재 여부를 확인할 수 없습니다.");

  return {
    name: "현재 입력된 타깃",
    user: idea.targetUser,
    payer: idea.payer,
    influencer: idea.influencer,
    triggerSituation: idea.problemSituation,
    problem: idea.currentSolutionProblem || idea.problemSituation,
    currentAlternative: idea.currentSolution,
    whyPromising: ["사용자가 직접 정의한 타깃이라 즉시 접촉 가능성이 있습니다."],
    risks: risks.length ? risks : ["확인된 위험 없음. 근거로 검증 필요."],
    validationQuestions: [
      "이 타깃에 해당하는 사람을 이번 주에 5명 만날 수 있는가",
      "그 사람들은 지금 이 문제를 어떻게 넘기고 있는가",
    ],
    recommendedExperiment: "스크리닝 질문 3개로 해당 타깃 5명을 찾아 인터뷰",
  };
}

export function buildTargetCandidates(
  idea: IdeaStructure,
  diagnosis: Diagnosis,
  policy: EvaluationPolicy,
  seeds: TargetCandidate[] = [],
): TargetCandidateSet {
  const candidates: TargetCandidate[] = [...seeds];
  const current = currentTargetAsCandidate(idea, diagnosis);
  if (current) candidates.unshift(current);

  if (candidates.length === 0) {
    return {
      candidates: [],
      recommendedCandidateIndex: null,
      recommendationReason:
        "입력 근거가 부족해 타깃 후보를 제시하지 않습니다. 먼저 타깃을 상황 + 현재 행동 + 중단 원인으로 다시 작성하세요.",
    };
  }

  // 추천은 근거가 충분할 때만 한다.
  if (diagnosis.overallConfidence < policy.holdThreshold) {
    return {
      candidates: candidates.slice(0, 4),
      recommendedCandidateIndex: null,
      recommendationReason: `전체 근거 신뢰도가 ${diagnosis.overallConfidence.toFixed(2)}로 기준 ${policy.holdThreshold.toFixed(2)} 미만이라 하나를 추천하지 않습니다. 후보를 비교한 뒤 스크리닝 인터뷰로 직접 고르세요.`,
    };
  }

  let index = 0;
  let reason =
    "현재 타깃이 상황 기반으로 정의되어 있고 근거 신뢰도가 기준을 넘겨 그대로 유지한 채 검증을 진행할 수 있습니다.";
  if (hasWarning(diagnosis, "BROAD_TARGET") && candidates.length > 1) {
    index = current ? 1 : 0;
    reason = `현재 타깃에 넓은 표현이 있어 그대로 검증하기 어렵습니다. '${candidates[index].name}'는 중단 시점이 명확해 실험 설계가 가능합니다.`;
  }

  return {
    candidates: candidates.slice(0, 4),
    recommendedCandidateIndex: index,
    recommendationReason: reason,
  };
}

/** MVP 범위는 P0 + 최소한의 P1. 측정 이벤트가 없는 기능은 넣지 않는다. */
export function buildMvpPlan(idea: IdeaStructure, diagnosis: Diagnosis): MvpPlan {
  const coreAction = idea.coreAction.trim() || "(핵심 행동 미정의)";
  const expected = idea.expectedResult.trim() || "(기대 결과 미정의)";

  const p0: string[] = [];
  if (hasText(idea.coreAction, 2)) p0.push(`핵심 행동: ${coreAction}`);
  if (hasText(idea.firstSuccess, 2))
    p0.push(`첫 성공 경험: ${(idea.firstSuccess as string).trim()}`);
  else p0.push("첫 성공 경험 설계 (3분 이내 완료 가능한 최소 성공)");
  p0.push("핵심 행동 완료 이벤트 기록");

  const p1: string[] = [];
  if (hasText(idea.retentionReason, 2))
    p1.push(`재방문 장치: ${(idea.retentionReason as string).trim()}`);
  p1.push("실패·빈 상태·권한 거부 화면");
  p1.push("결과 요약 화면 (점수보다 이유와 다음 행동 우선)");

  return {
    coreHypothesis: `${idea.targetUser.trim() || "(타깃 미정의)"}는 ${coreAction}을(를) 통해 ${expected}을(를) 얻는다.`,
    problemHypothesis: idea.problemSituation.trim() || "(문제 상황 미정의)",
    behaviorHypothesis: `사용자는 첫 세션에서 ${coreAction}을(를) 끝까지 완료한다.`,
    valueHypothesis: `핵심 행동을 마치면 ${expected}이(가) 실제로 발생한다.`,
    retentionHypothesis: hasText(idea.retentionReason, 2)
      ? (idea.retentionReason as string).trim()
      : "재방문 이유가 아직 정의되지 않아 가설을 세울 수 없다.",
    revenueHypothesis: hasText(idea.revenueModel, 2) ? (idea.revenueModel as string).trim() : null,
    p0Features: [...new Set(p0)],
    p1Features: [...new Set(p1)],
    excludedFeatures: ["P2/P3 편의·장식·확장 기능", "측정 이벤트가 연결되지 않은 모든 기능"],
    firstSuccessExperience: hasText(idea.firstSuccess, 2)
      ? (idea.firstSuccess as string).trim()
      : "미정의 — 활성화 지점을 먼저 정해야 합니다.",
    coreUserFlow: [
      "진입",
      "상황 선택 또는 짧은 진단",
      `핵심 행동 수행: ${coreAction}`,
      "즉각 피드백",
      "결과 요약과 다음 행동 제시",
    ],
    metrics: ["activation_complete", "core_action_complete", "day1_return"],
    risks: [...diagnosis.criticalRisks],
  };
}

// ─────────────────────────────────────────────────────────────
// 오케스트레이터
// ─────────────────────────────────────────────────────────────

export function runAnalysis(
  idea: IdeaStructure,
  options: {
    evidence?: EvidenceItem[];
    policy?: EvaluationPolicy;
    now?: Date;
    assist?: { provider: string; model: string } | null;
  } = {},
): AnalysisResult {
  const policy = options.policy ?? DEFAULT_POLICY;
  const evidence = options.evidence ?? [];
  const createdAt = options.now ?? new Date();

  // 1. 검증
  let warnings = dedupeWarnings(detectWarnings(idea));

  // 2. 신뢰도
  const conf = computeConfidence(evidence, policy);
  warnings = dedupeWarnings([...warnings, ...conf.warnings]);

  // 3. 채점
  const dimensions = scoreDimensions(idea, warnings, evidence, policy, conf.perDimension);
  const totalScore = dimensions.reduce((s, d) => s + d.normalizedScore, 0);

  const diagnosis: Diagnosis = {
    totalScore,
    overallConfidence: conf.overall,
    dimensions,
    warnings,
    criticalRisks: warnings
      .filter((w) => w.severity === "CRITICAL")
      .map((w) => `[${w.code}] ${w.message}`),
    unknowns: baseUnknowns(idea),
  };

  // 4. 타깃 후보 / MVP
  const targets = buildTargetCandidates(idea, diagnosis, policy);
  const mvp = buildMvpPlan(idea, diagnosis);

  // 5. 피벗 판정
  const pivot = decidePivot(diagnosis, policy);

  // 6. 사용자가 지금 할 일 — 점수가 아니라 행동을 먼저 보여준다
  const actions: string[] = [...pivot.nextActions];
  const weakest = [...diagnosis.dimensions]
    .sort((a, b) => a.rawScore - b.rawScore || a.code.localeCompare(b.code))
    .slice(0, 2);
  for (const d of weakest) actions.push(`[${d.label}] ${d.recommendedAction}`);
  if (diagnosis.criticalRisks.length > 0)
    actions.unshift("치명 위험으로 표시된 항목을 먼저 해소합니다.");

  return {
    meta: {
      engine: ENGINE_NAME,
      engineVersion: ENGINE_VERSION,
      policyVersion: policy.version,
      schemaVersion: SCHEMA_VERSION,
      createdAt: createdAt.toISOString(),
      // 엔진은 언제나 RULE_ENGINE. 아래 두 칸은 '초안을 누가 도왔는가'일 뿐 판정 주체가 아니다.
      modelProvider: options.assist?.provider ?? null,
      modelName: options.assist?.model ?? null,
    },
    idea,
    diagnosis,
    targets,
    mvp,
    pivot,
    nextActions: [...new Set(actions)],
  };
}

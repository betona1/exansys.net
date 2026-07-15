// 리뷰 정량 분석 — reviewgg 파이썬 로직을 웹용으로 재구성 + 시계열/버전 분석 추가
import type { ReviewRow } from "./stores";

// 키워드 분석 불용어 (영문 + 한글) — reviewgg 기준
const STOPWORDS = new Set(
  `a an the and or but if then this that these those is are was were be been being
to of in on at for for with from by as it its i you he she they we my your our
me him her them app apps use using used just really very so too much many more
most also even still get got can could would should will not no dont cant
im ive one two like want need make made time day days week weeks
have has had do does did what when where which who how why about out up down
그리고 그런데 하지만 그래서 정말 너무 앱 이 그 저 것 수 등 및 를 을 가 은 는
에 의 도 로 으로 에서 에게 한 할 하는 합니다 해요 했어요 있어요 없어요 같아요
좀 잘 더 못 안 왜 근데 진짜 그냥 계속 이거 저거 제가 저는 네요 어요 아요 는데
너무너무 정말정말 그리고또 있습니다 됩니다 하고 해서 하면 되서 그런`
    .split(/\s+/)
    .filter(Boolean),
);

export interface KeywordCount {
  word: string;
  count: number;
}

export interface Analysis {
  total: number;
  avgScore: number; // 평균 별점 (수집분 기준)
  distribution: number[]; // [1점,2점,3점,4점,5점] 개수
  distributionPct: number[]; // % (소수1자리)
  positive: number; // 4~5점
  neutral: number; // 3점
  negative: number; // 1~2점
  negativeRate: number; // 불만율 % (1~2점 비율)
  avgThumbsUp: number;
  complaintKeywords: KeywordCount[]; // 1~2점 리뷰 키워드
  praiseKeywords: KeywordCount[]; // 4~5점 리뷰 키워드
  monthlyTrend: { month: string; count: number; avg: number }[]; // YYYY-MM
  versionBreakdown: { version: string; count: number; avg: number }[];
}

function topKeywords(rows: ReviewRow[], topN: number): KeywordCount[] {
  const counter = new Map<string, number>();
  for (const r of rows) {
    const t = r.content;
    if (!t) continue;
    const tokens = t.toLowerCase().match(/[a-z가-힣]{2,}/g);
    if (!tokens) continue;
    for (const w of tokens) {
      if (STOPWORDS.has(w)) continue;
      counter.set(w, (counter.get(w) ?? 0) + 1);
    }
  }
  return [...counter.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, topN)
    .map(([word, count]) => ({ word, count }));
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function analyze(rows: ReviewRow[]): Analysis {
  const total = rows.length;
  const dist = [0, 0, 0, 0, 0];
  let sum = 0;
  let thumbs = 0;
  for (const r of rows) {
    const s = Math.min(5, Math.max(1, r.score || 0));
    if (s >= 1 && s <= 5) dist[s - 1]++;
    sum += r.score || 0;
    thumbs += r.thumbsUp || 0;
  }
  const positive = dist[3] + dist[4];
  const neutral = dist[2];
  const negative = dist[0] + dist[1];

  // 월별 추이
  const monthMap = new Map<string, { count: number; sum: number }>();
  for (const r of rows) {
    if (!r.at) continue;
    const d = new Date(r.at);
    const month = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
    const cur = monthMap.get(month) ?? { count: 0, sum: 0 };
    cur.count++;
    cur.sum += r.score || 0;
    monthMap.set(month, cur);
  }
  const monthlyTrend = [...monthMap.entries()]
    .sort((a, b) => (a[0] < b[0] ? -1 : 1))
    .map(([month, v]) => ({ month, count: v.count, avg: round1(v.sum / v.count) }));

  // 버전별 (play만 채워짐)
  const verMap = new Map<string, { count: number; sum: number }>();
  for (const r of rows) {
    if (!r.version) continue;
    const cur = verMap.get(r.version) ?? { count: 0, sum: 0 };
    cur.count++;
    cur.sum += r.score || 0;
    verMap.set(r.version, cur);
  }
  const versionBreakdown = [...verMap.entries()]
    .map(([version, v]) => ({ version, count: v.count, avg: round1(v.sum / v.count) }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  const neg = rows.filter((r) => (r.score || 0) <= 2);
  const pos = rows.filter((r) => (r.score || 0) >= 4);

  return {
    total,
    avgScore: total ? round1(sum / total) : 0,
    distribution: dist,
    distributionPct: dist.map((n) => (total ? round1((n / total) * 100) : 0)),
    positive,
    neutral,
    negative,
    negativeRate: total ? round1((negative / total) * 100) : 0,
    avgThumbsUp: total ? round1(thumbs / total) : 0,
    complaintKeywords: topKeywords(neg, 20),
    praiseKeywords: topKeywords(pos, 20),
    monthlyTrend,
    versionBreakdown,
  };
}

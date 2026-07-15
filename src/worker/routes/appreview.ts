// App Review 분석 API — 외부 스토어 리뷰 수집·분석·엑셀 추출 (crew 이상 전용)
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { and, asc, desc, eq, inArray, lt } from "drizzle-orm";
import { z } from "zod";
import { reviewCaches, reviewItems } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";
import { requireRole } from "../middleware";
import {
  SUPPORTED_REGIONS,
  searchApps,
  fetchAppInfo,
  fetchReviews,
  type ReviewRow,
  type StoreKind,
} from "../lib/stores";
import { analyze } from "../lib/analyze";
import { buildXlsx, type Sheet } from "../lib/xlsx";

export const appReviewRoutes = new Hono<{ Bindings: Env }>();

// crew 이상만 (외부 스토어 API 남용 방지)
appReviewRoutes.use("*", requireRole("crew"));

const CACHE_DAYS = 7;
const CACHE_MS = CACHE_DAYS * 24 * 60 * 60 * 1000;

const storeSchema = z.enum(["play", "apple"]);
const regionSchema = z.enum(SUPPORTED_REGIONS as [string, ...string[]]);

/** 만료된(7일 초과) 캐시 정리 */
async function cleanupStale(db: ReturnType<typeof drizzle>) {
  const cutoff = new Date(Date.now() - CACHE_MS);
  const stale = await db
    .select({ id: reviewCaches.id })
    .from(reviewCaches)
    .where(lt(reviewCaches.fetchedAt, cutoff));
  if (stale.length === 0) return;
  const ids = stale.map((s) => s.id);
  await db.delete(reviewItems).where(inArray(reviewItems.cacheId, ids));
  await db.delete(reviewCaches).where(inArray(reviewCaches.id, ids));
}

// ── 앱 검색 (순위·평점·다운로드 표시) ──
appReviewRoutes.get("/search", async (c) => {
  const parsed = z
    .object({ q: z.string().trim().min(1).max(80), store: storeSchema, region: regionSchema })
    .safeParse({
      q: c.req.query("q"),
      store: c.req.query("store"),
      region: c.req.query("region") ?? "kr",
    });
  if (!parsed.success) return c.json(err("invalid_params"), 400);
  const { q, store, region } = parsed.data;
  try {
    const hits = await searchApps(store, q, region);
    return c.json(ok({ hits, region, store }));
  } catch (e) {
    return c.json(err(`search_failed:${(e as Error).message}`), 502);
  }
});

const collectSchema = z.object({
  store: storeSchema,
  appId: z.string().trim().min(1).max(200),
  region: regionSchema,
  limit: z.number().int().min(50).max(1000).optional(),
  refresh: z.boolean().optional(),
});

// ── 리뷰 수집 + 분석 (7일 캐시) ──
appReviewRoutes.post("/collect", async (c) => {
  const body = await c.req.json().catch(() => null);
  const parsed = collectSchema.safeParse(body);
  if (!parsed.success) return c.json(err("invalid_params"), 400);
  const { store, appId, region, refresh } = parsed.data;
  // Apple RSS는 최대 500건
  const limit = Math.min(parsed.data.limit ?? 300, store === "apple" ? 500 : 1000);

  const db = drizzle(c.env.DB);
  await cleanupStale(db);

  const existing = await db
    .select()
    .from(reviewCaches)
    .where(
      and(eq(reviewCaches.store, store), eq(reviewCaches.appId, appId), eq(reviewCaches.region, region)),
    )
    .limit(1);

  const fresh =
    existing.length > 0 &&
    existing[0].reviewCount > 0 &&
    Date.now() - existing[0].fetchedAt.getTime() < CACHE_MS;

  // 캐시 적중 (강제 새로고침 아님)
  if (fresh && !refresh) {
    const cache = existing[0];
    const items = await loadItems(db, cache.id);
    const rows = items.map(itemToJson);
    return c.json(
      ok({
        cached: true,
        fetchedAt: cache.fetchedAt.getTime(),
        app: cacheMeta(cache),
        reviews: rows,
        analysis: analyze(rows),
      }),
    );
  }

  // 새로 수집
  let info;
  let reviews: ReviewRow[];
  try {
    [info, reviews] = await Promise.all([
      fetchAppInfo(store, appId, region),
      fetchReviews(store, appId, region, limit),
    ]);
  } catch (e) {
    return c.json(err(`collect_failed:${(e as Error).message}`), 502);
  }
  if (reviews.length === 0) {
    return c.json(err("no_reviews"), 404);
  }

  const now = new Date();
  const meta = {
    store,
    appId,
    region,
    title: info.title,
    iconUrl: info.iconUrl,
    score: info.score,
    ratings: info.ratings,
    installs: info.installs,
    realInstalls: info.realInstalls,
    reviewCount: reviews.length,
    fetchedAt: now,
  };

  // 캐시 upsert + 아이템 교체
  let cacheId: number;
  if (existing.length > 0) {
    cacheId = existing[0].id;
    await db.delete(reviewItems).where(eq(reviewItems.cacheId, cacheId));
    await db.update(reviewCaches).set(meta).where(eq(reviewCaches.id, cacheId));
  } else {
    const inserted = await db.insert(reviewCaches).values(meta).returning({ id: reviewCaches.id });
    cacheId = inserted[0].id;
  }
  await insertItems(db, cacheId, reviews);

  return c.json(
    ok({
      cached: false,
      fetchedAt: now.getTime(),
      app: { ...meta, fetchedAt: now.getTime() },
      reviews: reviews.map((r) => ({ ...r })),
      analysis: analyze(reviews),
    }),
  );
});

// ── 엑셀(.xlsx) 추출 — 마지막 수집 데이터 기준 ──
appReviewRoutes.get("/export", async (c) => {
  const parsed = z
    .object({ store: storeSchema, appId: z.string().min(1).max(200), region: regionSchema })
    .safeParse({
      store: c.req.query("store"),
      appId: c.req.query("appId"),
      region: c.req.query("region"),
    });
  if (!parsed.success) return c.json(err("invalid_params"), 400);
  const { store, appId, region } = parsed.data;

  const db = drizzle(c.env.DB);
  const rows = await db
    .select()
    .from(reviewCaches)
    .where(
      and(eq(reviewCaches.store, store), eq(reviewCaches.appId, appId), eq(reviewCaches.region, region)),
    )
    .limit(1);
  if (rows.length === 0) return c.json(err("not_collected"), 404);
  const cache = rows[0];
  const items = await loadItems(db, cache.id);
  const a = analyze(items.map(itemToJson));

  const fmtDate = (ms: number | null) =>
    ms ? new Date(ms).toISOString().slice(0, 19).replace("T", " ") : "";

  const infoSheet: Sheet = {
    name: "앱정보",
    rows: [
      ["항목", "값"],
      ["스토어", store === "play" ? "Google Play" : "App Store"],
      ["앱 ID", cache.appId],
      ["앱 이름", cache.title],
      ["지역", region],
      ["스토어 평균별점", cache.score ?? ""],
      ["총 평가 수", cache.ratings ?? ""],
      ["다운로드(표시)", cache.installs ?? ""],
      ["추정 설치 수", cache.realInstalls ?? ""],
      ["수집 리뷰 수", cache.reviewCount],
      ["수집 시각", fmtDate(cache.fetchedAt.getTime())],
    ],
  };

  const summarySheet: Sheet = {
    name: "별점요약",
    rows: [
      ["지표", "값"],
      ["수집 리뷰 평균별점", a.avgScore],
      ["긍정(4~5점)", a.positive],
      ["중립(3점)", a.neutral],
      ["부정(1~2점)", a.negative],
      ["불만율(%)", a.negativeRate],
      ["평균 도움돼요", a.avgThumbsUp],
      [],
      ["별점", "개수", "비율(%)"],
      ...a.distribution.map((n, i) => [`${i + 1}점`, n, a.distributionPct[i]]),
    ],
  };

  const keywordSheet: Sheet = {
    name: "키워드",
    rows: [
      ["불만 키워드(1~2점)", "빈도", "", "칭찬 키워드(4~5점)", "빈도"],
      ...Array.from({ length: Math.max(a.complaintKeywords.length, a.praiseKeywords.length) }).map(
        (_, i) => [
          a.complaintKeywords[i]?.word ?? "",
          a.complaintKeywords[i]?.count ?? "",
          "",
          a.praiseKeywords[i]?.word ?? "",
          a.praiseKeywords[i]?.count ?? "",
        ],
      ),
    ],
  };

  const trendSheet: Sheet = {
    name: "월별추이",
    rows: [["월", "리뷰수", "평균별점"], ...a.monthlyTrend.map((m) => [m.month, m.count, m.avg])],
  };

  const rawSheet: Sheet = {
    name: "리뷰원본",
    rows: [
      ["별점", "내용", "작성일", "도움돼요", "작성자", "버전"],
      ...items.map((r) => [
        r.score,
        r.content,
        fmtDate(r.at ? r.at.getTime() : null),
        r.thumbsUp,
        r.userName ?? "",
        r.version ?? "",
      ]),
    ],
  };

  const xlsx = buildXlsx([infoSheet, summarySheet, keywordSheet, trendSheet, rawSheet]);
  const safeName = `${store}-${cache.appId}-${region}`.replace(/[^\w.-]/g, "_");
  return c.body(xlsx as unknown as ArrayBuffer, 200, {
    "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "Content-Disposition": `attachment; filename="appreview-${safeName}.xlsx"`,
    "Cache-Control": "private, no-store",
  });
});

// ── 헬퍼 ──

type CacheRow = typeof reviewCaches.$inferSelect;
type ItemRow = typeof reviewItems.$inferSelect;

function cacheMeta(cache: CacheRow) {
  return {
    store: cache.store,
    appId: cache.appId,
    region: cache.region,
    title: cache.title,
    iconUrl: cache.iconUrl,
    score: cache.score,
    ratings: cache.ratings,
    installs: cache.installs,
    realInstalls: cache.realInstalls,
    reviewCount: cache.reviewCount,
    fetchedAt: cache.fetchedAt.getTime(),
  };
}

function itemToJson(r: ItemRow): ReviewRow {
  return {
    score: r.score,
    content: r.content,
    at: r.at ? r.at.getTime() : null,
    thumbsUp: r.thumbsUp,
    userName: r.userName,
    version: r.version,
  };
}

async function loadItems(db: ReturnType<typeof drizzle>, cacheId: number): Promise<ItemRow[]> {
  return db
    .select()
    .from(reviewItems)
    .where(eq(reviewItems.cacheId, cacheId))
    .orderBy(desc(reviewItems.at), asc(reviewItems.id));
}

// D1 바인딩 변수 한도(999)를 넘지 않도록 40행씩 나눠 삽입 (7컬럼 × 40 = 280)
async function insertItems(db: ReturnType<typeof drizzle>, cacheId: number, reviews: ReviewRow[]) {
  const CHUNK = 40;
  for (let i = 0; i < reviews.length; i += CHUNK) {
    const slice = reviews.slice(i, i + CHUNK).map((r) => ({
      cacheId,
      score: r.score,
      content: r.content.slice(0, 5000),
      at: r.at ? new Date(r.at) : null,
      thumbsUp: r.thumbsUp,
      userName: r.userName,
      version: r.version,
    }));
    await db.insert(reviewItems).values(slice);
  }
}

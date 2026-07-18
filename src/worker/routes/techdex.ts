// TechDex — IT/AI 용어 학습 게임 API
// 용어 DB(홈페이지 용어집 + 바이브코딩 용어) 조회 + 퀴즈 생성. 읽기는 공개, 시드는 admin.
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { and, eq, like, or, sql } from "drizzle-orm";
import { z } from "zod";
import { techdexTerms } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";
import { requireRole } from "../middleware";
import seedRaw from "../resources/techdex-seed.json?raw";

export const techdexRoutes = new Hono<{ Bindings: Env }>();

// 테이블 자동 생성 (마이그레이션 수동 적용 불필요, 아이소레이트당 1회)
let tablesReady = false;
async function ensureTables(db: ReturnType<typeof drizzle>) {
  if (tablesReady) return;
  await db.run(sql`CREATE TABLE IF NOT EXISTS techdex_terms (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    slug text NOT NULL, term text NOT NULL, sub text, def text NOT NULL,
    collection text NOT NULL, category text NOT NULL,
    difficulty integer DEFAULT 1 NOT NULL, vibe_core integer DEFAULT 0 NOT NULL, source text
  )`);
  await db.run(sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_techdex_slug ON techdex_terms (slug)`);
  await db.run(sql`CREATE INDEX IF NOT EXISTS idx_techdex_cat ON techdex_terms (collection, category)`);
  tablesReady = true;
}

type SeedRow = {
  slug: string;
  termKo: string;
  termEn: string | null;
  def: string;
  collection: string;
  category: string;
  difficulty: number;
  vibeCore: boolean;
  source: string | null;
};

// ── 시드 (admin, 멱등) — 번들 JSON을 D1에 적재 ──
techdexRoutes.post("/seed", requireRole("admin"), async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const force = c.req.query("force") === "1";
  const existing = await db.select({ n: sql<number>`count(*)` }).from(techdexTerms);
  const have = Number(existing[0]?.n ?? 0);
  if (have > 0 && !force) return c.json(ok({ already: true, count: have }));
  if (force) await db.run(sql`DELETE FROM techdex_terms`);

  const rows = JSON.parse(seedRaw) as SeedRow[];
  // D1 는 쿼리당 바인딩 파라미터 최대 100개 → 9컬럼 × 10행 = 90 이하로 나눠 삽입
  const CHUNK = 10;
  let inserted = 0;
  for (let i = 0; i < rows.length; i += CHUNK) {
    const slice = rows.slice(i, i + CHUNK).map((r) => ({
      slug: r.slug,
      term: r.termKo,
      sub: r.termEn ?? null,
      def: r.def,
      collection: r.collection,
      category: r.category,
      difficulty: Number.isFinite(r.difficulty) ? Math.min(4, Math.max(1, Math.round(r.difficulty))) : 1,
      vibeCore: !!r.vibeCore,
      source: r.source ?? null,
    }));
    await db.insert(techdexTerms).values(slice);
    inserted += slice.length;
  }
  return c.json(ok({ seeded: inserted }));
});

// ── 통계 (공개) ──
techdexRoutes.get("/stats", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const total = await db.select({ n: sql<number>`count(*)` }).from(techdexTerms);
  const byColl = await db
    .select({ collection: techdexTerms.collection, n: sql<number>`count(*)` })
    .from(techdexTerms)
    .groupBy(techdexTerms.collection);
  const vibeCore = await db
    .select({ n: sql<number>`count(*)` })
    .from(techdexTerms)
    .where(eq(techdexTerms.vibeCore, true));
  return c.json(
    ok({
      total: Number(total[0]?.n ?? 0),
      byCollection: byColl.map((r) => ({ collection: r.collection, count: Number(r.n) })),
      vibeCore: Number(vibeCore[0]?.n ?? 0),
    }),
  );
});

// ── 카테고리 목록 (공개) — 필터 칩용 ──
techdexRoutes.get("/categories", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const rows = await db
    .select({
      collection: techdexTerms.collection,
      category: techdexTerms.category,
      n: sql<number>`count(*)`,
    })
    .from(techdexTerms)
    .groupBy(techdexTerms.collection, techdexTerms.category)
    .orderBy(techdexTerms.collection, techdexTerms.category);
  return c.json(ok({ categories: rows.map((r) => ({ ...r, count: Number(r.n) })) }));
});

const COLLS = ["ai", "app", "vibe"] as const;

// ── 용어 목록 (공개) — 도감/검색 ──
techdexRoutes.get("/terms", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const q = (c.req.query("q") ?? "").trim().slice(0, 60);
  const collection = c.req.query("collection");
  const category = c.req.query("category");
  const limit = Math.min(Number(c.req.query("limit") ?? 60) || 60, 200);
  const offset = Math.max(Number(c.req.query("offset") ?? 0) || 0, 0);

  const conds = [];
  if (collection && COLLS.includes(collection as (typeof COLLS)[number]))
    conds.push(eq(techdexTerms.collection, collection));
  if (category) conds.push(eq(techdexTerms.category, category));
  if (q) {
    const p = `%${q}%`;
    conds.push(or(like(techdexTerms.term, p), like(techdexTerms.sub, p), like(techdexTerms.def, p))!);
  }
  const where = conds.length ? and(...conds) : undefined;

  const total = await db.select({ n: sql<number>`count(*)` }).from(techdexTerms).where(where);
  const rows = await db
    .select({
      id: techdexTerms.id,
      slug: techdexTerms.slug,
      term: techdexTerms.term,
      sub: techdexTerms.sub,
      def: techdexTerms.def,
      collection: techdexTerms.collection,
      category: techdexTerms.category,
      difficulty: techdexTerms.difficulty,
      vibeCore: techdexTerms.vibeCore,
    })
    .from(techdexTerms)
    .where(where)
    .orderBy(techdexTerms.term)
    .limit(limit)
    .offset(offset);
  return c.json(ok({ total: Number(total[0]?.n ?? 0), terms: rows }));
});

// ── 퀴즈 생성 (공개) — 정의를 보고 용어 맞히기(4지선다) ──
const quizQuery = z.object({
  count: z.coerce.number().int().min(1).max(20).optional(),
  collection: z.enum(COLLS).optional(),
  category: z.string().max(60).optional(),
  vibeCore: z.coerce.boolean().optional(),
});

function shuffle<T>(a: T[]): T[] {
  // Fisher–Yates (crypto 난수)
  for (let i = a.length - 1; i > 0; i--) {
    const j = crypto.getRandomValues(new Uint32Array(1))[0] % (i + 1);
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

type PoolTerm = {
  slug: string;
  term: string;
  sub: string | null;
  def: string;
  category: string;
  collection: string;
  difficulty: number;
};

techdexRoutes.get("/quiz", async (c) => {
  const parsed = quizQuery.safeParse({
    count: c.req.query("count"),
    collection: c.req.query("collection"),
    category: c.req.query("category"),
    vibeCore: c.req.query("vibeCore"),
  });
  if (!parsed.success) return c.json(err("invalid_params"), 400);
  const count = parsed.data.count ?? 10;
  const db = drizzle(c.env.DB);
  await ensureTables(db);

  const conds = [];
  if (parsed.data.collection) conds.push(eq(techdexTerms.collection, parsed.data.collection));
  if (parsed.data.category) conds.push(eq(techdexTerms.category, parsed.data.category));
  if (parsed.data.vibeCore) conds.push(eq(techdexTerms.vibeCore, true));

  const cols = {
    slug: techdexTerms.slug,
    term: techdexTerms.term,
    sub: techdexTerms.sub,
    def: techdexTerms.def,
    category: techdexTerms.category,
    collection: techdexTerms.collection,
    difficulty: techdexTerms.difficulty,
  };
  const poolSize = Math.max(count * 5, 60);
  let pool: PoolTerm[] = await db
    .select(cols)
    .from(techdexTerms)
    .where(conds.length ? and(...conds) : undefined)
    .orderBy(sql`RANDOM()`)
    .limit(poolSize);

  // 오답 보기를 4개 만들 수 없으면 필터를 풀어 전체에서 보강
  if (pool.length < 4) {
    pool = await db.select(cols).from(techdexTerms).orderBy(sql`RANDOM()`).limit(poolSize);
  }
  if (pool.length < 4) return c.json(err("not_enough_terms"), 404);

  // 같은 표시 용어 중복 제거(보기 혼동 방지)
  const seenTerm = new Set<string>();
  const uniq = pool.filter((p) => (seenTerm.has(p.term) ? false : (seenTerm.add(p.term), true)));

  const answers = uniq.slice(0, Math.min(count, uniq.length));
  const questions = answers.map((ans) => {
    // 같은 카테고리 우선, 부족하면 아무 용어로 오답 3개
    const sameCat = uniq.filter((p) => p.term !== ans.term && p.category === ans.category);
    const others = uniq.filter((p) => p.term !== ans.term && p.category !== ans.category);
    const distractors = shuffle(sameCat).slice(0, 3);
    if (distractors.length < 3) distractors.push(...shuffle(others).slice(0, 3 - distractors.length));
    const choices = shuffle([ans, ...distractors].map((p) => p.term));
    return {
      slug: ans.slug,
      prompt: ans.def,
      choices,
      answer: ans.term,
      answerIndex: choices.indexOf(ans.term),
      reveal: { term: ans.term, sub: ans.sub, category: ans.category, collection: ans.collection },
    };
  });

  return c.json(ok({ count: questions.length, questions }));
});

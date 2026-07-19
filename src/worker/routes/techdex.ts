// TechDex — IT/AI 용어 학습 게임 API
// 용어 DB(홈페이지 용어집 + 바이브코딩 용어) 조회 + 퀴즈 생성. 읽기는 공개, 시드는 admin.
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { and, desc, eq, gte, like, lte, or, sql } from "drizzle-orm";
import { z } from "zod";
import { techdexTerms, techdexSuggestions, users } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";
import { requireRole, type AuthedUser } from "../middleware";
import seedRaw from "../resources/techdex-seed.json?raw";

type Vars = { Variables: { user: AuthedUser } };
export const techdexRoutes = new Hono<{ Bindings: Env } & Vars>();

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
  await db.run(sql`CREATE TABLE IF NOT EXISTS techdex_suggestions (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    term text NOT NULL, sub text, def text, category text, note text,
    user_id integer NOT NULL, status text DEFAULT 'pending' NOT NULL,
    created_at integer NOT NULL, reviewed_at integer, reviewed_by integer, term_id integer
  )`);
  await db.run(sql`CREATE INDEX IF NOT EXISTS idx_techdex_sugg_status ON techdex_suggestions (status)`);
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

const COLLS = ["ai", "app", "vibe", "user"] as const;

function slugify(s: string) {
  const base = (s || "")
    .toLowerCase()
    .replace(/[^a-z0-9가-힣]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return base || "term";
}

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
  level: z.enum(["beginner", "intermediate", "hard"]).optional(),
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
    level: c.req.query("level"),
  });
  if (!parsed.success) return c.json(err("invalid_params"), 400);
  const count = parsed.data.count ?? 10;
  const db = drizzle(c.env.DB);
  await ensureTables(db);

  const conds = [];
  if (parsed.data.collection) conds.push(eq(techdexTerms.collection, parsed.data.collection));
  if (parsed.data.category) conds.push(eq(techdexTerms.category, parsed.data.category));
  if (parsed.data.vibeCore) conds.push(eq(techdexTerms.vibeCore, true));
  // 난이도: 초급=쉬운 용어(≤2), 고급=어려운 용어(≥3), 중급=제한 없음
  if (parsed.data.level === "beginner") conds.push(lte(techdexTerms.difficulty, 2));
  else if (parsed.data.level === "hard") conds.push(gte(techdexTerms.difficulty, 3));

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

// ──────────────── 사용자 제안 용어 (검색 실패 → 추가 요청 → 관리자 검토) ────────────────

const suggestSchema = z.object({
  term: z.string().trim().min(1).max(80),
  sub: z.string().trim().max(80).optional(),
  def: z.string().trim().max(1000).optional(),
  category: z.string().trim().max(60).optional(),
  note: z.string().trim().max(500).optional(),
});

// 제안 제출 (member 이상)
techdexRoutes.post("/suggest", requireRole("member"), async (c) => {
  const parsed = suggestSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const me = c.get("user");

  // 이미 등록된 용어인지(대략) 확인 — 있으면 알려줌
  const exists = await db
    .select({ id: techdexTerms.id, term: techdexTerms.term })
    .from(techdexTerms)
    .where(or(eq(techdexTerms.term, d.term), eq(techdexTerms.slug, slugify(d.sub || d.term))))
    .limit(1);
  if (exists.length) return c.json(ok({ duplicate: true, term: exists[0].term }));

  // 같은 사용자가 같은 용어를 이미 대기중으로 제안했는지 (중복 방지)
  const dup = await db
    .select({ id: techdexSuggestions.id })
    .from(techdexSuggestions)
    .where(
      and(
        eq(techdexSuggestions.term, d.term),
        eq(techdexSuggestions.status, "pending"),
      ),
    )
    .limit(1);
  if (dup.length) return c.json(ok({ pending: true, already: true }));

  await db.insert(techdexSuggestions).values({
    term: d.term,
    sub: d.sub || null,
    def: d.def || null,
    category: d.category || null,
    note: d.note || null,
    userId: me.id,
    status: "pending",
    createdAt: new Date(),
  });
  return c.json(ok({ submitted: true }));
});

// 내 제안 목록 (member)
techdexRoutes.get("/suggestions/mine", requireRole("member"), async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const me = c.get("user");
  const rows = await db
    .select({
      id: techdexSuggestions.id,
      term: techdexSuggestions.term,
      status: techdexSuggestions.status,
      createdAt: techdexSuggestions.createdAt,
    })
    .from(techdexSuggestions)
    .where(eq(techdexSuggestions.userId, me.id))
    .orderBy(desc(techdexSuggestions.id))
    .limit(50);
  return c.json(ok({ suggestions: rows }));
});

// 대기중 제안 수 (admin) — 뱃지용
techdexRoutes.get("/suggestions/count", requireRole("admin"), async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const r = await db
    .select({ n: sql<number>`count(*)` })
    .from(techdexSuggestions)
    .where(eq(techdexSuggestions.status, "pending"));
  return c.json(ok({ pending: Number(r[0]?.n ?? 0) }));
});

// 제안 목록 (admin)
techdexRoutes.get("/suggestions", requireRole("admin"), async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const status = c.req.query("status") ?? "pending";
  const rows = await db
    .select({
      id: techdexSuggestions.id,
      term: techdexSuggestions.term,
      sub: techdexSuggestions.sub,
      def: techdexSuggestions.def,
      category: techdexSuggestions.category,
      note: techdexSuggestions.note,
      status: techdexSuggestions.status,
      createdAt: techdexSuggestions.createdAt,
      userName: users.name,
    })
    .from(techdexSuggestions)
    .leftJoin(users, eq(techdexSuggestions.userId, users.id))
    .where(eq(techdexSuggestions.status, status))
    .orderBy(desc(techdexSuggestions.id))
    .limit(200);
  return c.json(ok({ suggestions: rows }));
});

// 제안 승인 (admin) — techdex_terms 에 게시. 관리자가 값 보정 가능.
const approveSchema = z.object({
  term: z.string().trim().min(1).max(80),
  sub: z.string().trim().max(80).optional().nullable(),
  def: z.string().trim().min(1).max(1000),
  category: z.string().trim().min(1).max(60),
  collection: z.enum(COLLS).optional(),
  difficulty: z.coerce.number().int().min(1).max(4).optional(),
  vibeCore: z.coerce.boolean().optional(),
});

techdexRoutes.post("/suggestions/:id/approve", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = approveSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  await ensureTables(db);

  const sug = await db.select().from(techdexSuggestions).where(eq(techdexSuggestions.id, id)).limit(1);
  if (sug.length === 0) return c.json(err("not_found"), 404);
  if (sug[0].status !== "pending") return c.json(err("already_reviewed"), 400);

  // 고유 slug 생성
  let slug = slugify(d.sub || d.term);
  for (let i = 2; ; i++) {
    const clash = await db.select({ id: techdexTerms.id }).from(techdexTerms).where(eq(techdexTerms.slug, slug)).limit(1);
    if (clash.length === 0) break;
    slug = `${slugify(d.sub || d.term)}-${i}`;
  }

  const inserted = await db
    .insert(techdexTerms)
    .values({
      slug,
      term: d.term,
      sub: d.sub ?? null,
      def: d.def,
      collection: d.collection ?? "user",
      category: d.category,
      difficulty: d.difficulty ?? 2,
      vibeCore: !!d.vibeCore,
      source: "사용자 제안",
    })
    .returning({ id: techdexTerms.id });

  await db
    .update(techdexSuggestions)
    .set({ status: "approved", reviewedAt: new Date(), reviewedBy: c.get("user").id, termId: inserted[0].id })
    .where(eq(techdexSuggestions.id, id));
  return c.json(ok({ approved: true, termId: inserted[0].id }));
});

// 제안 거절 (admin)
techdexRoutes.post("/suggestions/:id/reject", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  await db
    .update(techdexSuggestions)
    .set({ status: "rejected", reviewedAt: new Date(), reviewedBy: c.get("user").id })
    .where(and(eq(techdexSuggestions.id, id), eq(techdexSuggestions.status, "pending")));
  return c.json(ok({ rejected: true }));
});

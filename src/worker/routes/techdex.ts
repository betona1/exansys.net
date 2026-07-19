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
  // 리텐션 MVP: 사용자 진행(스트릭·XP·레벨), 배지, 데일리 챌린지
  await db.run(sql`CREATE TABLE IF NOT EXISTS techdex_user_stats (
    user_id integer PRIMARY KEY NOT NULL,
    streak integer DEFAULT 0 NOT NULL, best_streak integer DEFAULT 0 NOT NULL,
    last_play_date text, last_daily_date text,
    freezes integer DEFAULT 1 NOT NULL, xp integer DEFAULT 0 NOT NULL, level integer DEFAULT 1 NOT NULL,
    updated_at integer NOT NULL
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS techdex_badges (
    user_id integer NOT NULL, code text NOT NULL, awarded_at integer NOT NULL
  )`);
  await db.run(sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_techdex_badge ON techdex_badges (user_id, code)`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS techdex_daily (date text PRIMARY KEY NOT NULL, slugs text NOT NULL)`);
  tablesReady = true;
}

// KST 기준 날짜(YYYY-MM-DD)
function kstDate(d = new Date()): string {
  return new Date(d.getTime() + 9 * 3600 * 1000).toISOString().slice(0, 10);
}
function daysBetween(a: string, b: string): number {
  return Math.round((Date.parse(b + "T00:00:00Z") - Date.parse(a + "T00:00:00Z")) / 86400000);
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

// 정의문을 퀴즈 힌트답게 다듬는다: 예시 제거 · 정답 노출 가림 · 길이 정리
function cleanClue(def: string, term: string, sub: string | null): string {
  let s = def.trim();
  s = s.replace(/\([^)]*예[^)]*\)/g, ""); // (예 ...) 괄호 속 예시 제거
  s = s.replace(/(?:예를 들어|예:)[\s\S]*$/, ""); // '예:' / '예를 들어' 이후 절 제거
  // 정답이 힌트에 그대로 노출되면 ○○ 로 가림
  for (const w of [term, sub].filter((x): x is string => !!x && x.trim().length >= 2)) {
    s = s.split(w).join("○○");
  }
  s = s.replace(/\s{2,}/g, " ").trim();
  if (s.length > 92) {
    const cut = s.slice(0, 92);
    const p = Math.max(cut.lastIndexOf("."), cut.lastIndexOf("·"), cut.lastIndexOf(" "));
    s = (p > 45 ? cut.slice(0, p) : cut).trim() + "…";
  }
  return s || def;
}

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
      prompt: cleanClue(ans.def, ans.term, ans.sub),
      choices,
      answer: ans.term,
      answerIndex: choices.indexOf(ans.term),
      reveal: { term: ans.term, sub: ans.sub, category: ans.category, collection: ans.collection },
    };
  });

  return c.json(ok({ count: questions.length, questions }));
});

// ──────────────── 십자풀이(가로세로 퍼즐) ────────────────
// 영문 단어를 교차시키고 한글 뜻을 힌트로 쓰는 크로스워드를 즉석 생성한다.

type CrossItem = { answer: string; clue: string; term: string; sub: string | null };
type Placed = CrossItem & { row: number; col: number; dir: "across" | "down" };

function buildCrossword(items: CrossItem[], maxWords: number) {
  const grid = new Map<string, string>();
  const placed: Placed[] = [];
  const key = (r: number, cc: number) => `${r},${cc}`;
  const at = (r: number, cc: number) => grid.get(key(r, cc));

  // 배치 가능 여부 + 교차 수 반환 (null이면 불가)
  function canPlace(word: string, r: number, cCol: number, dir: "across" | "down"): number | null {
    const dr = dir === "down" ? 1 : 0;
    const dc = dir === "across" ? 1 : 0;
    if (at(r - dr, cCol - dc)) return null; // 시작 앞칸 비어야
    if (at(r + dr * word.length, cCol + dc * word.length)) return null; // 끝 뒤칸 비어야
    let inter = 0;
    for (let i = 0; i < word.length; i++) {
      const rr = r + dr * i;
      const cc = cCol + dc * i;
      const cur = at(rr, cc);
      if (cur) {
        if (cur !== word[i]) return null;
        inter++;
      } else {
        // 교차가 아닌 새 칸은 수직 이웃이 비어 있어야 (평행 단어 붙음 방지)
        const pr = dc;
        const pc = dr;
        if (at(rr + pr, cc + pc) || at(rr - pr, cc - pc)) return null;
      }
    }
    return inter;
  }

  function doPlace(item: CrossItem, r: number, cCol: number, dir: "across" | "down") {
    const dr = dir === "down" ? 1 : 0;
    const dc = dir === "across" ? 1 : 0;
    for (let i = 0; i < item.answer.length; i++) grid.set(key(r + dr * i, cCol + dc * i), item.answer[i]);
    placed.push({ ...item, row: r, col: cCol, dir });
  }

  const sorted = [...items].sort((a, b) => b.answer.length - a.answer.length);
  const first = sorted.shift();
  if (!first) return null;
  doPlace(first, 0, 0, "across");

  for (const item of sorted) {
    if (placed.length >= maxWords) break;
    const word = item.answer;
    let best: { r: number; c: number; dir: "across" | "down"; inter: number } | null = null;
    for (let i = 0; i < word.length; i++) {
      for (const [k, letter] of grid) {
        if (letter !== word[i]) continue;
        const parts = k.split(",");
        const r = Number(parts[0]);
        const cCol = Number(parts[1]);
        for (const dir of ["across", "down"] as const) {
          const dr = dir === "down" ? 1 : 0;
          const dc = dir === "across" ? 1 : 0;
          const startR = r - dr * i;
          const startC = cCol - dc * i;
          const inter = canPlace(word, startR, startC, dir);
          if (inter !== null && inter >= 1 && (!best || inter > best.inter)) {
            best = { r: startR, c: startC, dir, inter };
          }
        }
      }
    }
    if (best) doPlace(item, best.r, best.c, best.dir);
  }

  if (placed.length < 3) return null;

  // 좌표 정규화
  let minR = Infinity;
  let minC = Infinity;
  let maxR = -Infinity;
  let maxC = -Infinity;
  for (const k of grid.keys()) {
    const parts = k.split(",");
    const r = Number(parts[0]);
    const cCol = Number(parts[1]);
    minR = Math.min(minR, r);
    minC = Math.min(minC, cCol);
    maxR = Math.max(maxR, r);
    maxC = Math.max(maxC, cCol);
  }
  const norm = placed.map((p) => ({ ...p, row: p.row - minR, col: p.col - minC }));

  // 시작 칸에 번호 부여 (좌→우, 위→아래)
  const startCells = [...new Set(norm.map((e) => `${e.row},${e.col}`))].sort((a, b) => {
    const [ar, ac] = a.split(",").map(Number);
    const [br, bc] = b.split(",").map(Number);
    return ar - br || ac - bc;
  });
  const numByCell = new Map<string, number>();
  startCells.forEach((k, i) => numByCell.set(k, i + 1));

  const entries = norm
    .map((e) => ({
      num: numByCell.get(`${e.row},${e.col}`)!,
      row: e.row,
      col: e.col,
      dir: e.dir,
      answer: e.answer,
      len: e.answer.length,
      clue: e.clue,
      term: e.term,
      sub: e.sub,
    }))
    .sort((a, b) => a.num - b.num || (a.dir < b.dir ? -1 : 1));

  return { rows: maxR - minR + 1, cols: maxC - minC + 1, entries };
}

const crosswordQuery = z.object({
  count: z.coerce.number().int().min(6).max(14).optional(),
  collection: z.enum(COLLS).optional(),
  level: z.enum(["beginner", "intermediate", "hard"]).optional(),
});

techdexRoutes.get("/crossword", async (c) => {
  const parsed = crosswordQuery.safeParse({
    count: c.req.query("count"),
    collection: c.req.query("collection"),
    level: c.req.query("level"),
  });
  if (!parsed.success) return c.json(err("invalid_params"), 400);
  const count = parsed.data.count ?? 10;
  const db = drizzle(c.env.DB);
  await ensureTables(db);

  const conds = [];
  if (parsed.data.collection) conds.push(eq(techdexTerms.collection, parsed.data.collection));
  if (parsed.data.level === "beginner") conds.push(lte(techdexTerms.difficulty, 2));
  else if (parsed.data.level === "hard") conds.push(gte(techdexTerms.difficulty, 3));

  const cols = { term: techdexTerms.term, sub: techdexTerms.sub, def: techdexTerms.def };
  const fetchPool = (where: ReturnType<typeof and> | undefined) =>
    db.select(cols).from(techdexTerms).where(where).orderBy(sql`RANDOM()`).limit(140);

  // 영문 정답(3~8자 단일 단어) 후보만 추림
  const toCandidates = (rows: { term: string; sub: string | null; def: string }[]): CrossItem[] => {
    const seen = new Set<string>();
    const out: CrossItem[] = [];
    for (const r of rows) {
      const src = [r.sub ?? "", r.term].find((s) => /^[A-Za-z]{3,8}$/.test(s.trim()));
      if (!src) continue;
      const answer = src.trim().toUpperCase();
      if (seen.has(answer)) continue;
      seen.add(answer);
      out.push({ answer, clue: r.def, term: r.term, sub: r.sub });
    }
    return out;
  };

  let candidates = toCandidates(await fetchPool(conds.length ? and(...conds) : undefined));
  if (candidates.length < 8) candidates = toCandidates(await fetchPool(undefined));
  if (candidates.length < 6) return c.json(err("not_enough_words"), 404);

  const puzzle = buildCrossword(candidates, count);
  if (!puzzle) return c.json(err("generate_failed"), 500);
  return c.json(ok(puzzle));
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

// ──────────────── 리텐션 MVP: 진행(스트릭·XP·레벨)·배지·데일리 챌린지 ────────────────

type StatsRow = {
  user_id: number;
  streak: number;
  best_streak: number;
  last_play_date: string | null;
  last_daily_date: string | null;
  freezes: number;
  xp: number;
  level: number;
};

async function getOrInitStats(DB: D1Database, uid: number): Promise<StatsRow> {
  let s = await DB.prepare("SELECT * FROM techdex_user_stats WHERE user_id=?").bind(uid).first<StatsRow>();
  if (!s) {
    await DB.prepare("INSERT OR IGNORE INTO techdex_user_stats (user_id, updated_at) VALUES (?,?)")
      .bind(uid, Date.now())
      .run();
    s = await DB.prepare("SELECT * FROM techdex_user_stats WHERE user_id=?").bind(uid).first<StatsRow>();
  }
  return s!;
}

async function badgeCodes(DB: D1Database, uid: number): Promise<string[]> {
  const r = await DB.prepare("SELECT code FROM techdex_badges WHERE user_id=?").bind(uid).all<{ code: string }>();
  return (r.results ?? []).map((x) => x.code);
}

async function awardBadges(DB: D1Database, uid: number, codes: string[]): Promise<string[]> {
  const now = Date.now();
  const newly: string[] = [];
  for (const code of codes) {
    const r = await DB.prepare("INSERT OR IGNORE INTO techdex_badges (user_id, code, awarded_at) VALUES (?,?,?)")
      .bind(uid, code, now)
      .run();
    if (r.meta.changes > 0) newly.push(code);
  }
  return newly;
}

const progressSchema = z.object({
  correct: z.coerce.number().int().min(0).max(50),
  total: z.coerce.number().int().min(1).max(50),
  mode: z.enum(["quiz", "crossword", "daily"]).optional(),
});

// 세션 완료 후 진행 반영 (member)
techdexRoutes.post("/progress", requireRole("member"), async (c) => {
  const parsed = progressSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const { correct, mode } = parsed.data;
  const DB = c.env.DB;
  const db = drizzle(DB);
  await ensureTables(db);
  const uid = c.get("user").id;
  const s = await getOrInitStats(DB, uid);
  const today = kstDate();

  const gained = correct * 10 + (mode === "daily" ? 20 : 0);
  let streakEvent = "same";
  if (s.last_play_date !== today) {
    if (!s.last_play_date) {
      s.streak = 1;
      streakEvent = "start";
    } else {
      const gap = daysBetween(s.last_play_date, today);
      if (gap === 1) {
        s.streak += 1;
        streakEvent = "inc";
      } else if (gap > 1) {
        const missed = gap - 1;
        if (s.freezes >= missed) {
          s.freezes -= missed;
          s.streak += 1;
          streakEvent = "freeze";
        } else {
          s.streak = 1;
          streakEvent = "reset";
        }
      }
    }
    s.last_play_date = today;
    if (s.streak > s.best_streak) s.best_streak = s.streak;
    if (s.streak % 7 === 0 && s.freezes < 2) s.freezes += 1; // 7일 연속마다 프리즈 +1(최대 2)
  }
  if (mode === "daily") s.last_daily_date = today;
  s.xp += gained;
  s.level = Math.floor(s.xp / 100) + 1;

  await DB.prepare(
    `UPDATE techdex_user_stats SET streak=?, best_streak=?, last_play_date=?, last_daily_date=?,
       freezes=?, xp=?, level=?, updated_at=? WHERE user_id=?`,
  )
    .bind(s.streak, s.best_streak, s.last_play_date, s.last_daily_date, s.freezes, s.xp, s.level, Date.now(), uid)
    .run();

  const codes = ["onboard"];
  if (correct > 0) codes.push("first_correct");
  if (s.streak >= 3) codes.push("streak3");
  if (s.streak >= 10) codes.push("streak10");
  if (s.streak >= 30) codes.push("streak30");
  if (s.streak >= 100) codes.push("streak100");
  if (s.level >= 5) codes.push("level5");
  if (s.level >= 10) codes.push("level10");
  const newBadges = await awardBadges(DB, uid, codes);

  return c.json(
    ok({
      stats: {
        streak: s.streak,
        bestStreak: s.best_streak,
        freezes: s.freezes,
        xp: s.xp,
        level: s.level,
        lastDailyDate: s.last_daily_date,
      },
      gainedXp: gained,
      streakEvent,
      newBadges,
    }),
  );
});

// 내 스탯 (member)
techdexRoutes.get("/me/stats", requireRole("member"), async (c) => {
  const DB = c.env.DB;
  await ensureTables(drizzle(DB));
  const uid = c.get("user").id;
  const s = await getOrInitStats(DB, uid);
  const badges = await badgeCodes(DB, uid);
  return c.json(
    ok({
      streak: s.streak,
      bestStreak: s.best_streak,
      freezes: s.freezes,
      xp: s.xp,
      level: s.level,
      lastDailyDate: s.last_daily_date,
      today: kstDate(),
      badges,
    }),
  );
});

type TermLite = { slug: string; term: string; sub: string | null; def: string; category: string; collection: string };

function makeQuestions(answers: TermLite[], pool: TermLite[]) {
  const seen = new Set<string>();
  const uniqPool = pool.filter((p) => (seen.has(p.term) ? false : (seen.add(p.term), true)));
  return answers.map((ans) => {
    const sameCat = uniqPool.filter((p) => p.term !== ans.term && p.category === ans.category);
    const others = uniqPool.filter((p) => p.term !== ans.term && p.category !== ans.category);
    const distractors = shuffle(sameCat).slice(0, 3);
    if (distractors.length < 3) distractors.push(...shuffle(others).slice(0, 3 - distractors.length));
    const choices = shuffle([ans, ...distractors].map((p) => p.term));
    return {
      slug: ans.slug,
      prompt: cleanClue(ans.def, ans.term, ans.sub),
      choices,
      answer: ans.term,
      answerIndex: choices.indexOf(ans.term),
      reveal: { term: ans.term, sub: ans.sub, category: ans.category, collection: ans.collection },
    };
  });
}

// 오늘의 용어(데일리 챌린지, 공개) — 전원 동일한 5문제
techdexRoutes.get("/daily", async (c) => {
  const DB = c.env.DB;
  await ensureTables(drizzle(DB));
  const today = kstDate();
  let row = await DB.prepare("SELECT slugs FROM techdex_daily WHERE date=?").bind(today).first<{ slugs: string }>();
  if (!row) {
    const picked = await DB.prepare("SELECT slug FROM techdex_terms ORDER BY RANDOM() LIMIT 5").all<{ slug: string }>();
    const slugs = (picked.results ?? []).map((x) => x.slug);
    await DB.prepare("INSERT OR IGNORE INTO techdex_daily (date, slugs) VALUES (?,?)").bind(today, JSON.stringify(slugs)).run();
    row = { slugs: JSON.stringify(slugs) };
  }
  const slugs = JSON.parse(row.slugs) as string[];
  if (slugs.length === 0) return c.json(err("not_ready"), 404);
  const ph = slugs.map(() => "?").join(",");
  const ansRes = await DB.prepare(
    `SELECT slug,term,sub,def,category,collection FROM techdex_terms WHERE slug IN (${ph})`,
  )
    .bind(...slugs)
    .all<TermLite>();
  const poolRes = await DB.prepare(
    "SELECT slug,term,sub,def,category,collection FROM techdex_terms ORDER BY RANDOM() LIMIT 60",
  ).all<TermLite>();
  // 데일리 순서 유지
  const bySlug = new Map((ansRes.results ?? []).map((r) => [r.slug, r]));
  const answers = slugs.map((s) => bySlug.get(s)).filter((x): x is TermLite => !!x);
  const questions = makeQuestions(answers, poolRes.results ?? []);
  return c.json(ok({ date: today, count: questions.length, questions }));
});

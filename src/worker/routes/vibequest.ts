// VibeQuest 앱 지원 API — 문제 신고 게시판 + 원격 콘텐츠 (TECHSPEC §15.3)
// 앱은 로그인이 없으므로 신고 접수는 공개(IP 해시 레이트리밋), 관리는 staff 이상.
import { Hono } from "hono";
import { z } from "zod";
import glossaryRaw from "../resources/vibequest-glossary.json?raw";
import type { Env } from "../types";
import { ok, err } from "../types";
import { requireRole, type AuthedUser } from "../middleware";

type Vars = { Variables: { user: AuthedUser } };
export const vibequestRoutes = new Hono<{ Bindings: Env } & Vars>();

// ── 테이블 (런타임 생성) ──
let _ready = false;
async function ensureTables(DB: D1Database) {
  if (_ready) return;
  await DB.prepare(
    `CREATE TABLE IF NOT EXISTS vq_reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      term_id TEXT NOT NULL,
      term_ko TEXT NOT NULL,
      question_type TEXT,
      reason TEXT NOT NULL,
      detail TEXT,
      status TEXT NOT NULL DEFAULT 'open',
      ip_hash TEXT,
      created_date TEXT,
      created_at INTEGER NOT NULL,
      resolved_at INTEGER,
      resolved_by INTEGER
    )`,
  ).run();
  await DB.prepare(
    `CREATE TABLE IF NOT EXISTS vq_term_overrides (
      term_id TEXT PRIMARY KEY,
      patch_json TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      updated_by INTEGER
    )`,
  ).run();
  await DB.prepare(
    `CREATE TABLE IF NOT EXISTS vq_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)`,
  ).run();
  _ready = true;
}

async function getVersion(DB: D1Database): Promise<number> {
  const row = await DB.prepare("SELECT value FROM vq_meta WHERE key='contentVersion'").first<{ value: string }>();
  return row ? Number(row.value) || 1 : 1;
}

async function bumpVersion(DB: D1Database): Promise<number> {
  const v = (await getVersion(DB)) + 1;
  await DB.prepare(
    "INSERT INTO vq_meta (key, value) VALUES ('contentVersion', ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
  ).bind(String(v)).run();
  return v;
}

type TermRow = Record<string, unknown> & { id: string };

async function mergedGlossary(DB: D1Database): Promise<TermRow[]> {
  const base = JSON.parse(glossaryRaw) as TermRow[];
  const { results } = await DB.prepare("SELECT term_id, patch_json FROM vq_term_overrides").all<{
    term_id: string;
    patch_json: string;
  }>();
  if (!results?.length) return base;
  const patches = new Map(results.map((r) => [r.term_id, JSON.parse(r.patch_json) as Record<string, unknown>]));
  return base.map((t) => {
    const p = patches.get(t.id);
    return p ? { ...t, ...p } : t;
  });
}

async function sha256hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// ── 원격 콘텐츠 (§15.3) ──
vibequestRoutes.get("/content/meta", async (c) => {
  await ensureTables(c.env.DB);
  const body = JSON.stringify(await mergedGlossary(c.env.DB));
  return c.json(
    ok({
      contentVersion: await getVersion(c.env.DB),
      glossaryUrl: "/api/vibequest/content/glossary.json",
      sha256: await sha256hex(body),
      publishedAt: new Date().toISOString(),
    }),
  );
});

vibequestRoutes.get("/content/glossary.json", async (c) => {
  await ensureTables(c.env.DB);
  const body = JSON.stringify(await mergedGlossary(c.env.DB));
  return c.body(body, 200, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "public, max-age=300",
  });
});

// 단일 용어 (관리자 편집 화면용 — 병합본)
vibequestRoutes.get("/terms/:id", async (c) => {
  await ensureTables(c.env.DB);
  const t = (await mergedGlossary(c.env.DB)).find((x) => x.id === c.req.param("id"));
  if (!t) return c.json(err("not_found"), 404);
  return c.json(ok({ term: t }));
});

// ── 신고 접수 (공개, 레이트리밋) ──
const reportSchema = z.object({
  termId: z.string().min(1).max(40),
  termKo: z.string().min(1).max(120),
  questionType: z.string().max(20).optional().nullable(),
  reason: z.enum(["wrong_answer", "typo", "bad_explanation", "other"]),
  detail: z.string().max(1000).optional().nullable(),
});

async function hashIp(ip: string): Promise<string> {
  return (await sha256hex(`vq:${ip}`)).slice(0, 24);
}

vibequestRoutes.post("/reports", async (c) => {
  await ensureTables(c.env.DB);
  const parsed = reportSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;
  const ip = c.req.header("CF-Connecting-IP") ?? "0.0.0.0";
  const ipHash = await hashIp(ip);
  const today = new Date().toISOString().slice(0, 10);
  const cnt = await c.env.DB.prepare(
    "SELECT count(*) AS n FROM vq_reports WHERE ip_hash=? AND created_date=?",
  ).bind(ipHash, today).first<{ n: number }>();
  if ((cnt?.n ?? 0) >= 30) return c.json(err("too_many_reports"), 429);
  await c.env.DB.prepare(
    `INSERT INTO vq_reports (term_id, term_ko, question_type, reason, detail, status, ip_hash, created_date, created_at)
     VALUES (?,?,?,?,?,'open',?,?,?)`,
  )
    .bind(d.termId, d.termKo, d.questionType ?? null, d.reason, d.detail || null, ipHash, today, Date.now())
    .run();
  return c.json(ok({ reported: true }));
});

// ── 신고 게시판 (공개 열람) ──
vibequestRoutes.get("/reports", async (c) => {
  await ensureTables(c.env.DB);
  const { results } = await c.env.DB.prepare(
    `SELECT id, term_id AS termId, term_ko AS termKo, question_type AS questionType,
            reason, detail, status, created_at AS createdAt, resolved_at AS resolvedAt
     FROM vq_reports ORDER BY id DESC LIMIT 200`,
  ).all();
  return c.json(ok({ reports: results ?? [] }));
});

// ── 관리 (staff+): 상태 변경 ──
vibequestRoutes.post("/reports/:id/status", requireRole("staff"), async (c) => {
  await ensureTables(c.env.DB);
  const id = Number(c.req.param("id"));
  const body = (await c.req.json().catch(() => null)) as { status?: string } | null;
  if (!Number.isInteger(id) || !["open", "fixed", "rejected"].includes(body?.status ?? ""))
    return c.json(err("invalid_input"), 400);
  await c.env.DB.prepare(
    "UPDATE vq_reports SET status=?, resolved_at=?, resolved_by=? WHERE id=?",
  )
    .bind(body!.status, body!.status === "open" ? null : Date.now(), c.get("user").id, id)
    .run();
  return c.json(ok({ updated: true }));
});

// ── 관리 (staff+): 용어 수정(오버라이드) → 콘텐츠 버전 상승 → 앱이 받아감 ──
const patchSchema = z
  .object({
    termKo: z.string().min(1).max(120).optional(),
    termEn: z.string().max(200).optional(),
    def: z.string().min(1).max(1000).optional(),
    whyItMatters: z.string().max(500).optional(),
    example: z.string().max(500).optional(),
    aliases: z.array(z.string().max(80)).max(10).optional(),
    confusionSet: z.array(z.string().max(80)).max(6).optional(),
    difficulty: z.number().int().min(1).max(4).optional(),
    quizEnabled: z.boolean().optional(),
  })
  .strict();

vibequestRoutes.put("/terms/:id", requireRole("staff"), async (c) => {
  await ensureTables(c.env.DB);
  const id = c.req.param("id");
  const base = (JSON.parse(glossaryRaw) as TermRow[]).find((x) => x.id === id);
  if (!base) return c.json(err("not_found"), 404);
  const parsed = patchSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err(parsed.error.issues[0]?.message ?? "invalid_input"), 400);
  // 기존 오버라이드와 병합 저장
  const prev = await c.env.DB.prepare("SELECT patch_json FROM vq_term_overrides WHERE term_id=?")
    .bind(id)
    .first<{ patch_json: string }>();
  const merged = { ...(prev ? JSON.parse(prev.patch_json) : {}), ...parsed.data };
  await c.env.DB.prepare(
    `INSERT INTO vq_term_overrides (term_id, patch_json, updated_at, updated_by) VALUES (?,?,?,?)
     ON CONFLICT(term_id) DO UPDATE SET patch_json=excluded.patch_json, updated_at=excluded.updated_at, updated_by=excluded.updated_by`,
  )
    .bind(id, JSON.stringify(merged), Date.now(), c.get("user").id)
    .run();
  const version = await bumpVersion(c.env.DB);
  return c.json(ok({ term: { ...base, ...merged }, contentVersion: version }));
});

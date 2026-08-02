/**
 * ExaPDF 앱 계정·권한 API.
 *
 * 앱은 브라우저가 없거나(윈도우), 쿠키를 공유할 수 없는 곳(안드로이드)에서도
 * 돌아야 한다. 그래서 **연결 코드 방식**을 쓴다 — 앱이 여섯 자리 코드를
 * 보여 주고, 사용자는 아무 브라우저에서 로그인한 뒤 그 코드를 넣는다.
 * 앱 안에 로그인 창을 띄우지 않으므로 앱이 비밀번호를 볼 일이 없다.
 *
 *   앱                     웹(exansys.net)
 *   ├─ POST link/start  →  코드 발급 (KV, 10분)
 *   │  "ABCD-12" 표시
 *   │                      사용자가 /link 에서 로그인 후 코드 입력
 *   │                   ←  POST link/confirm 으로 사용자와 묶임
 *   └─ GET link/poll    →  앱 토큰 발급 (KV, 1년)
 *
 * 결제는 아직 없다. `plan` 은 admin 이 손으로 켜 준다 (Phase C 에서 PG 연동).
 */
import { Hono } from "hono";
import type { Context } from "hono";
import { eq } from "drizzle-orm";
import { drizzle } from "drizzle-orm/d1";

import { users } from "../../db/schema";
import { readSession } from "../auth/session";
import { ensureColumns } from "../lib/ensure-columns";
import { err, ok, type Env } from "../types";

export const exapdfRoutes = new Hono<{ Bindings: Env }>();

/** 연결 코드는 짧게 산다. 화면에 떠 있는 동안만 쓸 것이다 */
const LINK_TTL = 10 * 60;

/** 앱 토큰은 오래 산다. 매번 다시 연결하게 하면 아무도 안 쓴다 */
const APP_TOKEN_TTL = 365 * 24 * 60 * 60;

/** 유료 기능 목록. 앱과 웹이 같은 이름을 쓴다 */
const PRO_FEATURES = ["ocr", "image_to_text"] as const;

/** users 에 요금제 컬럼을 보정한다 (마이그레이션 없이도 동작하도록) */
const PLAN_COLUMNS = [
  { name: "plan", ddl: "plan text DEFAULT 'free' NOT NULL" },
  { name: "pro_until", ddl: "pro_until integer" },
];

/** 헷갈리는 글자를 뺀다 — 0/O, 1/I/l 은 사람이 반드시 잘못 읽는다 */
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

function newCode(): string {
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  const s = Array.from(bytes, (b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join("");
  return `${s.slice(0, 3)}-${s.slice(3)}`;
}

function randomToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

type LinkState = { device: string; userId?: number };

/** 지금 이 요청이 누구인지 — 앱 토큰(Bearer) 또는 웹 세션 쿠키.
 *
 * 둘을 다 받는 이유: 안드로이드·윈도우 앱은 쿠키가 없어 토큰을 쓰고,
 * 웹 PWA 는 같은 상위 도메인이라 쿠키가 그대로 간다 */
async function currentUserId(c: Context<{ Bindings: Env }>) {
  const auth = c.req.header("Authorization") ?? "";
  if (auth.startsWith("Bearer ")) {
    const raw = await c.env.SESSIONS.get(`exapdf:tok:${auth.slice(7)}`);
    if (raw) return Number(raw);
    return null;
  }
  const session = await readSession(c);
  return session?.userId ?? null;
}

/** 요금제를 읽어 앱이 쓸 모양으로 만든다 */
async function entitlement(env: Env, userId: number) {
  const db = drizzle(env.DB);
  await ensureColumns(db, "users", PLAN_COLUMNS);
  const rows = await db
    .select()
    .from(users)
    .where(eq(users.id, userId))
    .limit(1);
  const row = rows[0] as (typeof rows)[0] & { plan?: string; pro_until?: number | null };
  if (!row) return null;

  const proUntil = (row as { pro_until?: number | null }).pro_until ?? null;
  // 기한이 지났으면 무료로 본다. 만료를 배치로 지우지 않는 이유는,
  // 지우는 배치가 죽으면 유료가 영원히 유지되기 때문이다
  const active =
    ((row as { plan?: string }).plan ?? "free") === "pro" &&
    (proUntil === null || proUntil * 1000 > Date.now());

  return {
    userId: row.id,
    name: row.name,
    avatarUrl: row.avatarUrl,
    role: row.role,
    plan: active ? "pro" : "free",
    proUntil: active ? proUntil : null,
    features: active ? [...PRO_FEATURES] : [],
  };
}

/** 앱이 연결을 시작한다. 코드와 기기 번호를 받아 간다 */
exapdfRoutes.post("/link/start", async (c) => {
  const device = randomToken();
  const code = newCode();
  const state: LinkState = { device };
  await c.env.SESSIONS.put(`exapdf:link:${code}`, JSON.stringify(state), {
    expirationTtl: LINK_TTL,
  });
  await c.env.SESSIONS.put(`exapdf:dev:${device}`, code, { expirationTtl: LINK_TTL });
  return c.json(ok({ code, device, expiresIn: LINK_TTL }));
});

/** 사용자가 브라우저에서 코드를 넣는다. 로그인돼 있어야 한다 */
exapdfRoutes.post("/link/confirm", async (c) => {
  const session = await readSession(c);
  if (!session) return c.json(err("login_required"), 401);

  const body = await c.req.json<{ code?: string }>().catch(() => ({}) as { code?: string });
  const code = (body.code ?? "").trim().toUpperCase();
  if (!/^[A-Z0-9]{3}-[A-Z0-9]{3}$/.test(code)) return c.json(err("bad_code"), 400);

  const raw = await c.env.SESSIONS.get(`exapdf:link:${code}`);
  if (!raw) return c.json(err("expired"), 404);

  const state = JSON.parse(raw) as LinkState;
  state.userId = session.userId;
  await c.env.SESSIONS.put(`exapdf:link:${code}`, JSON.stringify(state), {
    expirationTtl: LINK_TTL,
  });
  return c.json(ok({ linked: true }));
});

/** 앱이 결과를 기다린다. 묶였으면 앱 토큰을 준다 */
exapdfRoutes.get("/link/poll", async (c) => {
  const device = c.req.query("device") ?? "";
  if (!device) return c.json(err("bad_device"), 400);

  const code = await c.env.SESSIONS.get(`exapdf:dev:${device}`);
  if (!code) return c.json(err("expired"), 404);

  const raw = await c.env.SESSIONS.get(`exapdf:link:${code}`);
  if (!raw) return c.json(err("expired"), 404);

  const state = JSON.parse(raw) as LinkState;
  if (!state.userId) return c.json(ok({ pending: true }));

  // 한 번 쓴 코드는 바로 버린다. 어깨너머로 본 사람이 다시 못 쓰게
  await c.env.SESSIONS.delete(`exapdf:link:${code}`);
  await c.env.SESSIONS.delete(`exapdf:dev:${device}`);

  const token = randomToken();
  await c.env.SESSIONS.put(`exapdf:tok:${token}`, String(state.userId), {
    expirationTtl: APP_TOKEN_TTL,
  });
  const me = await entitlement(c.env, state.userId);
  return c.json(ok({ pending: false, token, me }));
});

/** 지금 내 계정과 권한. 앱이 켜질 때마다 확인한다 */
exapdfRoutes.get("/me", async (c) => {
  const userId = await currentUserId(c);
  if (userId === null) return c.json(err("login_required"), 401);
  const me = await entitlement(c.env, userId);
  if (!me) return c.json(err("not_found"), 404);
  return c.json(ok(me));
});

/** 앱에서 로그아웃 — 이 기기의 토큰만 버린다 */
exapdfRoutes.post("/logout", async (c) => {
  const auth = c.req.header("Authorization") ?? "";
  if (auth.startsWith("Bearer ")) {
    await c.env.SESSIONS.delete(`exapdf:tok:${auth.slice(7)}`);
  }
  return c.json(ok({ loggedOut: true }));
});

/**
 * 요금제를 손으로 켜고 끈다 (admin 전용).
 *
 * 결제(PG) 가 붙기 전까지의 임시 통로다. 결제가 붙으면 결제 성공 훅이
 * 같은 자리를 부르면 된다 — 여기 로직을 그대로 쓴다.
 */
exapdfRoutes.post("/admin/plan", async (c) => {
  const session = await readSession(c);
  if (!session) return c.json(err("login_required"), 401);
  if (session.role !== "admin") return c.json(err("forbidden"), 403);

  const body = await c.req
    .json<{ userId?: number; plan?: string; days?: number }>()
    .catch(() => ({}) as { userId?: number; plan?: string; days?: number });
  const userId = Number(body.userId);
  const plan = body.plan === "pro" ? "pro" : "free";
  const days = Number.isFinite(body.days) ? Number(body.days) : 30;
  if (!Number.isFinite(userId) || userId <= 0) return c.json(err("bad_user"), 400);

  const db = drizzle(c.env.DB);
  await ensureColumns(db, "users", PLAN_COLUMNS);
  const until =
    plan === "pro" ? Math.floor(Date.now() / 1000) + days * 24 * 60 * 60 : null;
  await db
    .update(users)
    .set({ plan, pro_until: until } as unknown as Partial<typeof users.$inferInsert>)
    .where(eq(users.id, userId));

  const me = await entitlement(c.env, userId);
  return c.json(ok(me));
});



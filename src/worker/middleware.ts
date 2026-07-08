import type { Context, Next } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { eq } from "drizzle-orm";
import { users } from "../db/schema";
import type { Env, Role } from "./types";
import { ROLE_LEVEL, err } from "./types";
import { readSession } from "./auth/session";

export type AuthedUser = {
  id: number;
  name: string;
  role: Role;
};

/** 세션 + DB 최신 역할 기준으로 minRole 이상만 통과 */
export function requireRole(minRole: Role) {
  return async (
    c: Context<{ Bindings: Env; Variables: { user: AuthedUser } }>,
    next: Next,
  ) => {
    const sess = await readSession(c);
    if (!sess) return c.json(err("unauthorized"), 401);
    const db = drizzle(c.env.DB);
    const rows = await db.select().from(users).where(eq(users.id, sess.userId)).limit(1);
    if (rows.length === 0) return c.json(err("unauthorized"), 401);
    const role = rows[0].role as Role;
    if (ROLE_LEVEL[role] < ROLE_LEVEL[minRole]) return c.json(err("forbidden"), 403);
    c.set("user", { id: rows[0].id, name: rows[0].name, role });
    await next();
  };
}

import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { asc, eq } from "drizzle-orm";
import { z } from "zod";
import { apps, users } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";
import { requireRole, type AuthedUser } from "../middleware";

const appSchema = z.object({
  slug: z
    .string()
    .min(2)
    .max(50)
    .regex(/^[a-z0-9-]+$/, "slug는 소문자·숫자·하이픈만"),
  name: z.string().min(1).max(80),
  tagline: z.string().max(120).optional().nullable(),
  description: z.string().max(4000).optional().nullable(),
  iconUrl: z.string().max(500).optional().nullable(),
  storeUrlAndroid: z.string().url().max(500).optional().nullable().or(z.literal("")),
  storeUrlIos: z.string().url().max(500).optional().nullable().or(z.literal("")),
  status: z.enum(["planning", "development", "released"]),
});

const roleSchema = z.object({
  role: z.enum(["member", "crew", "staff", "admin"]),
});

type Vars = { Variables: { user: AuthedUser } };

export const adminRoutes = new Hono<{ Bindings: Env } & Vars>();

// 앱 등록/수정/삭제는 admin 전용 (CLAUDE.md 3절)
adminRoutes.post("/apps", requireRole("admin"), async (c) => {
  const parsed = appSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err(parsed.error.issues[0]?.message ?? "invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  const dup = await db.select({ id: apps.id }).from(apps).where(eq(apps.slug, d.slug)).limit(1);
  if (dup.length > 0) return c.json(err("slug_exists"), 409);
  const inserted = await db
    .insert(apps)
    .values({
      slug: d.slug,
      name: d.name,
      tagline: d.tagline || null,
      description: d.description || null,
      iconUrl: d.iconUrl || null,
      storeUrlAndroid: d.storeUrlAndroid || null,
      storeUrlIos: d.storeUrlIos || null,
      status: d.status,
      createdAt: new Date(),
    })
    .returning();
  return c.json(ok({ app: inserted[0] }));
});

adminRoutes.put("/apps/:id", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = appSchema.partial().safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err(parsed.error.issues[0]?.message ?? "invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  const updated = await db
    .update(apps)
    .set({
      ...(d.slug !== undefined && { slug: d.slug }),
      ...(d.name !== undefined && { name: d.name }),
      ...(d.tagline !== undefined && { tagline: d.tagline || null }),
      ...(d.description !== undefined && { description: d.description || null }),
      ...(d.iconUrl !== undefined && { iconUrl: d.iconUrl || null }),
      ...(d.storeUrlAndroid !== undefined && { storeUrlAndroid: d.storeUrlAndroid || null }),
      ...(d.storeUrlIos !== undefined && { storeUrlIos: d.storeUrlIos || null }),
      ...(d.status !== undefined && { status: d.status }),
    })
    .where(eq(apps.id, id))
    .returning();
  if (updated.length === 0) return c.json(err("not_found"), 404);
  return c.json(ok({ app: updated[0] }));
});

adminRoutes.delete("/apps/:id", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const deleted = await db.delete(apps).where(eq(apps.id, id)).returning({ id: apps.id });
  if (deleted.length === 0) return c.json(err("not_found"), 404);
  return c.json(ok({ deleted: id }));
});

// 회원 목록/승격 — admin 전용 (crew 승격 등, CLAUDE.md 4절)
adminRoutes.get("/users", requireRole("admin"), async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db
    .select({
      id: users.id,
      provider: users.provider,
      name: users.name,
      avatarUrl: users.avatarUrl,
      role: users.role,
      createdAt: users.createdAt,
    })
    .from(users)
    .orderBy(asc(users.id));
  return c.json(ok({ users: rows }));
});

adminRoutes.put("/users/:id/role", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  if (id === c.get("user").id) return c.json(err("cannot_change_own_role"), 400);
  const parsed = roleSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_role"), 400);
  const db = drizzle(c.env.DB);
  const updated = await db
    .update(users)
    .set({ role: parsed.data.role })
    .where(eq(users.id, id))
    .returning({ id: users.id, role: users.role });
  if (updated.length === 0) return c.json(err("not_found"), 404);
  return c.json(ok({ user: updated[0] }));
});

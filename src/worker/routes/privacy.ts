// 앱별 개인정보처리방침 (CLAUDE.md 5-5절) — 공개 URL + staff 편집 + 버전 이력
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { desc, eq } from "drizzle-orm";
import { z } from "zod";
import { apps, privacyPolicies, users } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";
import { requireRole, type AuthedUser } from "../middleware";

const policySchema = z.object({
  bodyMd: z.string().min(10).max(100000),
});

type Vars = { Variables: { user: AuthedUser } };

export const privacyRoutes = new Hono<{ Bindings: Env } & Vars>();

async function findApp(db: ReturnType<typeof drizzle>, slug: string) {
  const rows = await db
    .select({ id: apps.id, name: apps.name, slug: apps.slug })
    .from(apps)
    .where(eq(apps.slug, slug))
    .limit(1);
  return rows[0] ?? null;
}

/** 최신 방침 (공개 — Google Play Console에 이 URL 등록) */
privacyRoutes.get("/apps/:slug/privacy", async (c) => {
  const db = drizzle(c.env.DB);
  const app = await findApp(db, (c.req.param("slug") ?? ""));
  if (!app) return c.json(err("not_found"), 404);
  const rows = await db
    .select({
      version: privacyPolicies.version,
      bodyMd: privacyPolicies.bodyMd,
      updatedAt: privacyPolicies.updatedAt,
    })
    .from(privacyPolicies)
    .where(eq(privacyPolicies.appId, app.id))
    .orderBy(desc(privacyPolicies.version))
    .limit(1);
  return c.json(ok({ app, policy: rows[0] ?? null }));
});

/** 버전 이력 — staff 이상 */
privacyRoutes.get("/apps/:slug/privacy/versions", requireRole("staff"), async (c) => {
  const db = drizzle(c.env.DB);
  const app = await findApp(db, (c.req.param("slug") ?? ""));
  if (!app) return c.json(err("not_found"), 404);
  const rows = await db
    .select({
      version: privacyPolicies.version,
      updatedAt: privacyPolicies.updatedAt,
      updatedByName: users.name,
    })
    .from(privacyPolicies)
    .leftJoin(users, eq(privacyPolicies.updatedBy, users.id))
    .where(eq(privacyPolicies.appId, app.id))
    .orderBy(desc(privacyPolicies.version));
  return c.json(ok({ versions: rows }));
});

/** 작성/수정 — staff 이상, 새 버전으로 저장 (이력 보존) */
privacyRoutes.put("/apps/:slug/privacy", requireRole("staff"), async (c) => {
  const parsed = policySchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const app = await findApp(db, (c.req.param("slug") ?? ""));
  if (!app) return c.json(err("not_found"), 404);

  const latest = await db
    .select({ version: privacyPolicies.version })
    .from(privacyPolicies)
    .where(eq(privacyPolicies.appId, app.id))
    .orderBy(desc(privacyPolicies.version))
    .limit(1);
  const nextVersion = (latest[0]?.version ?? 0) + 1;

  await db.insert(privacyPolicies).values({
    appId: app.id,
    version: nextVersion,
    bodyMd: parsed.data.bodyMd,
    updatedBy: c.get("user").id,
    updatedAt: new Date(),
  });
  return c.json(ok({ version: nextVersion }));
});

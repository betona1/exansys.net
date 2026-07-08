// 앱별 문의게시판 — 댓글형 (CLAUDE.md 5-4절)
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { asc, eq, and, isNull } from "drizzle-orm";
import { z } from "zod";
import { apps, appComments, users } from "../../db/schema";
import type { Env } from "../types";
import { ok, err, ROLE_LEVEL } from "../types";
import { readSession } from "../auth/session";
import { requireRole, type AuthedUser } from "../middleware";

const commentSchema = z.object({
  body: z.string().min(1).max(2000),
  parentId: z.number().int().positive().optional().nullable(),
});

type Vars = { Variables: { user: AuthedUser } };

export const commentRoutes = new Hono<{ Bindings: Env } & Vars>();

/** 앱 댓글 목록 (공개 열람) — staff/admin은 EXANSYS 뱃지용 role 포함 */
commentRoutes.get("/apps/:slug/comments", async (c) => {
  const db = drizzle(c.env.DB);
  const appRows = await db.select({ id: apps.id }).from(apps).where(eq(apps.slug, (c.req.param("slug") ?? ""))).limit(1);
  if (appRows.length === 0) return c.json(err("not_found"), 404);

  const sess = await readSession(c);
  const rows = await db
    .select({
      id: appComments.id,
      parentId: appComments.parentId,
      body: appComments.body,
      createdAt: appComments.createdAt,
      deletedAt: appComments.deletedAt,
      userId: appComments.userId,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
      authorRole: users.role,
    })
    .from(appComments)
    .leftJoin(users, eq(appComments.userId, users.id))
    .where(eq(appComments.appId, appRows[0].id))
    .orderBy(asc(appComments.id));

  const list = rows.map((r) => ({
    id: r.id,
    parentId: r.parentId,
    body: r.deletedAt ? "삭제된 댓글입니다." : r.body,
    deleted: Boolean(r.deletedAt),
    createdAt: r.createdAt,
    authorName: r.authorName ?? "알 수 없음",
    authorAvatar: r.deletedAt ? null : r.authorAvatar,
    isExansys: r.authorRole === "staff" || r.authorRole === "admin",
    mine: sess?.userId === r.userId,
  }));
  return c.json(ok({ comments: list }));
});

/** 댓글 작성 — member 이상, 대댓글 1단계까지 (5-4절) */
commentRoutes.post("/apps/:slug/comments", requireRole("member"), async (c) => {
  const parsed = commentSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const appRows = await db.select({ id: apps.id }).from(apps).where(eq(apps.slug, (c.req.param("slug") ?? ""))).limit(1);
  if (appRows.length === 0) return c.json(err("not_found"), 404);

  let parentId: number | null = null;
  if (parsed.data.parentId) {
    const parent = await db
      .select({ id: appComments.id, parentId: appComments.parentId })
      .from(appComments)
      .where(and(eq(appComments.id, parsed.data.parentId), eq(appComments.appId, appRows[0].id), isNull(appComments.deletedAt)))
      .limit(1);
    if (parent.length === 0) return c.json(err("parent_not_found"), 400);
    if (parent[0].parentId !== null) return c.json(err("max_depth_exceeded"), 400);
    parentId = parent[0].id;
  }

  const inserted = await db
    .insert(appComments)
    .values({
      appId: appRows[0].id,
      userId: c.get("user").id,
      parentId,
      body: parsed.data.body,
      createdAt: new Date(),
    })
    .returning({ id: appComments.id });
  return c.json(ok({ id: inserted[0].id }));
});

/** 댓글 삭제 — 본인 소프트 삭제, admin은 모든 댓글 */
commentRoutes.delete("/comments/:id", requireRole("member"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const me = c.get("user");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(appComments).where(eq(appComments.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (rows[0].userId !== me.id && ROLE_LEVEL[me.role] < ROLE_LEVEL.admin) {
    return c.json(err("forbidden"), 403);
  }
  await db.update(appComments).set({ deletedAt: new Date() }).where(eq(appComments.id, id));
  return c.json(ok({ deleted: id }));
});

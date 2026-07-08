// 개발문의게시판 (CLAUDE.md 5-3절)
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { desc, eq, asc } from "drizzle-orm";
import { z } from "zod";
import { inquiries, inquiryReplies, users } from "../../db/schema";
import type { Env, Role } from "../types";
import { ok, err, ROLE_LEVEL } from "../types";
import { readSession } from "../auth/session";
import { requireRole, type AuthedUser } from "../middleware";
import { verifyTurnstile } from "../turnstile";

const inquirySchema = z.object({
  title: z.string().min(2).max(120),
  body: z.string().min(5).max(5000),
  contact: z.string().max(200).optional().nullable(),
  isPrivate: z.boolean().optional().default(false),
  turnstileToken: z.string().optional(),
});

const replySchema = z.object({
  body: z.string().min(1).max(5000),
});

type Vars = { Variables: { user: AuthedUser } };

export const inquiryRoutes = new Hono<{ Bindings: Env } & Vars>();

/** 목록 — 비공개 글은 제목을 마스킹하되 작성자/staff에게는 공개 */
inquiryRoutes.get("/", async (c) => {
  const sess = await readSession(c);
  const isStaff = sess ? ROLE_LEVEL[sess.role] >= ROLE_LEVEL.staff : false;
  const db = drizzle(c.env.DB);
  const rows = await db
    .select({
      id: inquiries.id,
      userId: inquiries.userId,
      title: inquiries.title,
      isPrivate: inquiries.isPrivate,
      status: inquiries.status,
      createdAt: inquiries.createdAt,
      authorName: users.name,
    })
    .from(inquiries)
    .leftJoin(users, eq(inquiries.userId, users.id))
    .orderBy(desc(inquiries.id))
    .limit(100);

  const list = rows.map((r) => {
    const canSee = !r.isPrivate || isStaff || sess?.userId === r.userId;
    return {
      id: r.id,
      title: canSee ? r.title : "비공개 문의입니다.",
      isPrivate: r.isPrivate,
      status: r.status,
      createdAt: r.createdAt,
      authorName: r.authorName ?? "알 수 없음",
      mine: sess?.userId === r.userId,
    };
  });
  return c.json(ok({ inquiries: list }));
});

/** 상세 + 답변 — 비공개 글은 작성자/staff만 (5-3절) */
inquiryRoutes.get("/:id", async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const sess = await readSession(c);
  const isStaff = sess ? ROLE_LEVEL[sess.role] >= ROLE_LEVEL.staff : false;
  const db = drizzle(c.env.DB);

  const rows = await db
    .select({
      id: inquiries.id,
      userId: inquiries.userId,
      title: inquiries.title,
      body: inquiries.body,
      contact: inquiries.contact,
      isPrivate: inquiries.isPrivate,
      status: inquiries.status,
      createdAt: inquiries.createdAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(inquiries)
    .leftJoin(users, eq(inquiries.userId, users.id))
    .where(eq(inquiries.id, id))
    .limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const q = rows[0];

  const isAuthor = sess?.userId === q.userId;
  if (q.isPrivate && !isStaff && !isAuthor) return c.json(err("private_inquiry"), 403);

  const replies = await db
    .select({
      id: inquiryReplies.id,
      body: inquiryReplies.body,
      createdAt: inquiryReplies.createdAt,
      authorName: users.name,
      authorRole: users.role,
    })
    .from(inquiryReplies)
    .leftJoin(users, eq(inquiryReplies.userId, users.id))
    .where(eq(inquiryReplies.inquiryId, id))
    .orderBy(asc(inquiryReplies.id));

  return c.json(
    ok({
      inquiry: {
        ...q,
        // 연락처는 작성자/staff에게만 노출 (개인정보)
        contact: isStaff || isAuthor ? q.contact : null,
        mine: isAuthor,
      },
      replies,
    }),
  );
});

/** 작성 — member 이상 + Turnstile 검증 */
inquiryRoutes.post("/", requireRole("member"), async (c) => {
  const parsed = inquirySchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;

  const human = await verifyTurnstile(
    c.env,
    d.turnstileToken,
    c.req.header("CF-Connecting-IP"),
  );
  if (!human) return c.json(err("turnstile_failed"), 400);

  const db = drizzle(c.env.DB);
  const inserted = await db
    .insert(inquiries)
    .values({
      userId: c.get("user").id,
      title: d.title,
      body: d.body,
      contact: d.contact || null,
      isPrivate: d.isPrivate ?? false,
      status: "open",
      createdAt: new Date(),
    })
    .returning({ id: inquiries.id });
  return c.json(ok({ id: inserted[0].id }));
});

/** 답변 — staff 이상, 등록 시 상태 '답변완료' (5-3절) */
inquiryRoutes.post("/:id/replies", requireRole("staff"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = replySchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);

  const db = drizzle(c.env.DB);
  const found = await db.select({ id: inquiries.id }).from(inquiries).where(eq(inquiries.id, id)).limit(1);
  if (found.length === 0) return c.json(err("not_found"), 404);

  await db.insert(inquiryReplies).values({
    inquiryId: id,
    userId: c.get("user").id,
    body: parsed.data.body,
    createdAt: new Date(),
  });
  await db.update(inquiries).set({ status: "answered" }).where(eq(inquiries.id, id));
  return c.json(ok({ replied: true }));
});

/** 삭제 — admin 전용 (3절: 글 삭제) */
inquiryRoutes.delete("/:id", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  await db.delete(inquiryReplies).where(eq(inquiryReplies.inquiryId, id));
  const deleted = await db.delete(inquiries).where(eq(inquiries.id, id)).returning({ id: inquiries.id });
  if (deleted.length === 0) return c.json(err("not_found"), 404);
  return c.json(ok({ deleted: id }));
});

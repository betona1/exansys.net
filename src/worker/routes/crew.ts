// 크루(앱개발자 모임) 내부 갤러리 (CLAUDE.md 5-6절)
// crew 역할 이상만 접근. 이미지 R2 저장 (클라이언트에서 webp 변환 후 업로드, 최대 5MB)
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { asc, desc, eq, sql } from "drizzle-orm";
import { z } from "zod";
import { galleryPosts, galleryImages, galleryComments, users } from "../../db/schema";
import type { Env, Role } from "../types";
import { ok, err, ROLE_LEVEL } from "../types";
import { requireRole, type AuthedUser } from "../middleware";
import { readSession } from "../auth/session";
import appEducationHtml from "../resources/app-education.html?raw";

const MAX_IMAGE_BYTES = 5 * 1024 * 1024; // 5MB (5-6절)

// 크루 자료실 — 학습용 정적 문서(HTML)를 crew 전용으로 서빙.
// 새 자료는 여기에 항목을 추가하면 목록·서빙에 함께 반영된다.
const RESOURCES: Record<
  string,
  { title: string; description: string; emoji: string; html: string }
> = {
  "app-education": {
    title: "앱 개발 교육 · 통합 대시보드",
    description: "기획 · 시장 분석 · 기초용어 · 개발언어 · 역할&DB · 세팅까지 초보 팀을 위한 학습 자료 모음",
    emoji: "📚",
    html: appEducationHtml,
  },
};

const postSchema = z.object({
  title: z.string().min(2).max(80),
  body: z.string().max(2000).optional().nullable(),
  linkUrl: z.string().url().max(500).optional().nullable().or(z.literal("")),
  imageKeys: z.array(z.string().regex(/^gallery\/[a-z0-9-]+\.webp$/)).max(5).optional(),
});

const commentSchema = z.object({
  body: z.string().min(1).max(1000),
});

type Vars = { Variables: { user: AuthedUser } };

export const crewRoutes = new Hono<{ Bindings: Env } & Vars>();

/** 이미지 업로드 — webp 원본 바이트를 R2에 저장 */
crewRoutes.post("/crew/upload", requireRole("crew"), async (c) => {
  const type = c.req.header("Content-Type") ?? "";
  if (!type.startsWith("image/webp")) return c.json(err("webp_only"), 400);
  const len = Number(c.req.header("Content-Length") ?? "0");
  if (!len || len > MAX_IMAGE_BYTES) return c.json(err("max_5mb"), 400);

  const body = await c.req.arrayBuffer();
  if (body.byteLength > MAX_IMAGE_BYTES) return c.json(err("max_5mb"), 400);

  const key = `gallery/${crypto.randomUUID()}.webp`;
  await c.env.MEDIA.put(key, body, {
    httpMetadata: { contentType: "image/webp" },
  });
  return c.json(ok({ key, url: `/api/media/${key}` }));
});

/** 갤러리 이미지 서빙 — 갤러리는 공개 열람이므로 누구나 */
crewRoutes.get("/media/gallery/:file", async (c) => {
  const key = `gallery/${c.req.param("file") ?? ""}`;
  const obj = await c.env.MEDIA.get(key);
  if (!obj) return c.json(err("not_found"), 404);
  return c.body(obj.body, 200, {
    "Content-Type": obj.httpMetadata?.contentType ?? "image/webp",
    "Cache-Control": "public, max-age=86400",
  });
});

/** 자료실 목록 — crew 이상 (메타데이터만, HTML 본문 제외) */
crewRoutes.get("/crew/resources", requireRole("crew"), (c) => {
  const list = Object.entries(RESOURCES).map(([slug, r]) => ({
    slug,
    title: r.title,
    description: r.description,
    emoji: r.emoji,
  }));
  return c.json(ok({ resources: list }));
});

/**
 * 자료실 문서 서빙 — 브라우저 새 탭 내비게이션용.
 * 인증 실패 시 JSON 대신 /crew 안내 페이지로 리다이렉트(깔끔한 UX).
 * requireRole과 동일하게 DB 최신 역할로 재확인(로그인 후 승격 반영).
 */
crewRoutes.get("/crew/resources/:slug", async (c) => {
  const res = RESOURCES[c.req.param("slug") ?? ""];
  if (!res) return c.redirect("/crew");
  const sess = await readSession(c);
  if (!sess) return c.redirect("/crew");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(users).where(eq(users.id, sess.userId)).limit(1);
  if (rows.length === 0 || ROLE_LEVEL[rows[0].role as Role] < ROLE_LEVEL.crew) {
    return c.redirect("/crew");
  }
  return c.html(res.html, 200, { "Cache-Control": "private, max-age=3600" });
});

/** 게시글 목록 — 카드형 갤러리용 (첫 이미지 + 댓글 수) */
crewRoutes.get("/crew/posts", async (c) => {
  const db = drizzle(c.env.DB);
  const posts = await db
    .select({
      id: galleryPosts.id,
      title: galleryPosts.title,
      body: galleryPosts.body,
      linkUrl: galleryPosts.linkUrl,
      createdAt: galleryPosts.createdAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(galleryPosts)
    .leftJoin(users, eq(galleryPosts.userId, users.id))
    .orderBy(desc(galleryPosts.id))
    .limit(100);

  const images = await db
    .select({ postId: galleryImages.postId, imageUrl: galleryImages.imageUrl, sort: galleryImages.sort })
    .from(galleryImages)
    .orderBy(asc(galleryImages.sort));
  const counts = await db
    .select({ postId: galleryComments.postId, cnt: sql<number>`count(*)` })
    .from(galleryComments)
    .groupBy(galleryComments.postId);

  const firstImage = new Map<number, string>();
  for (const img of images) if (!firstImage.has(img.postId)) firstImage.set(img.postId, img.imageUrl);
  const countMap = new Map(counts.map((r) => [r.postId, Number(r.cnt)]));

  return c.json(
    ok({
      posts: posts.map((p) => ({
        ...p,
        thumbnail: firstImage.get(p.id) ?? null,
        commentCount: countMap.get(p.id) ?? 0,
      })),
    }),
  );
});

/** 게시글 작성 */
crewRoutes.post("/crew/posts", requireRole("crew"), async (c) => {
  const parsed = postSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  const inserted = await db
    .insert(galleryPosts)
    .values({
      userId: c.get("user").id,
      title: d.title,
      body: d.body || null,
      linkUrl: d.linkUrl || null,
      createdAt: new Date(),
    })
    .returning({ id: galleryPosts.id });
  const postId = inserted[0].id;

  if (d.imageKeys?.length) {
    for (let i = 0; i < d.imageKeys.length; i++) {
      await db.insert(galleryImages).values({
        postId,
        imageUrl: `/api/media/${d.imageKeys[i]}`,
        sort: i,
      });
    }
  }
  return c.json(ok({ id: postId }));
});

/** 게시글 상세 + 댓글 — 공개 열람 (로그인 시 mine 플래그로 본인 글/댓글 표시) */
crewRoutes.get("/crew/posts/:id", async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const rows = await db
    .select({
      id: galleryPosts.id,
      userId: galleryPosts.userId,
      title: galleryPosts.title,
      body: galleryPosts.body,
      linkUrl: galleryPosts.linkUrl,
      createdAt: galleryPosts.createdAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(galleryPosts)
    .leftJoin(users, eq(galleryPosts.userId, users.id))
    .where(eq(galleryPosts.id, id))
    .limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);

  const sess = await readSession(c);
  const meId = sess?.userId ?? -1;
  const images = await db
    .select({ id: galleryImages.id, imageUrl: galleryImages.imageUrl })
    .from(galleryImages)
    .where(eq(galleryImages.postId, id))
    .orderBy(asc(galleryImages.sort));
  const comments = await db
    .select({
      id: galleryComments.id,
      body: galleryComments.body,
      createdAt: galleryComments.createdAt,
      userId: galleryComments.userId,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(galleryComments)
    .leftJoin(users, eq(galleryComments.userId, users.id))
    .where(eq(galleryComments.postId, id))
    .orderBy(asc(galleryComments.id));

  return c.json(
    ok({
      post: { ...rows[0], mine: rows[0].userId === meId },
      images,
      comments: comments.map((cm) => ({ ...cm, mine: cm.userId === meId })),
    }),
  );
});

/** 댓글 작성 */
crewRoutes.post("/crew/posts/:id/comments", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = commentSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const found = await db.select({ id: galleryPosts.id }).from(galleryPosts).where(eq(galleryPosts.id, id)).limit(1);
  if (found.length === 0) return c.json(err("not_found"), 404);
  await db.insert(galleryComments).values({
    postId: id,
    userId: c.get("user").id,
    body: parsed.data.body,
    createdAt: new Date(),
  });
  return c.json(ok({ commented: true }));
});

/** 게시글 삭제 — 작성자 또는 admin (R2 이미지도 함께 정리) */
crewRoutes.delete("/crew/posts/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const me = c.get("user");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(galleryPosts).where(eq(galleryPosts.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (rows[0].userId !== me.id && ROLE_LEVEL[me.role] < ROLE_LEVEL.admin) {
    return c.json(err("forbidden"), 403);
  }
  const images = await db
    .select({ imageUrl: galleryImages.imageUrl })
    .from(galleryImages)
    .where(eq(galleryImages.postId, id));
  for (const img of images) {
    const key = img.imageUrl.replace("/api/media/", "");
    if (key.startsWith("gallery/")) await c.env.MEDIA.delete(key);
  }
  await db.delete(galleryComments).where(eq(galleryComments.postId, id));
  await db.delete(galleryImages).where(eq(galleryImages.postId, id));
  await db.delete(galleryPosts).where(eq(galleryPosts.id, id));
  return c.json(ok({ deleted: id }));
});

/** 댓글 삭제 — 작성자 또는 admin */
crewRoutes.delete("/crew/comments/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const me = c.get("user");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(galleryComments).where(eq(galleryComments.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (rows[0].userId !== me.id && ROLE_LEVEL[me.role] < ROLE_LEVEL.admin) {
    return c.json(err("forbidden"), 403);
  }
  await db.delete(galleryComments).where(eq(galleryComments.id, id));
  return c.json(ok({ deleted: id }));
});

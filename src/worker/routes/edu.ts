// AI교육 게시판 — 교육 자료 게시 (열람 공개, 작성/업로드/삭제는 admin 전용)
// 첨부: 다이나믹 HTML(샌드박스 렌더) / 이미지(webp) / PDF / 외부 링크
import { Hono, type Context } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { asc, desc, eq, sql } from "drizzle-orm";
import { z } from "zod";
import { eduPosts, eduAttachments, eduComments, users } from "../../db/schema";
import type { Env } from "../types";
import { ok, err, ROLE_LEVEL } from "../types";
import { requireRole, type AuthedUser } from "../middleware";
import { readSession } from "../auth/session";
import glossaryHtml from "../resources/ai-glossary.html?raw";
import guideHtml from "../resources/claude-code-guide.html?raw";

type Vars = { Variables: { user: AuthedUser } };
export const eduRoutes = new Hono<{ Bindings: Env } & Vars>();

const MAX_HTML_BYTES = 3 * 1024 * 1024; // 3MB
const MAX_IMAGE_BYTES = 5 * 1024 * 1024; // 5MB
const MAX_PDF_BYTES = 20 * 1024 * 1024; // 20MB

// 첨부 R2 키 형식
const KEY_RE = {
  html: /^edu\/html\/[a-f0-9-]{36}\.html$/,
  image: /^edu\/img\/[a-f0-9-]{36}\.webp$/,
  pdf: /^edu\/pdf\/[a-f0-9-]{36}\.pdf$/,
};

// 테이블 자동 생성 (마이그레이션 수동 적용 불필요, 아이소레이트당 1회)
let tablesReady = false;
async function ensureTables(db: ReturnType<typeof drizzle>) {
  if (tablesReady) return;
  await db.run(sql`CREATE TABLE IF NOT EXISTS edu_posts (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    user_id integer NOT NULL, title text NOT NULL, body text,
    created_at integer NOT NULL, updated_at integer NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS edu_attachments (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    post_id integer NOT NULL, kind text NOT NULL,
    file_key text, url text, name text NOT NULL, size integer,
    sort integer DEFAULT 0 NOT NULL,
    FOREIGN KEY (post_id) REFERENCES edu_posts(id)
  )`);
  await db.run(sql`CREATE INDEX IF NOT EXISTS idx_edu_attachments_post ON edu_attachments (post_id)`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS edu_comments (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    post_id integer NOT NULL, user_id integer NOT NULL,
    body text NOT NULL, created_at integer NOT NULL,
    FOREIGN KEY (post_id) REFERENCES edu_posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);
  await db.run(sql`CREATE INDEX IF NOT EXISTS idx_edu_comments_post ON edu_comments (post_id)`);
  tablesReady = true;
}

// ── 첨부 업로드 (admin 전용) ──

eduRoutes.post("/edu/upload/html", requireRole("admin"), async (c) => {
  const buf = await c.req.arrayBuffer();
  if (buf.byteLength === 0 || buf.byteLength > MAX_HTML_BYTES) return c.json(err("max_3mb"), 400);
  const key = `edu/html/${crypto.randomUUID()}.html`;
  await c.env.MEDIA.put(key, buf, { httpMetadata: { contentType: "text/html; charset=utf-8" } });
  return c.json(ok({ kind: "html", key, size: buf.byteLength }));
});

eduRoutes.post("/edu/upload/image", requireRole("admin"), async (c) => {
  const type = c.req.header("Content-Type") ?? "";
  if (!type.startsWith("image/webp")) return c.json(err("webp_only"), 400);
  const buf = await c.req.arrayBuffer();
  if (buf.byteLength === 0 || buf.byteLength > MAX_IMAGE_BYTES) return c.json(err("max_5mb"), 400);
  const key = `edu/img/${crypto.randomUUID()}.webp`;
  await c.env.MEDIA.put(key, buf, { httpMetadata: { contentType: "image/webp" } });
  return c.json(ok({ kind: "image", key, size: buf.byteLength }));
});

eduRoutes.post("/edu/upload/pdf", requireRole("admin"), async (c) => {
  const type = c.req.header("Content-Type") ?? "";
  if (!type.startsWith("application/pdf")) return c.json(err("pdf_only"), 400);
  const buf = await c.req.arrayBuffer();
  if (buf.byteLength === 0 || buf.byteLength > MAX_PDF_BYTES) return c.json(err("max_20mb"), 400);
  const key = `edu/pdf/${crypto.randomUUID()}.pdf`;
  await c.env.MEDIA.put(key, buf, { httpMetadata: { contentType: "application/pdf" } });
  return c.json(ok({ kind: "pdf", key, size: buf.byteLength }));
});

// ── 첨부 서빙 (열람 공개) ──

eduRoutes.get("/edu/media/img/:file", async (c) => {
  const key = `edu/img/${c.req.param("file") ?? ""}`;
  if (!KEY_RE.image.test(key)) return c.json(err("not_found"), 404);
  const obj = await c.env.MEDIA.get(key);
  if (!obj) return c.json(err("not_found"), 404);
  return c.body(obj.body, 200, {
    "Content-Type": "image/webp",
    "Cache-Control": "public, max-age=604800, immutable",
  });
});

eduRoutes.get("/edu/media/pdf/:file", async (c) => {
  const key = `edu/pdf/${c.req.param("file") ?? ""}`;
  if (!KEY_RE.pdf.test(key)) return c.json(err("not_found"), 404);
  const obj = await c.env.MEDIA.get(key);
  if (!obj) return c.json(err("not_found"), 404);
  return c.body(obj.body, 200, {
    "Content-Type": "application/pdf",
    "Content-Disposition": "inline",
    "Cache-Control": "public, max-age=604800",
  });
});

// 다이나믹 HTML — 반드시 샌드박스로 서빙 (opaque origin, 네트워크 차단)
// CSP sandbox 로 문서를 격리해 exansys 세션 쿠키 접근·API 호출을 원천 차단한다.
eduRoutes.get("/edu/media/html/:file", async (c) => {
  const key = `edu/html/${c.req.param("file") ?? ""}`;
  if (!KEY_RE.html.test(key)) return c.json(err("not_found"), 404);
  const obj = await c.env.MEDIA.get(key);
  if (!obj) return c.json(err("not_found"), 404);
  // 보안 핵심:
  // - CSP `sandbox` 는 응답 자체를 opaque origin 으로 격리 → 새 탭 직접 열기 시에도
  //   exansys 세션 쿠키 접근·인증 API 호출 불가 (iframe sandbox 속성은 임베드 때만 적용되므로 필수)
  // - `connect-src 'none'` 로 fetch/XHR/WebSocket 전면 차단
  // - 인라인 스크립트/스타일은 허용해야 다이나믹 자료(아티팩트형)가 정상 동작
  return c.body(obj.body, 200, {
    "Content-Type": "text/html; charset=utf-8",
    "Content-Security-Policy": [
      "sandbox allow-scripts allow-popups allow-popups-to-escape-sandbox allow-forms allow-modals allow-downloads",
      "default-src 'none'",
      "script-src 'unsafe-inline' 'unsafe-eval' https: data: blob:",
      "style-src 'unsafe-inline' https: data:",
      "img-src 'self' data: blob: https:",
      "font-src data: https:",
      "media-src data: blob: https:",
      "connect-src 'none'",
      "base-uri 'none'",
      "form-action 'none'",
    ].join("; "),
    "X-Content-Type-Options": "nosniff",
    "Cache-Control": "public, max-age=86400",
  });
});

// ── 게시글 ──

const attachmentSchema = z
  .object({
    kind: z.enum(["html", "image", "pdf", "link"]),
    key: z.string().max(120).optional(),
    url: z.string().url().max(1000).optional(),
    name: z.string().min(1).max(120),
  })
  .refine(
    (a) =>
      a.kind === "link"
        ? !!a.url
        : !!a.key && KEY_RE[a.kind].test(a.key),
    { message: "invalid_attachment" },
  );

const postSchema = z.object({
  title: z.string().min(2).max(120),
  body: z.string().max(20000).optional().nullable(),
  attachments: z.array(attachmentSchema).max(20).optional(),
});

// 목록 (공개)
eduRoutes.get("/edu/posts", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const posts = await db
    .select({
      id: eduPosts.id,
      title: eduPosts.title,
      createdAt: eduPosts.createdAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(eduPosts)
    .leftJoin(users, eq(eduPosts.userId, users.id))
    .orderBy(desc(eduPosts.id))
    .limit(100);

  const atts = await db
    .select({ postId: eduAttachments.postId, kind: eduAttachments.kind, fileKey: eduAttachments.fileKey })
    .from(eduAttachments)
    .orderBy(asc(eduAttachments.sort));
  const counts = await db
    .select({ postId: eduComments.postId, cnt: sql<number>`count(*)` })
    .from(eduComments)
    .groupBy(eduComments.postId);

  // 카드 썸네일: 첫 이미지 첨부, 그리고 첨부 종류 배지 집계
  const thumb = new Map<number, string>();
  const kinds = new Map<number, Set<string>>();
  for (const a of atts) {
    if (!kinds.has(a.postId)) kinds.set(a.postId, new Set());
    kinds.get(a.postId)!.add(a.kind);
    if (a.kind === "image" && a.fileKey && !thumb.has(a.postId)) {
      thumb.set(a.postId, `/api/edu/media/img/${a.fileKey.split("/").pop()}`);
    }
  }
  const countMap = new Map(counts.map((r) => [r.postId, Number(r.cnt)]));

  return c.json(
    ok({
      posts: posts.map((p) => ({
        ...p,
        thumbnail: thumb.get(p.id) ?? null,
        kinds: [...(kinds.get(p.id) ?? [])],
        commentCount: countMap.get(p.id) ?? 0,
      })),
    }),
  );
});

// 상세 (공개) — 첨부 서빙 URL을 완성해 반환
function attView(a: {
  id: number;
  kind: string;
  fileKey: string | null;
  url: string | null;
  name: string;
  size: number | null;
}) {
  let src: string | null = null;
  if (a.kind === "link") src = a.url;
  else if (a.fileKey) {
    const file = a.fileKey.split("/").pop();
    src =
      a.kind === "html"
        ? `/api/edu/media/html/${file}`
        : a.kind === "image"
          ? `/api/edu/media/img/${file}`
          : `/api/edu/media/pdf/${file}`;
  }
  return { id: a.id, kind: a.kind, name: a.name, size: a.size, src };
}

eduRoutes.get("/edu/posts/:id", async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const rows = await db
    .select({
      id: eduPosts.id,
      userId: eduPosts.userId,
      title: eduPosts.title,
      body: eduPosts.body,
      createdAt: eduPosts.createdAt,
      updatedAt: eduPosts.updatedAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(eduPosts)
    .leftJoin(users, eq(eduPosts.userId, users.id))
    .where(eq(eduPosts.id, id))
    .limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);

  const attachments = await db
    .select()
    .from(eduAttachments)
    .where(eq(eduAttachments.postId, id))
    .orderBy(asc(eduAttachments.sort));
  const comments = await db
    .select({
      id: eduComments.id,
      body: eduComments.body,
      createdAt: eduComments.createdAt,
      userId: eduComments.userId,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(eduComments)
    .leftJoin(users, eq(eduComments.userId, users.id))
    .where(eq(eduComments.postId, id))
    .orderBy(asc(eduComments.id));

  // 로그인 사용자 정보 (본인 댓글/삭제 권한 판단용, 비로그인도 열람 가능)
  const sess = await readSession(c);
  let meId = 0;
  let meRole = "";
  if (sess) {
    const u = await db.select({ id: users.id, role: users.role }).from(users).where(eq(users.id, sess.userId)).limit(1);
    if (u.length) {
      meId = u[0].id;
      meRole = u[0].role;
    }
  }
  const isAdmin = ROLE_LEVEL[meRole as keyof typeof ROLE_LEVEL] >= ROLE_LEVEL.admin;

  return c.json(
    ok({
      post: rows[0],
      attachments: attachments.map(attView),
      comments: comments.map((cm) => ({
        ...cm,
        mine: cm.userId === meId || isAdmin,
      })),
      canComment: meId > 0,
      canManage: isAdmin,
    }),
  );
});

// 작성 (admin)
eduRoutes.post("/edu/posts", requireRole("admin"), async (c) => {
  const parsed = postSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const now = new Date();
  const inserted = await db
    .insert(eduPosts)
    .values({ userId: c.get("user").id, title: d.title, body: d.body || null, createdAt: now, updatedAt: now })
    .returning({ id: eduPosts.id });
  const postId = inserted[0].id;

  if (d.attachments?.length) {
    for (let i = 0; i < d.attachments.length; i++) {
      const a = d.attachments[i];
      await db.insert(eduAttachments).values({
        postId,
        kind: a.kind,
        fileKey: a.kind === "link" ? null : a.key!,
        url: a.kind === "link" ? a.url! : null,
        name: a.name,
        sort: i,
      });
    }
  }
  return c.json(ok({ id: postId }));
});

// 번들 자료 시드 (admin 전용, 멱등) — 큰 HTML을 브라우저로 전송하지 않고 번들에서 R2+DB에 직접 등록
async function seedDoc(
  c: Context<{ Bindings: Env } & Vars>,
  opts: { title: string; body: string; fileName: string; html: string },
) {
  const db = drizzle(c.env.DB);
  await ensureTables(db);
  const existing = await db
    .select({ id: eduPosts.id })
    .from(eduPosts)
    .where(eq(eduPosts.title, opts.title))
    .limit(1);
  if (existing.length) return c.json(ok({ id: existing[0].id, already: true }));

  const key = `edu/html/${crypto.randomUUID()}.html`;
  await c.env.MEDIA.put(key, opts.html, { httpMetadata: { contentType: "text/html; charset=utf-8" } });

  const now = new Date();
  const inserted = await db
    .insert(eduPosts)
    .values({ userId: c.get("user").id, title: opts.title, body: opts.body, createdAt: now, updatedAt: now })
    .returning({ id: eduPosts.id });
  const postId = inserted[0].id;
  await db.insert(eduAttachments).values({
    postId,
    kind: "html",
    fileKey: key,
    url: null,
    name: opts.fileName,
    sort: 0,
  });
  return c.json(ok({ id: postId, key, chars: opts.html.length }));
}

eduRoutes.post("/edu/seed/glossary", requireRole("admin"), (c) =>
  seedDoc(c, {
    title: "AI · 앱 개발 용어집 (필수 용어 177개)",
    body: "클로드코드로 앱을 만들 때 만나는 필수 용어 177개를 한곳에 모았습니다. 아래 자료에서 검색하거나 18개 분류로 필터링해 찾아보세요.",
    fileName: "AI·앱 개발 용어집.html",
    html: glossaryHtml,
  }),
);

eduRoutes.post("/edu/seed/guide", requireRole("admin"), (c) =>
  seedDoc(c, {
    title: "클로드코드 설치·사용 가이드 (터미널·VS Code·GitHub·WSL)",
    body: "설치부터 터미널·VS Code 사용법, GitHub·WSL 개념과 설치까지 그림 위주로 정리한 가이드입니다. 자세한 내용은 강의에서 설명합니다.",
    fileName: "클로드코드 설치·사용 가이드.html",
    html: guideHtml,
  }),
);

// 수정 (admin) — 제목/본문만 (첨부는 삭제 후 재작성)
eduRoutes.put("/edu/posts/:id", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = z
    .object({ title: z.string().min(2).max(120), body: z.string().max(20000).optional().nullable() })
    .safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const found = await db.select({ id: eduPosts.id }).from(eduPosts).where(eq(eduPosts.id, id)).limit(1);
  if (found.length === 0) return c.json(err("not_found"), 404);
  await db
    .update(eduPosts)
    .set({ title: parsed.data.title, body: parsed.data.body || null, updatedAt: new Date() })
    .where(eq(eduPosts.id, id));
  return c.json(ok({ id }));
});

// 삭제 (admin) — R2 첨부도 함께 정리
eduRoutes.delete("/edu/posts/:id", requireRole("admin"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const atts = await db
    .select({ fileKey: eduAttachments.fileKey })
    .from(eduAttachments)
    .where(eq(eduAttachments.postId, id));
  for (const a of atts) if (a.fileKey) await c.env.MEDIA.delete(a.fileKey);
  await db.delete(eduComments).where(eq(eduComments.postId, id));
  await db.delete(eduAttachments).where(eq(eduAttachments.postId, id));
  await db.delete(eduPosts).where(eq(eduPosts.id, id));
  return c.json(ok({ deleted: id }));
});

// 댓글 작성 (member 이상)
eduRoutes.post("/edu/posts/:id/comments", requireRole("member"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = z.object({ body: z.string().min(1).max(1000) }).safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const found = await db.select({ id: eduPosts.id }).from(eduPosts).where(eq(eduPosts.id, id)).limit(1);
  if (found.length === 0) return c.json(err("not_found"), 404);
  await db.insert(eduComments).values({ postId: id, userId: c.get("user").id, body: parsed.data.body, createdAt: new Date() });
  return c.json(ok({ commented: true }));
});

// 댓글 삭제 (작성자 또는 admin)
eduRoutes.delete("/edu/comments/:id", requireRole("member"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const me = c.get("user");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(eduComments).where(eq(eduComments.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (rows[0].userId !== me.id && ROLE_LEVEL[me.role] < ROLE_LEVEL.admin) return c.json(err("forbidden"), 403);
  await db.delete(eduComments).where(eq(eduComments.id, id));
  return c.json(ok({ deleted: id }));
});

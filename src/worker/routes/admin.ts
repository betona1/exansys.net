import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { asc, eq, gte, lt, sql } from "drizzle-orm";
import { z } from "zod";
import {
  apps,
  appBuilds,
  appComments,
  appScreenshots,
  downloadLogs,
  privacyPolicies,
  users,
  visitLogs,
  visitStats,
} from "../../db/schema";
import type { Env } from "../types";
import { ok, err, ROLE_LEVEL } from "../types";
import { requireRole, type AuthedUser } from "../middleware";
import { ensureOwnerCol } from "./apps";
import { kstDate } from "./visits";

// 앱 소유자(owner_id)는 apps 테이블의 런타임 추가 컬럼 — 원시 SQL로만 읽는다.
async function appOwnerId(DB: D1Database, id: number): Promise<number | null> {
  await ensureOwnerCol(DB);
  const row = await DB.prepare("SELECT owner_id AS o FROM apps WHERE id = ?").bind(id).first<{ o: number | null }>();
  return row ? row.o : null;
}
// staff 이상은 모든 앱, crew는 자기가 등록한 앱만 관리
function canManageApp(user: AuthedUser, ownerId: number | null): boolean {
  return ROLE_LEVEL[user.role] >= ROLE_LEVEL["staff"] || (ownerId !== null && ownerId === user.id);
}

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

// 앱 목록(소유자 포함) — crew 이상. crew는 프런트에서 자기 앱만 관리하도록 owner_id로 구분.
adminRoutes.get("/apps-list", requireRole("crew"), async (c) => {
  await ensureOwnerCol(c.env.DB);
  const { results } = await c.env.DB.prepare(
    "SELECT id, slug, name, tagline, description, icon_url AS iconUrl, store_url_android AS storeUrlAndroid, store_url_ios AS storeUrlIos, status, download_count AS downloadCount, owner_id AS ownerId FROM apps ORDER BY id ASC",
  ).all();
  return c.json(ok({ apps: results }));
});

// 앱 등록 — crew 이상 (등록자가 소유자가 됨). 수정/삭제는 소유자 또는 staff 이상만.
adminRoutes.post("/apps", requireRole("crew"), async (c) => {
  const parsed = appSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err(parsed.error.issues[0]?.message ?? "invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  await ensureOwnerCol(c.env.DB);
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
  // 등록자를 소유자로 기록
  await c.env.DB.prepare("UPDATE apps SET owner_id = ? WHERE id = ?").bind(c.get("user").id, inserted[0].id).run();
  return c.json(ok({ app: inserted[0] }));
});

adminRoutes.put("/apps/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, id))) return c.json(err("forbidden"), 403);
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

adminRoutes.delete("/apps/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, id))) return c.json(err("forbidden"), 403);
  const db = drizzle(c.env.DB);
  const found = await db.select().from(apps).where(eq(apps.id, id)).limit(1);
  if (found.length === 0) return c.json(err("not_found"), 404);

  // R2 파일 정리: 스크린샷·아이콘·APK 빌드
  const shots = await db.select().from(appScreenshots).where(eq(appScreenshots.appId, id));
  for (const s of shots) {
    const key = s.imageUrl.replace(/^\/api\/media\//, "");
    if (key.startsWith("shots/")) await c.env.MEDIA.delete(key);
  }
  const iconKey = (found[0].iconUrl ?? "").replace(/^\/api\/media\//, "");
  if (iconKey.startsWith("shots/")) await c.env.MEDIA.delete(iconKey);
  const builds = await db.select().from(appBuilds).where(eq(appBuilds.appId, id));
  for (const b of builds) {
    await c.env.MEDIA.delete(b.fileKey);
  }

  // 자식 행부터 삭제 (FK 제약 — 방침·댓글·카운터 로그가 남아 있으면 앱 삭제가 실패한다)
  await db.delete(appScreenshots).where(eq(appScreenshots.appId, id));
  await db.delete(appBuilds).where(eq(appBuilds.appId, id));
  await db.delete(appComments).where(eq(appComments.appId, id));
  await db.delete(privacyPolicies).where(eq(privacyPolicies.appId, id));
  await db.delete(downloadLogs).where(eq(downloadLogs.appId, id));
  await db.delete(apps).where(eq(apps.id, id));
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

// ── 앱 스크린샷/미디어 관리 (admin) — R2 shots/ 저장 ──
// webp·gif(움짤)는 5MB, mp4(홍보 영상)는 30MB까지
const SHOT_TYPES: Record<string, { ext: string; max: number }> = {
  "image/webp": { ext: "webp", max: 5 * 1024 * 1024 },
  "image/gif": { ext: "gif", max: 5 * 1024 * 1024 },
  "video/mp4": { ext: "mp4", max: 30 * 1024 * 1024 },
};

adminRoutes.post("/apps/:id/screenshots", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, id))) return c.json(err("forbidden"), 403);
  const type = (c.req.header("Content-Type") ?? "").split(";")[0].trim();
  const spec = SHOT_TYPES[type];
  if (!spec) return c.json(err("webp_gif_mp4_only"), 400);
  const body = await c.req.arrayBuffer();
  if (!body.byteLength || body.byteLength > spec.max) return c.json(err("too_large"), 400);

  const db = drizzle(c.env.DB);
  const app = await db.select({ id: apps.id }).from(apps).where(eq(apps.id, id)).limit(1);
  if (app.length === 0) return c.json(err("not_found"), 404);

  const key = `shots/${crypto.randomUUID()}.${spec.ext}`;
  await c.env.MEDIA.put(key, body, { httpMetadata: { contentType: type } });

  const maxSort = await db
    .select({ n: sql<number>`coalesce(max(${appScreenshots.sort}), 0)` })
    .from(appScreenshots)
    .where(eq(appScreenshots.appId, id));
  const inserted = await db
    .insert(appScreenshots)
    .values({ appId: id, imageUrl: `/api/media/${key}`, sort: maxSort[0].n + 1 })
    .returning();
  return c.json(ok({ screenshot: inserted[0] }));
});

adminRoutes.delete("/screenshots/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(appScreenshots).where(eq(appScreenshots.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, rows[0].appId))) return c.json(err("forbidden"), 403);
  const key = rows[0].imageUrl.replace(/^\/api\/media\//, "");
  if (key.startsWith("shots/")) await c.env.MEDIA.delete(key);
  await db.delete(appScreenshots).where(eq(appScreenshots.id, id));
  return c.json(ok({ deleted: id }));
});

// ── 테스트 APK 빌드 관리 (admin) — R2 멀티파트 분할 업로드 ──
// 워커 요청 본문 100MB 제한 때문에 클라이언트가 25MB 조각으로 나눠 올린다
const MAX_APK_BYTES = 300 * 1024 * 1024; // 게임 APK 여유 있게 300MB
const BUILD_KEY_RE = /^builds\/[a-z0-9-]+\.apk$/;

const buildStartSchema = z.object({
  version: z.string().min(1).max(40),
  size: z.number().int().positive().max(MAX_APK_BYTES),
});

adminRoutes.post("/apps/:id/builds/start", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, id))) return c.json(err("forbidden"), 403);
  const parsed = buildStartSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const app = await db.select({ id: apps.id }).from(apps).where(eq(apps.id, id)).limit(1);
  if (app.length === 0) return c.json(err("not_found"), 404);

  const key = `builds/${crypto.randomUUID()}.apk`;
  const mpu = await c.env.MEDIA.createMultipartUpload(key, {
    httpMetadata: { contentType: "application/vnd.android.package-archive" },
  });
  return c.json(ok({ key, uploadId: mpu.uploadId }));
});

adminRoutes.put("/builds/part", requireRole("crew"), async (c) => {
  const key = c.req.query("key") ?? "";
  const uploadId = c.req.query("uploadId") ?? "";
  const part = Number(c.req.query("part"));
  if (!BUILD_KEY_RE.test(key) || !uploadId || !Number.isInteger(part) || part < 1)
    return c.json(err("invalid_input"), 400);
  const body = await c.req.arrayBuffer();
  if (!body.byteLength) return c.json(err("empty_part"), 400);
  const mpu = c.env.MEDIA.resumeMultipartUpload(key, uploadId);
  const uploaded = await mpu.uploadPart(part, body);
  return c.json(ok({ partNumber: uploaded.partNumber, etag: uploaded.etag }));
});

const buildCompleteSchema = z.object({
  key: z.string().regex(BUILD_KEY_RE),
  uploadId: z.string().min(1),
  parts: z
    .array(z.object({ partNumber: z.number().int().positive(), etag: z.string().min(1) }))
    .min(1)
    .max(50),
  version: z.string().min(1).max(40),
  notes: z.string().max(2000).optional().nullable(),
  size: z.number().int().positive().max(MAX_APK_BYTES),
});

adminRoutes.post("/apps/:id/builds/complete", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, id))) return c.json(err("forbidden"), 403);
  const parsed = buildCompleteSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;

  const mpu = c.env.MEDIA.resumeMultipartUpload(d.key, d.uploadId);
  await mpu.complete(d.parts);

  const db = drizzle(c.env.DB);
  const inserted = await db
    .insert(appBuilds)
    .values({
      appId: id,
      version: d.version,
      fileKey: d.key,
      fileSize: d.size,
      notes: d.notes || null,
      createdAt: new Date(),
    })
    .returning();
  return c.json(ok({ build: inserted[0] }));
});

adminRoutes.post("/builds/abort", requireRole("crew"), async (c) => {
  const body = (await c.req.json().catch(() => null)) as { key?: string; uploadId?: string } | null;
  if (!body?.key || !BUILD_KEY_RE.test(body.key) || !body.uploadId)
    return c.json(err("invalid_input"), 400);
  const mpu = c.env.MEDIA.resumeMultipartUpload(body.key, body.uploadId);
  await mpu.abort().catch(() => {});
  return c.json(ok({ aborted: true }));
});

adminRoutes.delete("/builds/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(appBuilds).where(eq(appBuilds.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (!canManageApp(c.get("user"), await appOwnerId(c.env.DB, rows[0].appId))) return c.json(err("forbidden"), 403);
  await c.env.MEDIA.delete(rows[0].fileKey);
  await db.delete(appBuilds).where(eq(appBuilds.id, id));
  return c.json(ok({ deleted: id }));
});

// 방문자/사이트 통계 — staff 이상 열람
adminRoutes.get("/stats", requireRole("staff"), async (c) => {
  const db = drizzle(c.env.DB);
  const today = kstDate();
  const from = kstDate(-13); // 오늘 포함 최근 14일

  const days = await db
    .select()
    .from(visitStats)
    .where(gte(visitStats.date, from))
    .orderBy(asc(visitStats.date));

  const totalsRow = await db
    .select({
      visitors: sql<number>`coalesce(sum(${visitStats.visitors}), 0)`,
      pageviews: sql<number>`coalesce(sum(${visitStats.pageviews}), 0)`,
      since: sql<string | null>`min(${visitStats.date})`,
    })
    .from(visitStats);

  const memberCountRow = await db.select({ n: sql<number>`count(*)` }).from(users);
  const downloadRow = await db
    .select({ n: sql<number>`coalesce(sum(${apps.downloadCount}), 0)` })
    .from(apps);

  // 오래된 방문 로그 정리 (35일 이전 — 집계는 visit_stats에 영구 보존)
  await db.delete(visitLogs).where(lt(visitLogs.date, kstDate(-35)));

  const todayRow = days.find((d) => d.date === today);
  return c.json(
    ok({
      today: { date: today, visitors: todayRow?.visitors ?? 0, pageviews: todayRow?.pageviews ?? 0 },
      days,
      totals: totalsRow[0],
      memberCount: memberCountRow[0].n,
      downloadTotal: downloadRow[0].n,
    }),
  );
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

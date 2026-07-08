import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { and, asc, eq } from "drizzle-orm";
import QRCode from "qrcode/lib/browser";
import { apps, appScreenshots, downloadLogs } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";

export const appRoutes = new Hono<{ Bindings: Env }>();

appRoutes.get("/", async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db
    .select({
      id: apps.id,
      slug: apps.slug,
      name: apps.name,
      tagline: apps.tagline,
      iconUrl: apps.iconUrl,
      status: apps.status,
      downloadCount: apps.downloadCount,
      storeUrlAndroid: apps.storeUrlAndroid,
      storeUrlIos: apps.storeUrlIos,
    })
    .from(apps)
    .orderBy(asc(apps.id));
  return c.json(ok({ apps: rows }));
});

appRoutes.get("/:slug", async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug"))).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const shots = await db
    .select({ id: appScreenshots.id, imageUrl: appScreenshots.imageUrl })
    .from(appScreenshots)
    .where(eq(appScreenshots.appId, rows[0].id))
    .orderBy(asc(appScreenshots.sort));
  return c.json(ok({ app: rows[0], screenshots: shots }));
});

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

// 스토어 이동 시 다운로드 카운터 +1 — IP+UA 해시 기준 하루 1회 (CLAUDE.md 5-2절)
// 개인정보 보호: IP/UA 원문은 저장하지 않고 해시만 저장 (11절)
appRoutes.post("/:slug/count", async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug"))).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const app = rows[0];

  const ip = c.req.header("CF-Connecting-IP") ?? "0.0.0.0";
  const ua = c.req.header("User-Agent") ?? "unknown";
  const date = new Date().toISOString().slice(0, 10);
  const ipHash = await sha256Hex(`${ip}:exansys`);
  const uaHash = await sha256Hex(`${ua}:exansys`);

  const dup = await db
    .select({ id: downloadLogs.id })
    .from(downloadLogs)
    .where(
      and(
        eq(downloadLogs.appId, app.id),
        eq(downloadLogs.ipHash, ipHash),
        eq(downloadLogs.uaHash, uaHash),
        eq(downloadLogs.date, date),
      ),
    )
    .limit(1);

  let count = app.downloadCount;
  if (dup.length === 0) {
    await db.insert(downloadLogs).values({ appId: app.id, ipHash, uaHash, date });
    count += 1;
    await db.update(apps).set({ downloadCount: count }).where(eq(apps.id, app.id));
  }
  return c.json(ok({ downloadCount: count }));
});

// 스토어 링크 QR 코드 (SVG) — 홍보물용 다운로드 가능 (CLAUDE.md 5-2절)
appRoutes.get("/:slug/qr", async (c) => {
  const platform = c.req.query("platform") === "ios" ? "ios" : "android";
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug"))).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const url = platform === "ios" ? rows[0].storeUrlIos : rows[0].storeUrlAndroid;
  if (!url) return c.json(err("store_url_not_set"), 404);

  const svg = await QRCode.toString(url, {
    type: "svg",
    errorCorrectionLevel: "M",
    margin: 2,
    width: 512,
    color: { dark: "#12141C", light: "#FFFFFF" },
  });
  return c.body(svg, 200, {
    "Content-Type": "image/svg+xml",
    "Cache-Control": "public, max-age=3600",
    "Content-Disposition": `inline; filename="${rows[0].slug}-${platform}-qr.svg"`,
  });
});

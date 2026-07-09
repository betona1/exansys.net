// 공개 미디어 서빙 — 앱 쇼케이스 스크린샷 (R2 shots/, 누구나 열람 가능)
// 크루 갤러리(gallery/)는 crew.ts에서 crew 이상으로 게이트, APK(builds/)는 apps.ts에서 member 이상
import { Hono } from "hono";
import type { Env } from "../types";
import { err } from "../types";

export const mediaRoutes = new Hono<{ Bindings: Env }>();

mediaRoutes.get("/media/shots/:file", async (c) => {
  const file = c.req.param("file") ?? "";
  if (!/^[a-z0-9-]+\.(webp|gif|mp4)$/.test(file)) return c.json(err("not_found"), 404);
  const obj = await c.env.MEDIA.get(`shots/${file}`);
  if (!obj) return c.json(err("not_found"), 404);
  return c.body(obj.body, 200, {
    "Content-Type": obj.httpMetadata?.contentType ?? "application/octet-stream",
    "Cache-Control": "public, max-age=604800, immutable",
  });
});

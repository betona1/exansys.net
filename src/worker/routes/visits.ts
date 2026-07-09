// 방문자 카운트 — 페이지 로드마다 호출, 하루 단위 유니크 방문자 집계 (CLAUDE.md 11절: IP/UA 해시만 저장)
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { sql } from "drizzle-orm";
import { visitLogs, visitStats } from "../../db/schema";
import type { Env } from "../types";
import { ok } from "../types";

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

// 한국 시간 기준 날짜 (워커는 UTC로 돌기 때문에 KST 하루 경계를 맞춘다)
export function kstDate(offsetDays = 0): string {
  return new Date(Date.now() + 9 * 3600_000 + offsetDays * 86_400_000).toISOString().slice(0, 10);
}

export const visitRoutes = new Hono<{ Bindings: Env }>();

visitRoutes.post("/track", async (c) => {
  const date = kstDate();
  const ip = c.req.header("cf-connecting-ip") ?? "0.0.0.0";
  const ua = c.req.header("user-agent") ?? "";
  const visitorHash = await sha256Hex(`${date}:${ip}:${ua}:exansys`);

  const db = drizzle(c.env.DB);
  // 오늘 처음 온 방문자인지 — 유니크 인덱스 충돌 여부로 판단
  const inserted = await db
    .insert(visitLogs)
    .values({ date, visitorHash })
    .onConflictDoNothing()
    .returning({ id: visitLogs.id });
  const isNewVisitor = inserted.length > 0;

  await db
    .insert(visitStats)
    .values({ date, pageviews: 1, visitors: isNewVisitor ? 1 : 0 })
    .onConflictDoUpdate({
      target: visitStats.date,
      set: {
        pageviews: sql`${visitStats.pageviews} + 1`,
        visitors: sql`${visitStats.visitors} + ${isNewVisitor ? 1 : 0}`,
      },
    });

  return c.json(ok({ counted: true }));
});

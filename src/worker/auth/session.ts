import type { Context } from "hono";
import type { Env as HonoEnv } from "hono";
import { getCookie, setCookie, deleteCookie } from "hono/cookie";
import type { Env, SessionUser } from "../types";

const COOKIE = "session";
const TTL_SECONDS = 30 * 24 * 60 * 60; // 30일 (CLAUDE.md 4절)

// exansys.net 계열이면 서브도메인(techdex.exansys.net 등) 간 세션 공유를 위해 상위 도메인으로 설정.
// 로컬·프리뷰(localhost 등)는 도메인 미지정(host-only).
function cookieDomain<E extends HonoEnv & { Bindings: Env }>(c: Context<E>): string | undefined {
  try {
    const host = new URL(c.req.url).hostname;
    return host === "exansys.net" || host.endsWith(".exansys.net") ? ".exansys.net" : undefined;
  } catch {
    return undefined;
  }
}

function randomToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export async function createSession<E extends HonoEnv & { Bindings: Env }>(
  c: Context<E>,
  user: SessionUser,
): Promise<void> {
  const token = randomToken();
  await c.env.SESSIONS.put(`sess:${token}`, JSON.stringify(user), {
    expirationTtl: TTL_SECONDS,
  });
  setCookie(c, COOKIE, token, {
    httpOnly: true,
    secure: true,
    sameSite: "Lax",
    path: "/",
    maxAge: TTL_SECONDS,
    domain: cookieDomain(c),
  });
}

export async function readSession<E extends HonoEnv & { Bindings: Env }>(
  c: Context<E>,
): Promise<SessionUser | null> {
  const token = getCookie(c, COOKIE);
  if (!token) return null;
  const raw = await c.env.SESSIONS.get(`sess:${token}`);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionUser;
  } catch {
    return null;
  }
}

export async function destroySession<E extends HonoEnv & { Bindings: Env }>(c: Context<E>): Promise<void> {
  const token = getCookie(c, COOKIE);
  if (token) await c.env.SESSIONS.delete(`sess:${token}`);
  deleteCookie(c, COOKIE, { path: "/", domain: cookieDomain(c) });
}

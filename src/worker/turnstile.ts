// Cloudflare Turnstile 서버 검증 (CLAUDE.md 2절 — 게시판 작성 폼 스팸 방지)
import type { Env } from "./types";

/** 시크릿이 설정되지 않은 환경(로컬 등)에서는 검증을 건너뛴다 */
export async function verifyTurnstile(
  env: Env,
  token: string | undefined,
  ip: string | undefined,
): Promise<boolean> {
  if (!env.TURNSTILE_SECRET_KEY) return true;
  if (!token) return false;
  const body = new URLSearchParams({
    secret: env.TURNSTILE_SECRET_KEY,
    response: token,
  });
  if (ip) body.set("remoteip", ip);
  const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });
  if (!res.ok) return false;
  const json: any = await res.json();
  return json.success === true;
}

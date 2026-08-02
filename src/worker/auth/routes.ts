import { Hono } from "hono";
import type { Context } from "hono";
import { getCookie, setCookie, deleteCookie } from "hono/cookie";
import { drizzle } from "drizzle-orm/d1";
import { and, eq } from "drizzle-orm";
import { users } from "../../db/schema";
import type { Env, Role } from "../types";
import { ok, err } from "../types";
import { enabledProviders, getProvider, type ProviderName } from "./providers";
import { createSession, destroySession, readSession } from "./session";

import { emailAuthRoutes } from "./email";

const STATE_COOKIE = "oauth_state";

function isProviderName(v: string): v is ProviderName {
  return v === "google" || v === "github" || v === "kakao" || v === "naver";
}

export const authRoutes = new Hono<{ Bindings: Env }>();

authRoutes.get("/providers", (c) =>
  c.json(
    ok({
      providers: enabledProviders(c.env),
      emailLogin: Boolean(c.env.RESEND_API_KEY),
    }),
  ),
);

authRoutes.route("/email", emailAuthRoutes);

/** 로그인 뒤 돌아갈 곳을 담아 두는 쿠키 */
const NEXT_COOKIE = "auth_next";

/**
 * 돌아갈 곳을 안전하게 다듬는다.
 *
 * **우리 사이트 안의 경로만 받는다.** `//evil.com` 같은 것을 그대로 쓰면
 * 로그인 직후 남의 사이트로 튕기는 통로(open redirect)가 된다.
 */
function safeNext(raw: string | undefined): string {
  const v = (raw ?? "").trim();
  if (!v.startsWith("/") || v.startsWith("//")) return "/";
  return v;
}

/** 담아 둔 곳을 꺼내고 지운다 */
function takeNext(c: Context<{ Bindings: Env }>): string {
  const v = getCookie(c, NEXT_COOKIE);
  deleteCookie(c, NEXT_COOKIE, { path: "/" });
  return safeNext(v);
}

authRoutes.get("/:provider/start", (c) => {
  const name = c.req.param("provider");
  if (!isProviderName(name)) return c.json(err("unknown_provider"), 400);
  const provider = getProvider(c.env, name);
  if (!provider) return c.json(err("provider_not_configured"), 400);

  const state = crypto.randomUUID();
  setCookie(c, STATE_COOKIE, `${name}:${state}`, {
    httpOnly: true,
    secure: true,
    sameSite: "Lax",
    path: "/",
    maxAge: 600,
  });
  // 로그인 뒤 돌아갈 곳을 기억해 둔다. 없으면 늘 홈으로 떨어져서,
  // "로그인했는데 아무 일도 안 일어난다" 가 된다 (앱 연결이 이래서 막혔다).
  // 우리 사이트 안의 경로만 받는다 — 남의 주소로 튕기는 통로를 만들지 않는다
  setCookie(c, NEXT_COOKIE, safeNext(c.req.query("next")), {
    httpOnly: true,
    secure: true,
    sameSite: "Lax",
    path: "/",
    maxAge: 600,
  });
  const redirectUri = `${c.env.SITE_URL}/api/auth/${name}/callback`;
  return c.redirect(provider.authorizeUrl(redirectUri, state));
});

authRoutes.get("/:provider/callback", async (c) => {
  const name = c.req.param("provider");
  if (!isProviderName(name)) return c.json(err("unknown_provider"), 400);
  const provider = getProvider(c.env, name);
  if (!provider) return c.json(err("provider_not_configured"), 400);

  const code = c.req.query("code");
  const state = c.req.query("state");
  const stateCookie = getCookie(c, STATE_COOKIE);
  deleteCookie(c, STATE_COOKIE, { path: "/" });
  if (!code || !state || stateCookie !== `${name}:${state}`) {
    return c.redirect("/?login=error");
  }

  try {
    const redirectUri = `${c.env.SITE_URL}/api/auth/${name}/callback`;
    const token = await provider.exchange(code, redirectUri);
    const profile = await provider.profile(token);

    const db = drizzle(c.env.DB);
    const found = await db
      .select()
      .from(users)
      .where(and(eq(users.provider, name), eq(users.providerId, profile.providerId)))
      .limit(1);

    // 대표 시드: GitHub 로그인 아이디가 ADMIN_GITHUB_LOGIN이면 admin (CLAUDE.md 3절)
    const isSeedAdmin =
      name === "github" && profile.handle?.toLowerCase() === c.env.ADMIN_GITHUB_LOGIN.toLowerCase();

    let userId: number;
    let role: Role;
    if (found.length === 0) {
      role = isSeedAdmin ? "admin" : "member";
      const inserted = await db
        .insert(users)
        .values({
          provider: name,
          providerId: profile.providerId,
          name: profile.name,
          avatarUrl: profile.avatarUrl,
          role,
          createdAt: new Date(),
        })
        .returning({ id: users.id });
      userId = inserted[0].id;
    } else {
      userId = found[0].id;
      role = isSeedAdmin && found[0].role !== "admin" ? "admin" : (found[0].role as Role);
      await db
        .update(users)
        .set({ name: profile.name, avatarUrl: profile.avatarUrl, role })
        .where(eq(users.id, userId));
    }

    await createSession(c, {
      userId,
      provider: name,
      name: profile.name,
      avatarUrl: profile.avatarUrl,
      role,
    });
    return c.redirect(takeNext(c));
  } catch (e) {
    console.error("oauth callback error", e);
    return c.redirect("/?login=error");
  }
});

authRoutes.get("/me", async (c) => {
  const sess = await readSession(c);
  if (!sess) return c.json(ok({ user: null }));
  // 역할 승격이 즉시 반영되도록 DB에서 최신 역할을 읽는다
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(users).where(eq(users.id, sess.userId)).limit(1);
  if (rows.length === 0) {
    await destroySession(c);
    return c.json(ok({ user: null }));
  }
  const u = rows[0];
  return c.json(
    ok({
      user: {
        id: u.id,
        name: u.name,
        avatarUrl: u.avatarUrl,
        role: u.role,
        provider: u.provider,
      },
    }),
  );
});

authRoutes.post("/logout", async (c) => {
  await destroySession(c);
  return c.json(ok({ loggedOut: true }));
});

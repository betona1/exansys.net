export interface Env {
  DB: D1Database;
  SESSIONS: KVNamespace;
  ADMIN_GITHUB_LOGIN: string;
  SITE_URL: string;
  GITHUB_CLIENT_ID?: string;
  GITHUB_CLIENT_SECRET?: string;
  GOOGLE_CLIENT_ID?: string;
  GOOGLE_CLIENT_SECRET?: string;
  KAKAO_CLIENT_ID?: string;
  KAKAO_CLIENT_SECRET?: string;
}

export type Role = "member" | "crew" | "staff" | "admin";

export const ROLE_LEVEL: Record<Role, number> = {
  member: 0,
  crew: 1,
  staff: 2,
  admin: 3,
};

export type SessionUser = {
  userId: number;
  provider: string;
  name: string;
  avatarUrl: string | null;
  role: Role;
};

/** API 응답 통일 형식 (CLAUDE.md 10절) */
export const ok = <T>(data: T) => ({ ok: true as const, data });
export const err = (error: string) => ({ ok: false as const, error });

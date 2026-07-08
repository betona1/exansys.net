export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };

export async function api<T>(path: string, init?: RequestInit): Promise<ApiResult<T>> {
  try {
    const res = await fetch(path, {
      credentials: "same-origin",
      headers: init?.body ? { "Content-Type": "application/json" } : undefined,
      ...init,
    });
    return (await res.json()) as ApiResult<T>;
  } catch {
    return { ok: false, error: "network_error" };
  }
}

export type Me = {
  id: number;
  name: string;
  avatarUrl: string | null;
  role: "member" | "crew" | "staff" | "admin";
  provider: string;
} | null;

export type AppRow = {
  id: number;
  slug: string;
  name: string;
  tagline: string | null;
  description?: string | null;
  iconUrl: string | null;
  status: "planning" | "development" | "released";
  downloadCount: number;
  storeUrlAndroid: string | null;
  storeUrlIos: string | null;
};

export const STATUS_LABEL: Record<AppRow["status"], string> = {
  planning: "기획 중",
  development: "개발 중",
  released: "출시됨",
};

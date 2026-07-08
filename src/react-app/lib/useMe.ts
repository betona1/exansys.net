import { useCallback, useEffect, useState } from "react";
import { api, type Me } from "./api";

export function useMe() {
  const [me, setMe] = useState<Me>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const res = await api<{ user: Me }>("/api/auth/me");
    setMe(res.ok ? res.data.user : null);
    setLoading(false);
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const logout = useCallback(async () => {
    await api("/api/auth/logout", { method: "POST" });
    setMe(null);
  }, []);

  return { me, loading, refresh, logout };
}

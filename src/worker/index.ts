import { Hono } from "hono";

// Phase 2에서 D1/KV/R2 바인딩이 추가되면 Env 타입을 wrangler types로 생성해 교체한다.
type Env = Record<string, never>;

const app = new Hono<{ Bindings: Env }>();

app.get("/api/health", (c) =>
  c.json({ ok: true, data: { service: "exansys-site", phase: 1 } }),
);

app.notFound((c) => c.json({ ok: false, error: "not_found" }, 404));

export default app;

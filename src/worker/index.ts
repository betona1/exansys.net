import { Hono } from "hono";
import type { Env } from "./types";
import { ok, err } from "./types";
import { authRoutes } from "./auth/routes";
import { appRoutes } from "./routes/apps";
import { adminRoutes } from "./routes/admin";

const app = new Hono<{ Bindings: Env }>();

app.get("/api/health", (c) => c.json(ok({ service: "exansys-site", phase: 2 })));

app.route("/api/auth", authRoutes);
app.route("/api/apps", appRoutes);
app.route("/api/admin", adminRoutes);

app.notFound((c) => c.json(err("not_found"), 404));

export default app;

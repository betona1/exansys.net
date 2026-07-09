import { Hono } from "hono";
import type { Env } from "./types";
import { ok, err } from "./types";
import { authRoutes } from "./auth/routes";
import { appRoutes } from "./routes/apps";
import { adminRoutes } from "./routes/admin";
import { inquiryRoutes } from "./routes/inquiries";
import { commentRoutes } from "./routes/comments";
import { privacyRoutes } from "./routes/privacy";
import { crewRoutes } from "./routes/crew";
import { visitRoutes } from "./routes/visits";
import { mediaRoutes } from "./routes/media";

const app = new Hono<{ Bindings: Env }>();

app.get("/api/health", (c) => c.json(ok({ service: "exansys-site", phase: 4 })));

// 프론트에서 필요한 공개 설정 값
app.get("/api/config", (c) =>
  c.json(ok({ turnstileSiteKey: c.env.TURNSTILE_SITE_KEY ?? null })),
);

app.route("/api/auth", authRoutes);
app.route("/api/inquiries", inquiryRoutes);
app.route("/api", commentRoutes); // /api/apps/:slug/comments, /api/comments/:id
app.route("/api", privacyRoutes); // /api/apps/:slug/privacy
app.route("/api", crewRoutes); // /api/crew/*, /api/media/gallery/*
app.route("/api", mediaRoutes); // /api/media/shots/* (공개 스크린샷)
app.route("/api/visits", visitRoutes);
app.route("/api/apps", appRoutes);
app.route("/api/admin", adminRoutes);

app.notFound((c) => c.json(err("not_found"), 404));

export default app;

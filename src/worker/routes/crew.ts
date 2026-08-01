// 앱튜버갤러리 (앱개발자 모임 내부 갤러리) (CLAUDE.md 5-6절)
// crew 역할 이상만 접근. 이미지 R2 저장 (클라이언트에서 webp 변환 후 업로드, 최대 5MB)
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { asc, desc, eq, sql } from "drizzle-orm";
import { z } from "zod";
import { galleryPosts, galleryImages, galleryComments, users } from "../../db/schema";
import type { Env, Role } from "../types";
import { ok, err, ROLE_LEVEL } from "../types";
import { requireRole, type AuthedUser } from "../middleware";
import { readSession } from "../auth/session";
import appEducationHtml from "../resources/app-education.html?raw";

const MAX_IMAGE_BYTES = 5 * 1024 * 1024; // 5MB (5-6절)

// 앱튜버 자료실 — 학습용 정적 문서(HTML)를 crew 전용으로 서빙.
// 새 자료는 여기에 항목을 추가하면 목록·서빙에 함께 반영된다.
const RESOURCES: Record<
  string,
  { title: string; description: string; emoji: string; html: string }
> = {
  "app-education": {
    title: "앱 개발 교육 · 통합 대시보드",
    description: "기획 · 시장 분석 · 기초용어 · 개발언어 · 역할&DB · 세팅까지 초보 팀을 위한 학습 자료 모음",
    emoji: "📚",
    html: appEducationHtml,
  },
};

const postSchema = z.object({
  title: z.string().min(2).max(80),
  body: z.string().max(2000).optional().nullable(),
  linkUrl: z.string().url().max(500).optional().nullable().or(z.literal("")),
  imageKeys: z.array(z.string().regex(/^gallery\/[a-z0-9-]+\.webp$/)).max(5).optional(),
});

const commentSchema = z.object({
  body: z.string().min(1).max(1000),
});

type Vars = { Variables: { user: AuthedUser } };

export const crewRoutes = new Hono<{ Bindings: Env } & Vars>();

/** 이미지 업로드 — webp 원본 바이트를 R2에 저장 */
crewRoutes.post("/crew/upload", requireRole("crew"), async (c) => {
  const type = c.req.header("Content-Type") ?? "";
  if (!type.startsWith("image/webp")) return c.json(err("webp_only"), 400);
  const len = Number(c.req.header("Content-Length") ?? "0");
  if (!len || len > MAX_IMAGE_BYTES) return c.json(err("max_5mb"), 400);

  const body = await c.req.arrayBuffer();
  if (body.byteLength > MAX_IMAGE_BYTES) return c.json(err("max_5mb"), 400);

  const key = `gallery/${crypto.randomUUID()}.webp`;
  await c.env.MEDIA.put(key, body, {
    httpMetadata: { contentType: "image/webp" },
  });
  return c.json(ok({ key, url: `/api/media/${key}` }));
});

/** 갤러리 이미지 서빙 — 갤러리는 공개 열람이므로 누구나 */
crewRoutes.get("/media/gallery/:file", async (c) => {
  const key = `gallery/${c.req.param("file") ?? ""}`;
  const obj = await c.env.MEDIA.get(key);
  if (!obj) return c.json(err("not_found"), 404);
  return c.body(obj.body, 200, {
    "Content-Type": obj.httpMetadata?.contentType ?? "image/webp",
    "Cache-Control": "public, max-age=86400",
  });
});

/** 자료실 목록 — crew 이상 (메타데이터만, HTML 본문 제외) */
crewRoutes.get("/crew/resources", requireRole("crew"), (c) => {
  const list = Object.entries(RESOURCES).map(([slug, r]) => ({
    slug,
    title: r.title,
    description: r.description,
    emoji: r.emoji,
  }));
  return c.json(ok({ resources: list }));
});

/**
 * 자료실 문서 서빙 — 브라우저 새 탭 내비게이션용.
 * 인증 실패 시 JSON 대신 /crew 안내 페이지로 리다이렉트(깔끔한 UX).
 * requireRole과 동일하게 DB 최신 역할로 재확인(로그인 후 승격 반영).
 */
crewRoutes.get("/crew/resources/:slug", async (c) => {
  const res = RESOURCES[c.req.param("slug") ?? ""];
  if (!res) return c.redirect("/crew");
  const sess = await readSession(c);
  if (!sess) return c.redirect("/crew");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(users).where(eq(users.id, sess.userId)).limit(1);
  if (rows.length === 0 || ROLE_LEVEL[rows[0].role as Role] < ROLE_LEVEL.crew) {
    return c.redirect("/crew");
  }
  return c.html(res.html, 200, { "Cache-Control": "private, max-age=3600" });
});

/** 게시글 목록 — 카드형 갤러리용 (첫 이미지 + 댓글 수) */
crewRoutes.get("/crew/posts", async (c) => {
  const db = drizzle(c.env.DB);
  const posts = await db
    .select({
      id: galleryPosts.id,
      title: galleryPosts.title,
      body: galleryPosts.body,
      linkUrl: galleryPosts.linkUrl,
      createdAt: galleryPosts.createdAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(galleryPosts)
    .leftJoin(users, eq(galleryPosts.userId, users.id))
    .orderBy(desc(galleryPosts.id))
    .limit(100);

  const images = await db
    .select({ postId: galleryImages.postId, imageUrl: galleryImages.imageUrl, sort: galleryImages.sort })
    .from(galleryImages)
    .orderBy(asc(galleryImages.sort));
  const counts = await db
    .select({ postId: galleryComments.postId, cnt: sql<number>`count(*)` })
    .from(galleryComments)
    .groupBy(galleryComments.postId);

  const firstImage = new Map<number, string>();
  for (const img of images) if (!firstImage.has(img.postId)) firstImage.set(img.postId, img.imageUrl);
  const countMap = new Map(counts.map((r) => [r.postId, Number(r.cnt)]));

  return c.json(
    ok({
      posts: posts.map((p) => ({
        ...p,
        thumbnail: firstImage.get(p.id) ?? null,
        commentCount: countMap.get(p.id) ?? 0,
      })),
    }),
  );
});

/** 게시글 작성 */
crewRoutes.post("/crew/posts", requireRole("crew"), async (c) => {
  const parsed = postSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const d = parsed.data;
  const db = drizzle(c.env.DB);
  const inserted = await db
    .insert(galleryPosts)
    .values({
      userId: c.get("user").id,
      title: d.title,
      body: d.body || null,
      linkUrl: d.linkUrl || null,
      createdAt: new Date(),
    })
    .returning({ id: galleryPosts.id });
  const postId = inserted[0].id;

  if (d.imageKeys?.length) {
    for (let i = 0; i < d.imageKeys.length; i++) {
      await db.insert(galleryImages).values({
        postId,
        imageUrl: `/api/media/${d.imageKeys[i]}`,
        sort: i,
      });
    }
  }
  return c.json(ok({ id: postId }));
});

/** 게시글 상세 + 댓글 — 공개 열람 (로그인 시 mine 플래그로 본인 글/댓글 표시) */
crewRoutes.get("/crew/posts/:id", async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const rows = await db
    .select({
      id: galleryPosts.id,
      userId: galleryPosts.userId,
      title: galleryPosts.title,
      body: galleryPosts.body,
      linkUrl: galleryPosts.linkUrl,
      createdAt: galleryPosts.createdAt,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(galleryPosts)
    .leftJoin(users, eq(galleryPosts.userId, users.id))
    .where(eq(galleryPosts.id, id))
    .limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);

  const sess = await readSession(c);
  const meId = sess?.userId ?? -1;
  const images = await db
    .select({ id: galleryImages.id, imageUrl: galleryImages.imageUrl })
    .from(galleryImages)
    .where(eq(galleryImages.postId, id))
    .orderBy(asc(galleryImages.sort));
  const comments = await db
    .select({
      id: galleryComments.id,
      body: galleryComments.body,
      createdAt: galleryComments.createdAt,
      userId: galleryComments.userId,
      authorName: users.name,
      authorAvatar: users.avatarUrl,
    })
    .from(galleryComments)
    .leftJoin(users, eq(galleryComments.userId, users.id))
    .where(eq(galleryComments.postId, id))
    .orderBy(asc(galleryComments.id));

  return c.json(
    ok({
      post: { ...rows[0], mine: rows[0].userId === meId },
      images,
      comments: comments.map((cm) => ({ ...cm, mine: cm.userId === meId })),
    }),
  );
});

/** 댓글 작성 */
crewRoutes.post("/crew/posts/:id/comments", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const parsed = commentSchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) return c.json(err("invalid_input"), 400);
  const db = drizzle(c.env.DB);
  const found = await db.select({ id: galleryPosts.id }).from(galleryPosts).where(eq(galleryPosts.id, id)).limit(1);
  if (found.length === 0) return c.json(err("not_found"), 404);
  await db.insert(galleryComments).values({
    postId: id,
    userId: c.get("user").id,
    body: parsed.data.body,
    createdAt: new Date(),
  });
  return c.json(ok({ commented: true }));
});

/** 게시글 삭제 — 작성자 또는 admin (R2 이미지도 함께 정리) */
crewRoutes.delete("/crew/posts/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const me = c.get("user");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(galleryPosts).where(eq(galleryPosts.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (rows[0].userId !== me.id && ROLE_LEVEL[me.role] < ROLE_LEVEL.admin) {
    return c.json(err("forbidden"), 403);
  }
  const images = await db
    .select({ imageUrl: galleryImages.imageUrl })
    .from(galleryImages)
    .where(eq(galleryImages.postId, id));
  for (const img of images) {
    const key = img.imageUrl.replace("/api/media/", "");
    if (key.startsWith("gallery/")) await c.env.MEDIA.delete(key);
  }
  await db.delete(galleryComments).where(eq(galleryComments.postId, id));
  await db.delete(galleryImages).where(eq(galleryImages.postId, id));
  await db.delete(galleryPosts).where(eq(galleryPosts.id, id));
  return c.json(ok({ deleted: id }));
});

/** 댓글 삭제 — 작성자 또는 admin */
crewRoutes.delete("/crew/comments/:id", requireRole("crew"), async (c) => {
  const id = Number(c.req.param("id"));
  if (!Number.isInteger(id)) return c.json(err("invalid_id"), 400);
  const me = c.get("user");
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(galleryComments).where(eq(galleryComments.id, id)).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  if (rows[0].userId !== me.id && ROLE_LEVEL[me.role] < ROLE_LEVEL.admin) {
    return c.json(err("forbidden"), 403);
  }
  await db.delete(galleryComments).where(eq(galleryComments.id, id));
  return c.json(ok({ deleted: id }));
});

// ─────────────────────────────────────────────────────────────
// 일회성 시드 — 출시 완료된 자사 앱 2건을 앱튜버갤러리에 올린다.
// 멱등: 같은 제목의 글이 이미 있으면 아무것도 하지 않는다.
// 등록이 끝나면 이 라우트는 제거한다 (임시 코드).
// ─────────────────────────────────────────────────────────────
const RELEASED_APP_POSTS: {
  title: string;
  linkUrl: string;
  body: string;
  images: string[];
}[] = [
  {
    title: "VibeQuest — AI·코딩 용어 퀘스트 (Google Play 출시)",
    linkUrl: "https://play.google.com/store/apps/details?id=net.exansys.vibequest",
    body: `🐾 어려운 개발 용어, 퀘스트로 클리어!

"프롬프트가 뭐야? API는? 커밋은 또 뭐지?"
AI로 코딩을 시작했는데 용어가 벽처럼 느껴진다면 — VibeQuest가 딱이에요.

러시안 블루 고양이 '비비'와 함께, 하루 3분 퀘스트로
AI·프로그래밍·웹·데이터베이스 용어를 하나씩 내 것으로 만들어 보세요.

⚡ 하루 3분, 부담 없는 퀘스트
· O/X, 4지선다, 주관식, 글자 조립, 짝 맞추기 — 5가지 문제
· 하트나 생명 제한 없음! 틀려도 계속 배울 수 있어요
· 틀리면 왜 틀렸는지 차근차근 설명

🧠 과학적인 복습 시스템
· 틀린 용어는 자동으로 복습 일정에 등록
· 잊어버릴 때쯤 다시 만나는 간격 반복 학습

📚 867개 용어 사전
· 생성형 AI, 프롬프트, 에이전트, 바이브코딩부터
· 프로그래밍 기초, 웹, 백엔드, DB, Git, UX까지

🔒 가입 없이, 광고 없이 — 학습 기록은 내 기기에만 저장

· 패키지: net.exansys.vibequest
· 카테고리: 교육
· 개발: EXANSYS`,
    images: [
      "/showcase/vibequest/feature_graphic.webp",
      "/showcase/vibequest/icon_512.webp",
      "/showcase/vibequest/02_home.webp",
      "/showcase/vibequest/03_quiz.webp",
      "/showcase/vibequest/04_wrong.webp",
      "/showcase/vibequest/07_glossary.webp",
      "/showcase/vibequest/06_result.webp",
      "/showcase/vibequest/01_intro_a.webp",
    ],
  },
  {
    title: "Log Challenge — 습관 인증 챌린지 (Google Play 출시)",
    linkUrl: "https://play.google.com/store/apps/details?id=com.keywordream.keepup",
    body: `습관은 '기록(Log)'으로 남을 때 진짜가 됩니다.

Log Challenge는 좋은 습관을 매일 인증하고 도장으로 남기는 습관 챌린지 앱입니다.
미루면 사라지는 결심을, 마감 전 알림이 놓치지 않게 붙잡아 줍니다.

📸 다양한 인증 방법
· 사진 (날짜·시각 자동 워터마크)
· 타이머 (명상 모드·호흡 가이드)
· 녹음, 동영상, URL
· 마감 3시간 / 1시간 / 30분 전 알림

🏅 두 가지 챌린지 방식
· 적립형 — 매일 / 주6일 실행
· 결과형 — 주1회 · 15일 · 1회성 인증
· 도장이 찍힌 시즌 달력에서 달성률과 최장 연속 확인

🔒 데이터 안전
· 모든 기록은 기기 내 저장
· ZIP 백업과 자동 스냅샷 복구

· 패키지: com.keywordream.keepup
· 카테고리: 생산성
· 태그: 습관 형성 · 자기계발 · 할 일 관리`,
    images: [
      "/showcase/keepup/00_feature_graphic.webp",
      "/showcase/keepup/icon_512.webp",
      "/showcase/keepup/01_home.webp",
      "/showcase/keepup/02_routines.webp",
      "/showcase/keepup/03_verify.webp",
      "/showcase/keepup/04_calendar.webp",
      "/showcase/keepup/05_alarm.webp",
    ],
  },
];

crewRoutes.post("/crew/seed-released-apps", async (c) => {
  const db = drizzle(c.env.DB);

  // 글쓴이는 대표(admin) 계정으로 단다
  const admin = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.role, "admin"))
    .orderBy(asc(users.id))
    .limit(1);
  if (admin.length === 0) return c.json(err("no_admin_user"), 400);

  const created: string[] = [];
  const skipped: string[] = [];

  for (const post of RELEASED_APP_POSTS) {
    const dup = await db
      .select({ id: galleryPosts.id })
      .from(galleryPosts)
      .where(eq(galleryPosts.title, post.title))
      .limit(1);
    if (dup.length > 0) {
      skipped.push(post.title);
      continue;
    }
    const inserted = await db
      .insert(galleryPosts)
      .values({
        userId: admin[0].id,
        title: post.title,
        body: post.body,
        linkUrl: post.linkUrl,
        createdAt: new Date(),
      })
      .returning({ id: galleryPosts.id });
    for (let i = 0; i < post.images.length; i++) {
      await db
        .insert(galleryImages)
        .values({ postId: inserted[0].id, imageUrl: post.images[i], sort: i });
    }
    created.push(post.title);
  }

  return c.json(ok({ created, skipped }));
});

import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { and, asc, desc, eq, sql } from "drizzle-orm";
import QRCode from "qrcode/lib/browser";
import { apps, appBuilds, appScreenshots, downloadLogs } from "../../db/schema";
import type { Env } from "../types";
import { ok, err } from "../types";
import { ensureColumns, APPS_GALLERY_COLUMNS } from "../lib/ensure-columns";
import { requireRole } from "../middleware";
import { readSession } from "../auth/session";

// owner_id 컬럼은 Drizzle 스키마에 넣지 않고(기존 전체 SELECT 안전) 런타임 ALTER + 원시 SQL로만 다룬다.
// 아이솔레이트 단위 캐시로 매 요청 ALTER 시도를 피한다(ALTER는 DB 전역 1회 반영).
let _ownerColReady = false;
export async function ensureOwnerCol(DB: D1Database) {
  if (_ownerColReady) return;
  try {
    await DB.prepare("ALTER TABLE apps ADD COLUMN owner_id INTEGER").run();
  } catch {
    /* 이미 존재하면 무시 */
  }
  _ownerColReady = true;
}

export const appRoutes = new Hono<{ Bindings: Env }>();

appRoutes.get("/", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureColumns(db, "apps", APPS_GALLERY_COLUMNS);
  const rows = await db
    .select({
      id: apps.id,
      slug: apps.slug,
      name: apps.name,
      tagline: apps.tagline,
      description: apps.description,
      iconUrl: apps.iconUrl,
      status: apps.status,
      downloadCount: apps.downloadCount,
      storeUrlAndroid: apps.storeUrlAndroid,
      storeUrlIos: apps.storeUrlIos,
      nameEn: apps.nameEn,
      taglineEn: apps.taglineEn,
      descriptionEn: apps.descriptionEn,
      // 갤러리용
      thumbUrl: apps.thumbUrl,
      videoUrl: apps.videoUrl,
      category: apps.category,
      featured: apps.featured,
      sort: apps.sort,
    })
    .from(apps)
    .orderBy(asc(apps.sort), asc(apps.id));
  return c.json(ok({ apps: rows }));
});

// 일회성 시드: Exanode(구 CRDL) 이름·스토어 URL·출시 상태 동기화 (출시 직후 실행, 멱등)
appRoutes.post("/crdl/seed-store", async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, "crdl")).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const url = "https://play.google.com/store/apps/details?id=com.betona.crdl";
  await db
    .update(apps)
    .set({ name: "Exanode", storeUrlAndroid: rows[0].storeUrlAndroid || url, status: "released" })
    .where(eq(apps.slug, "crdl"));
  const updated = await db.select().from(apps).where(eq(apps.slug, "crdl")).limit(1);
  return c.json(ok({ app: updated[0] }));
});

appRoutes.get("/:slug", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureColumns(db, "apps", APPS_GALLERY_COLUMNS);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug"))).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const shots = await db
    .select({ id: appScreenshots.id, imageUrl: appScreenshots.imageUrl })
    .from(appScreenshots)
    .where(eq(appScreenshots.appId, rows[0].id))
    .orderBy(asc(appScreenshots.sort));
  // 베타 테스트 빌드 존재 여부 (목록/다운로드는 member 이상)
  const buildCount = await db
    .select({ n: sql<number>`count(*)` })
    .from(appBuilds)
    .where(eq(appBuilds.appId, rows[0].id));
  return c.json(ok({ app: rows[0], screenshots: shots, betaAvailable: buildCount[0].n > 0 }));
});

// ── 베타 테스트 빌드 — 회원(member 이상) 전용 ──
appRoutes.get("/:slug/builds", requireRole("member"), async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug") ?? "")).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const builds = await db
    .select({
      id: appBuilds.id,
      version: appBuilds.version,
      fileSize: appBuilds.fileSize,
      notes: appBuilds.notes,
      downloadCount: appBuilds.downloadCount,
      createdAt: appBuilds.createdAt,
    })
    .from(appBuilds)
    .where(eq(appBuilds.appId, rows[0].id))
    .orderBy(desc(appBuilds.id));
  return c.json(ok({ builds }));
});

// 베타 APK QR — 30분 유효 다운로드 토큰을 담은 QR (회원이 발급, 폰에서 스캔하면 로그인 없이 다운로드)
appRoutes.get("/:slug/builds/:id/qr", requireRole("member"), async (c) => {
  const buildId = Number(c.req.param("id"));
  if (!Number.isInteger(buildId)) return c.json(err("invalid_id"), 400);
  const db = drizzle(c.env.DB);
  const appRows = await db
    .select()
    .from(apps)
    .where(eq(apps.slug, c.req.param("slug") ?? ""))
    .limit(1);
  if (appRows.length === 0) return c.json(err("not_found"), 404);
  const builds = await db
    .select({ id: appBuilds.id })
    .from(appBuilds)
    .where(and(eq(appBuilds.id, buildId), eq(appBuilds.appId, appRows[0].id)))
    .limit(1);
  if (builds.length === 0) return c.json(err("not_found"), 404);

  const token = crypto.randomUUID();
  await c.env.SESSIONS.put(`dlt:${token}`, String(buildId), { expirationTtl: 1800 });
  const url = `${c.env.SITE_URL}/api/apps/${appRows[0].slug}/builds/${buildId}/download?t=${token}`;
  const svg = await QRCode.toString(url, {
    type: "svg",
    errorCorrectionLevel: "M",
    margin: 4, // 다크 배경에서도 스캔되도록 넉넉한 quiet zone
    width: 512,
    color: { dark: "#12141C", light: "#FFFFFF" },
  });
  return c.body(svg, 200, {
    "Content-Type": "image/svg+xml",
    "Cache-Control": "private, no-store", // 토큰이 담기므로 캐시 금지
  });
});

// 다운로드 — 로그인 회원 또는 QR 토큰(?t=) 소지자
appRoutes.get("/:slug/builds/:id/download", async (c) => {
  const buildId = Number(c.req.param("id"));
  if (!Number.isInteger(buildId)) return c.json(err("invalid_id"), 400);

  let authorized = false;
  const t = c.req.query("t");
  if (t && /^[a-f0-9-]{36}$/.test(t)) {
    const v = await c.env.SESSIONS.get(`dlt:${t}`);
    if (v === String(buildId)) authorized = true;
  }
  if (!authorized) {
    const sess = await readSession(c);
    if (sess) authorized = true; // 모든 로그인 역할이 member 이상
  }
  if (!authorized) {
    // 폰 브라우저로 직접 연 경우(만료된 QR 등): 오류 JSON을 파일로 저장하게 두지 말고 앱 페이지로 안내
    if (c.req.header("Sec-Fetch-Mode") === "navigate") {
      return c.redirect(`/apps/${c.req.param("slug") ?? ""}?beta=expired`);
    }
    return c.json(err("unauthorized"), 401);
  }

  const db = drizzle(c.env.DB);
  const appRows = await db
    .select()
    .from(apps)
    .where(eq(apps.slug, c.req.param("slug") ?? ""))
    .limit(1);
  if (appRows.length === 0) return c.json(err("not_found"), 404);
  const builds = await db
    .select()
    .from(appBuilds)
    .where(and(eq(appBuilds.id, buildId), eq(appBuilds.appId, appRows[0].id)))
    .limit(1);
  if (builds.length === 0) return c.json(err("not_found"), 404);

  const obj = await c.env.MEDIA.get(builds[0].fileKey);
  if (!obj) return c.json(err("file_missing"), 404);

  await db
    .update(appBuilds)
    .set({ downloadCount: sql`${appBuilds.downloadCount} + 1` })
    .where(eq(appBuilds.id, buildId));

  const filename = `${appRows[0].slug}-${builds[0].version}.apk`.replace(/[^\w.-]/g, "_");
  return c.body(obj.body, 200, {
    "Content-Type": "application/vnd.android.package-archive",
    "Content-Length": String(builds[0].fileSize),
    "Content-Disposition": `attachment; filename="${filename}"`,
    "Cache-Control": "private, no-store",
  });
});

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

// 스토어 이동 시 다운로드 카운터 +1 — IP+UA 해시 기준 하루 1회 (CLAUDE.md 5-2절)
// 개인정보 보호: IP/UA 원문은 저장하지 않고 해시만 저장 (11절)
appRoutes.post("/:slug/count", async (c) => {
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug"))).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const app = rows[0];

  const ip = c.req.header("CF-Connecting-IP") ?? "0.0.0.0";
  const ua = c.req.header("User-Agent") ?? "unknown";
  const date = new Date().toISOString().slice(0, 10);
  const ipHash = await sha256Hex(`${ip}:exansys`);
  const uaHash = await sha256Hex(`${ua}:exansys`);

  const dup = await db
    .select({ id: downloadLogs.id })
    .from(downloadLogs)
    .where(
      and(
        eq(downloadLogs.appId, app.id),
        eq(downloadLogs.ipHash, ipHash),
        eq(downloadLogs.uaHash, uaHash),
        eq(downloadLogs.date, date),
      ),
    )
    .limit(1);

  let count = app.downloadCount;
  if (dup.length === 0) {
    await db.insert(downloadLogs).values({ appId: app.id, ipHash, uaHash, date });
    count += 1;
    await db.update(apps).set({ downloadCount: count }).where(eq(apps.id, app.id));
  }
  return c.json(ok({ downloadCount: count }));
});

// 스토어 링크 QR 코드 (SVG) — 홍보물용 다운로드 가능 (CLAUDE.md 5-2절)
appRoutes.get("/:slug/qr", async (c) => {
  const platform = c.req.query("platform") === "ios" ? "ios" : "android";
  const db = drizzle(c.env.DB);
  const rows = await db.select().from(apps).where(eq(apps.slug, c.req.param("slug"))).limit(1);
  if (rows.length === 0) return c.json(err("not_found"), 404);
  const url = platform === "ios" ? rows[0].storeUrlIos : rows[0].storeUrlAndroid;
  if (!url) return c.json(err("store_url_not_set"), 404);

  const svg = await QRCode.toString(url, {
    type: "svg",
    errorCorrectionLevel: "M",
    margin: 4, // 다크 배경에서도 스캔되도록 넉넉한 quiet zone
    width: 512,
    color: { dark: "#12141C", light: "#FFFFFF" },
  });
  return c.body(svg, 200, {
    "Content-Type": "image/svg+xml",
    "Cache-Control": "public, max-age=3600",
    "Content-Disposition": `inline; filename="${rows[0].slug}-${platform}-qr.svg"`,
  });
});

// ─────────────────────────────────────────────────────────────
// 일회성 시드 — 출시 완료된 앱을 홈 갤러리(OUR APPS)에 올린다.
// 멱등: 같은 slug 가 있으면 갱신하고, 스크린샷은 지웠다 다시 넣는다.
// 등록이 끝나면 이 라우트는 제거한다 (임시 코드).
// ─────────────────────────────────────────────────────────────
const RELEASED_APPS = [
  {
    slug: "vibequest",
    name: "VibeQuest",
    nameEn: "VibeQuest",
    tagline: "AI·코딩 용어를 3분 퀘스트로. 고양이 비비와 함께 매일 클리어하는 용어 학습 게임",
    taglineEn:
      "Clear AI and coding terms in three-minute quests — a daily vocabulary game with Bibi the cat.",
    description: `AI로 코딩을 시작했는데 용어가 벽처럼 느껴진다면 — VibeQuest가 딱입니다.

하루 3분 퀘스트로 AI·프로그래밍·웹·데이터베이스 용어를 하나씩 내 것으로 만듭니다.

· O/X, 4지선다, 주관식, 글자 조립, 짝 맞추기 — 5가지 문제
· 하트나 생명 제한 없음. 틀려도 계속 배울 수 있습니다
· 틀린 용어는 자동으로 복습 일정에 등록되는 간격 반복 학습
· 867개 용어 사전 — 모든 용어에 "왜 중요한지"와 실제 사용 예시
· 보석·XP·레벨·콤보·연속 학습 스트릭
· 가입 없이, 광고 없이. 학습 기록은 내 기기에만 저장됩니다`,
    descriptionEn: `Started coding with AI but the jargon feels like a wall? VibeQuest is for you.

Three minutes a day turns AI, programming, web and database terms into your own.

· Five question types — true/false, multiple choice, typing, letter assembly, matching
· No hearts, no lives. Get it wrong and keep learning
· Missed terms are scheduled automatically for spaced repetition
· A dictionary of 867 terms, each with why it matters and a real example
· Gems, XP, levels, combos and daily streaks
· No sign-up, no ads. Your progress stays on your device`,
    iconUrl: "/showcase/vibequest/icon_512.webp",
    thumbUrl: "/showcase/vibequest/feature_graphic.webp",
    storeUrlAndroid: "https://play.google.com/store/apps/details?id=net.exansys.vibequest",
    category: "Education",
    featured: true,
    sort: 0,
    shots: [
      "/showcase/vibequest/02_home.webp",
      "/showcase/vibequest/03_quiz.webp",
      "/showcase/vibequest/04_wrong.webp",
      "/showcase/vibequest/07_glossary.webp",
      "/showcase/vibequest/06_result.webp",
      "/showcase/vibequest/01_intro_a.webp",
    ],
  },
  {
    slug: "logchallenge",
    name: "Log Challenge",
    nameEn: "Log Challenge",
    tagline: "좋은 습관을 매일 도장으로 기록하는 챌린지 앱. 사진·타이머·녹음으로 인증합니다",
    taglineEn:
      "Stamp your good habits every day. Verify with a photo, a timer or a recording.",
    description: `습관은 '기록(Log)'으로 남을 때 진짜가 됩니다.

미루면 사라지는 결심을, 마감 전 알림이 놓치지 않게 붙잡아 줍니다.

· 인증 방법 — 사진(날짜·시각 자동 워터마크), 타이머(명상·호흡 가이드), 녹음, 동영상, URL
· 마감 3시간 / 1시간 / 30분 전 알림
· 적립형(매일·주6일)과 결과형(주1회·15일·1회성) 두 가지 챌린지
· 도장이 찍힌 시즌 달력에서 달성률과 최장 연속 확인
· 모든 기록은 기기 내 저장. ZIP 백업과 자동 스냅샷 복구`,
    descriptionEn: `A habit becomes real when it is logged.

Reminders before the deadline catch the resolutions that would otherwise slip away.

· Verify with a photo (auto date and time watermark), a timer with breathing guide, a recording, a video or a URL
· Alerts at three hours, one hour and thirty minutes before the deadline
· Two challenge types — recurring (daily, six days a week) and outcome based (weekly, 15-day, one-off)
· A stamped season calendar shows your completion rate and longest streak
· Everything is stored on your device, with ZIP backup and automatic snapshot recovery`,
    iconUrl: "/showcase/keepup/icon_512.webp",
    thumbUrl: "/showcase/keepup/00_feature_graphic.webp",
    storeUrlAndroid: "https://play.google.com/store/apps/details?id=com.keywordream.keepup",
    category: "Productivity",
    featured: false,
    sort: 1,
    shots: [
      "/showcase/keepup/01_home.webp",
      "/showcase/keepup/02_routines.webp",
      "/showcase/keepup/03_verify.webp",
      "/showcase/keepup/04_calendar.webp",
      "/showcase/keepup/05_alarm.webp",
    ],
  },
];

appRoutes.post("/seed-released", async (c) => {
  const db = drizzle(c.env.DB);
  await ensureColumns(db, "apps", APPS_GALLERY_COLUMNS);
  const result: { slug: string; action: string }[] = [];

  for (const a of RELEASED_APPS) {
    const values = {
      name: a.name,
      nameEn: a.nameEn,
      tagline: a.tagline,
      taglineEn: a.taglineEn,
      description: a.description,
      descriptionEn: a.descriptionEn,
      iconUrl: a.iconUrl,
      thumbUrl: a.thumbUrl,
      storeUrlAndroid: a.storeUrlAndroid,
      status: "released" as const,
      category: a.category,
      featured: a.featured,
      sort: a.sort,
    };
    const found = await db.select({ id: apps.id }).from(apps).where(eq(apps.slug, a.slug)).limit(1);
    let appId: number;
    if (found.length > 0) {
      appId = found[0].id;
      await db.update(apps).set(values).where(eq(apps.id, appId));
      result.push({ slug: a.slug, action: "updated" });
    } else {
      const ins = await db
        .insert(apps)
        .values({ slug: a.slug, ...values, createdAt: new Date() })
        .returning({ id: apps.id });
      appId = ins[0].id;
      result.push({ slug: a.slug, action: "created" });
    }
    // 스크린샷은 매번 새로 맞춘다 (중복 방지)
    await db.delete(appScreenshots).where(eq(appScreenshots.appId, appId));
    for (let i = 0; i < a.shots.length; i++) {
      await db.insert(appScreenshots).values({ appId, imageUrl: a.shots[i], sort: i });
    }
  }

  // 기존 Exanode 는 분류만 채워 갤러리 필터에서 자연스럽게 묶이게 한다
  await db.update(apps).set({ category: "Game", sort: 2 }).where(eq(apps.slug, "crdl"));

  return c.json(ok({ result }));
});

// CLAUDE.md 8절 DB 스키마 (D1/SQLite, Drizzle)
// 실제 D1 데이터베이스 생성과 마이그레이션은 Phase 2에서 수행한다.
import {
  sqliteTable,
  text,
  integer,
  real,
  index,
  uniqueIndex,
} from "drizzle-orm/sqlite-core";

export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  provider: text("provider", {
    enum: ["google", "github", "kakao", "naver", "email"],
  }).notNull(),
  providerId: text("provider_id").notNull(),
  name: text("name").notNull(),
  avatarUrl: text("avatar_url"),
  role: text("role", { enum: ["member", "crew", "staff", "admin"] })
    .notNull()
    .default("member"),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const apps = sqliteTable("apps", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  slug: text("slug").notNull().unique(),
  name: text("name").notNull(),
  tagline: text("tagline"),
  description: text("description"),
  iconUrl: text("icon_url"),
  storeUrlAndroid: text("store_url_android"),
  storeUrlIos: text("store_url_ios"),
  status: text("status", { enum: ["planning", "development", "released"] })
    .notNull()
    .default("planning"),
  downloadCount: integer("download_count").notNull().default(0),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const appScreenshots = sqliteTable("app_screenshots", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  appId: integer("app_id")
    .notNull()
    .references(() => apps.id),
  imageUrl: text("image_url").notNull(),
  sort: integer("sort").notNull().default(0),
});

export const appComments = sqliteTable(
  "app_comments",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    appId: integer("app_id")
      .notNull()
      .references(() => apps.id),
    userId: integer("user_id")
      .notNull()
      .references(() => users.id),
    parentId: integer("parent_id"),
    body: text("body").notNull(),
    createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
    deletedAt: integer("deleted_at", { mode: "timestamp" }),
  },
  (t) => [index("idx_app_comments_app").on(t.appId)],
);

export const inquiries = sqliteTable("inquiries", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  userId: integer("user_id")
    .notNull()
    .references(() => users.id),
  title: text("title").notNull(),
  body: text("body").notNull(),
  contact: text("contact"),
  isPrivate: integer("is_private", { mode: "boolean" }).notNull().default(false),
  status: text("status", { enum: ["open", "answered"] })
    .notNull()
    .default("open"),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const inquiryReplies = sqliteTable("inquiry_replies", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  inquiryId: integer("inquiry_id")
    .notNull()
    .references(() => inquiries.id),
  userId: integer("user_id")
    .notNull()
    .references(() => users.id),
  body: text("body").notNull(),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const privacyPolicies = sqliteTable("privacy_policies", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  appId: integer("app_id")
    .notNull()
    .references(() => apps.id),
  version: integer("version").notNull().default(1),
  bodyMd: text("body_md").notNull(),
  updatedBy: integer("updated_by")
    .notNull()
    .references(() => users.id),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
});

export const galleryPosts = sqliteTable("gallery_posts", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  userId: integer("user_id")
    .notNull()
    .references(() => users.id),
  title: text("title").notNull(),
  body: text("body"),
  linkUrl: text("link_url"),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const galleryImages = sqliteTable("gallery_images", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  postId: integer("post_id")
    .notNull()
    .references(() => galleryPosts.id),
  imageUrl: text("image_url").notNull(),
  sort: integer("sort").notNull().default(0),
});

export const galleryComments = sqliteTable("gallery_comments", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  postId: integer("post_id")
    .notNull()
    .references(() => galleryPosts.id),
  userId: integer("user_id")
    .notNull()
    .references(() => users.id),
  body: text("body").notNull(),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

// 출시 전 테스트용 APK 빌드 (R2 저장, member 이상 다운로드)
export const appBuilds = sqliteTable(
  "app_builds",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    appId: integer("app_id")
      .notNull()
      .references(() => apps.id),
    version: text("version").notNull(),
    fileKey: text("file_key").notNull(), // R2 키 (builds/….apk)
    fileSize: integer("file_size").notNull(),
    notes: text("notes"), // 테스트 안내/변경 사항
    downloadCount: integer("download_count").notNull().default(0),
    createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
  },
  (t) => [index("idx_app_builds_app").on(t.appId)],
);

// 방문자 카운트 — 하루 단위 유니크 방문자 중복 방지 (IP/UA 원문 저장 금지 — 해시만)
export const visitLogs = sqliteTable(
  "visit_logs",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    date: text("date").notNull(), // YYYY-MM-DD (KST), 35일 후 정리
    visitorHash: text("visitor_hash").notNull(),
  },
  (t) => [uniqueIndex("idx_visit_logs_dedupe").on(t.date, t.visitorHash)],
);

// 일별 집계 (로그 정리 후에도 통계는 영구 보존)
export const visitStats = sqliteTable("visit_stats", {
  date: text("date").primaryKey(), // YYYY-MM-DD (KST)
  pageviews: integer("pageviews").notNull().default(0),
  visitors: integer("visitors").notNull().default(0),
});

// App Review 분석 — 외부 스토어(구글플레이/앱스토어)에서 수집한 리뷰 캐시
// 용량 절약을 위해 7일 뒤 자동 정리 (crew 이상만 접근, CLAUDE.md 무료 한도 준수)
export const reviewCaches = sqliteTable(
  "review_caches",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    store: text("store", { enum: ["play", "apple"] }).notNull(),
    appId: text("app_id").notNull(), // play: 패키지명, apple: trackId
    region: text("region").notNull(), // kr, us, jp ...
    title: text("title").notNull(),
    iconUrl: text("icon_url"),
    score: real("score"), // 스토어 평균 별점
    ratings: integer("ratings"), // 총 평가 수
    installs: text("installs"), // 표시용 다운로드 수 (play 전용, 예: "1,000,000+")
    realInstalls: integer("real_installs"), // 추정 실제 설치 수 (play)
    reviewCount: integer("review_count").notNull().default(0), // 수집한 리뷰 개수
    fetchedAt: integer("fetched_at", { mode: "timestamp" }).notNull(),
  },
  (t) => [uniqueIndex("idx_review_caches_key").on(t.store, t.appId, t.region)],
);

export const reviewItems = sqliteTable(
  "review_items",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    cacheId: integer("cache_id")
      .notNull()
      .references(() => reviewCaches.id),
    score: integer("score").notNull().default(0), // 1~5
    content: text("content").notNull(),
    at: integer("at", { mode: "timestamp" }), // 작성일
    thumbsUp: integer("thumbs_up").notNull().default(0),
    userName: text("user_name"),
    version: text("version"), // 앱 버전 (play만 제공)
  },
  (t) => [index("idx_review_items_cache").on(t.cacheId)],
);

// 다운로드 카운터 중복 방지용 (IP/UA는 원문 저장 금지 — 해시만)
export const downloadLogs = sqliteTable(
  "download_logs",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    appId: integer("app_id")
      .notNull()
      .references(() => apps.id),
    ipHash: text("ip_hash").notNull(),
    uaHash: text("ua_hash").notNull(),
    date: text("date").notNull(), // YYYY-MM-DD, 30일 후 정리
  },
  (t) => [index("idx_download_logs_dedupe").on(t.appId, t.ipHash, t.uaHash, t.date)],
);

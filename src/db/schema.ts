// CLAUDE.md 8절 DB 스키마 (D1/SQLite, Drizzle)
// 실제 D1 데이터베이스 생성과 마이그레이션은 Phase 2에서 수행한다.
import {
  sqliteTable,
  text,
  integer,
  index,
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

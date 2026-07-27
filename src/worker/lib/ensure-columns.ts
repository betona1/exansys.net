// 마이그레이션을 수동으로 적용하지 않아도 새 컬럼이 동작하도록 런타임에서 한 번 보정한다.
//
// ALTER TABLE ADD COLUMN 은 이미 있으면 에러가 나므로 PRAGMA 로 먼저 확인한다.
// 컬럼을 더하기만 하고 기존 데이터는 절대 건드리지 않는다.
import { sql } from "drizzle-orm";
import type { drizzle } from "drizzle-orm/d1";

type Db = ReturnType<typeof drizzle>;

/** 아이소레이트당 1회만 돌도록 기억한다 */
const done = new Set<string>();

export async function ensureColumns(
  db: Db,
  table: string,
  columns: { name: string; ddl: string }[],
): Promise<void> {
  if (done.has(table)) return;
  try {
    const info = await db.all<{ name: string }>(sql.raw(`PRAGMA table_info(${table})`));
    const existing = new Set((info ?? []).map((r) => r.name));
    for (const col of columns) {
      if (existing.has(col.name)) continue;
      await db.run(sql.raw(`ALTER TABLE ${table} ADD COLUMN ${col.ddl}`));
    }
    done.add(table);
  } catch {
    // 보정에 실패해도 조회는 계속되어야 한다. 다음 요청에서 다시 시도한다.
  }
}

/** apps 테이블 갤러리 컬럼 (2026 리뉴얼) */
export const APPS_GALLERY_COLUMNS = [
  { name: "name_en", ddl: "name_en text" },
  { name: "tagline_en", ddl: "tagline_en text" },
  { name: "description_en", ddl: "description_en text" },
  { name: "thumb_url", ddl: "thumb_url text" },
  { name: "video_url", ddl: "video_url text" },
  { name: "category", ddl: "category text" },
  { name: "featured", ddl: "featured integer DEFAULT 0 NOT NULL" },
  { name: "sort", ddl: "sort integer DEFAULT 0 NOT NULL" },
];

import { defineConfig } from "drizzle-kit";

// Phase 2에서 D1 생성 후 dbCredentials(accountId/databaseId/token)를 채운다.
// 토큰은 환경변수로만 주입하고 절대 커밋하지 않는다.
export default defineConfig({
  dialect: "sqlite",
  driver: "d1-http",
  schema: "./src/db/schema.ts",
  out: "./drizzle",
});

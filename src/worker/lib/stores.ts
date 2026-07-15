// 외부 앱스토어 데이터 수집 (App Review 분석용)
// - Apple: iTunes 공개 JSON API (검색/조회/RSS 리뷰) — 안정적
// - Google Play: 스토어 내부 엔드포인트 (google-play-scraper 프로토콜 재현) — 형식 변경에 취약하므로 방어적으로 파싱
//
// 모든 호출은 Cloudflare Worker에서 서버사이드로 수행한다.
// (브라우저·Claude 컨테이너에서는 CORS/차단으로 불가능하지만 Worker는 outbound fetch 허용)

export type StoreKind = "play" | "apple";

/** 검색 결과 1건 (순위·평점·다운로드 표시용) */
export interface AppHit {
  store: StoreKind;
  appId: string; // play: 패키지명, apple: trackId
  title: string;
  iconUrl: string | null;
  score: number | null; // 평균 별점
  ratings: number | null; // 총 평가 수
  installs: string | null; // 다운로드 표시 (play만)
  realInstalls: number | null;
  developer: string | null;
  url: string | null; // 스토어 링크
}

/** 앱 상세 (수집 시 함께 저장) */
export interface AppInfo {
  title: string;
  iconUrl: string | null;
  score: number | null;
  ratings: number | null;
  installs: string | null;
  realInstalls: number | null;
}

/** 리뷰 1건 */
export interface ReviewRow {
  score: number;
  content: string;
  at: number | null; // epoch millis
  thumbsUp: number;
  userName: string | null;
  version: string | null;
}

// Apple 스토어프론트 ID (X-Apple-Store-Front 헤더용)
const APPLE_STOREFRONTS: Record<string, string> = {
  kr: "143466",
  us: "143441",
  jp: "143462",
  in: "143467",
  vn: "143471",
  sg: "143464",
  tw: "143470",
  hk: "143463",
  ru: "143469",
  gb: "143444",
  de: "143443",
};

export const SUPPORTED_REGIONS = Object.keys(APPLE_STOREFRONTS);

const UA_BROWSER =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

async function fetchText(url: string, init?: RequestInit, timeoutMs = 12000): Promise<string> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      ...init,
      signal: ctrl.signal,
      headers: { "User-Agent": UA_BROWSER, ...(init?.headers ?? {}) },
      cf: { cacheTtl: 0 },
    } as RequestInit);
    if (!res.ok) throw new Error(`upstream_${res.status}`);
    return await res.text();
  } finally {
    clearTimeout(timer);
  }
}

async function fetchJson<T = unknown>(url: string, init?: RequestInit): Promise<T> {
  const txt = await fetchText(url, init);
  return JSON.parse(txt) as T;
}

// ────────────────────────────────────────────────────────────────
// Apple (App Store) — iTunes 공개 API
// ────────────────────────────────────────────────────────────────

interface ItunesResult {
  trackId?: number;
  trackName?: string;
  artworkUrl100?: string;
  averageUserRating?: number;
  userRatingCount?: number;
  artistName?: string;
  trackViewUrl?: string;
}

export async function appleSearch(term: string, country: string): Promise<AppHit[]> {
  const url =
    "https://itunes.apple.com/search?" +
    new URLSearchParams({ term, country, entity: "software", limit: "20" }).toString();
  const data = await fetchJson<{ results: ItunesResult[] }>(url);
  const hits: AppHit[] = [];
  for (const r of data.results ?? []) {
    if (!r.trackId) continue;
    hits.push({
      store: "apple",
      appId: String(r.trackId),
      title: r.trackName ?? "?",
      iconUrl: r.artworkUrl100 ?? null,
      score: typeof r.averageUserRating === "number" ? r.averageUserRating : null,
      ratings: r.userRatingCount ?? null,
      installs: null, // Apple은 다운로드 수를 공개하지 않음
      realInstalls: null,
      developer: r.artistName ?? null,
      url: r.trackViewUrl ?? null,
    });
  }
  return hits;
}

export async function appleInfo(appId: string, country: string): Promise<AppInfo> {
  const url =
    "https://itunes.apple.com/lookup?" +
    new URLSearchParams({ id: appId, country }).toString();
  const data = await fetchJson<{ results: ItunesResult[] }>(url);
  const r = data.results?.[0];
  return {
    title: r?.trackName ?? appId,
    iconUrl: r?.artworkUrl100 ?? null,
    score: typeof r?.averageUserRating === "number" ? r.averageUserRating : null,
    ratings: r?.userRatingCount ?? null,
    installs: null,
    realInstalls: null,
  };
}

// Apple 리뷰: 공개 RSS (customerreviews) — 페이지당 50건, 최대 10페이지(500건)
interface RssEntry {
  "im:rating"?: { label?: string };
  "im:version"?: { label?: string };
  title?: { label?: string };
  content?: { label?: string };
  author?: { name?: { label?: string } };
  updated?: { label?: string };
  "im:voteSum"?: { label?: string };
}

export async function appleReviews(
  appId: string,
  country: string,
  limit: number,
): Promise<ReviewRow[]> {
  const rows: ReviewRow[] = [];
  const maxPages = Math.min(10, Math.ceil((limit || 500) / 50));
  for (let page = 1; page <= maxPages; page++) {
    const url = `https://itunes.apple.com/${country}/rss/customerreviews/page=${page}/id=${appId}/sortby=mostrecent/json`;
    let data: { feed?: { entry?: RssEntry | RssEntry[] } };
    try {
      // 주의: Apple RSS는 브라우저 UA면 리뷰를 반환하지 않음 → iTunes UA 사용
      data = JSON.parse(
        await fetchText(url, {
          headers: { "User-Agent": "iTunes/12.12 (Windows; Microsoft Windows 10)" },
        }),
      );
    } catch {
      break;
    }
    const entry = data.feed?.entry;
    if (!entry) break;
    // 첫 항목은 앱 메타(별점 없음)일 수 있음 — im:rating 있는 것만
    const list = Array.isArray(entry) ? entry : [entry];
    let added = 0;
    for (const e of list) {
      const rating = e["im:rating"]?.label;
      if (!rating) continue;
      const title = (e.title?.label ?? "").trim();
      const body = (e.content?.label ?? "").trim();
      rows.push({
        score: Number(rating) || 0,
        content: title && title !== body ? `[${title}] ${body}` : body,
        at: e.updated?.label ? Date.parse(e.updated.label) || null : null,
        thumbsUp: Number(e["im:voteSum"]?.label) || 0,
        userName: e.author?.name?.label ?? null,
        version: e["im:version"]?.label ?? null,
      });
      added++;
      if (rows.length >= limit) return rows;
    }
    if (added === 0) break;
  }
  return rows;
}

// ────────────────────────────────────────────────────────────────
// Google Play — 스토어 내부 엔드포인트 (google-play-scraper 프로토콜)
// ────────────────────────────────────────────────────────────────

/** AF_initDataCallback 블록에서 특정 dataset(ds:N)의 JSON 배열을 추출 */
function extractInitData(html: string, key: string): unknown | null {
  // 최신 포맷: AF_initDataCallback({key: 'ds:5', hash: '...', data:[...], sideChannel: {}});
  const marker = `key: '${key}'`;
  const at = html.indexOf(marker);
  if (at === -1) return null;
  const dataAt = html.indexOf("data:", at);
  if (dataAt === -1) return null;
  const start = html.indexOf("[", dataAt);
  if (start === -1) return null;
  // 대괄호 균형을 맞춰 JSON 배열 끝 위치 탐색 (문자열/이스케이프 고려)
  let depth = 0;
  let inStr = false;
  let esc = false;
  for (let i = start; i < html.length; i++) {
    const ch = html[i];
    if (inStr) {
      if (esc) esc = false;
      else if (ch === "\\") esc = true;
      else if (ch === '"') inStr = false;
      continue;
    }
    if (ch === '"') inStr = true;
    else if (ch === "[") depth++;
    else if (ch === "]") {
      depth--;
      if (depth === 0) {
        const slice = html.slice(start, i + 1);
        try {
          return JSON.parse(slice);
        } catch {
          return null;
        }
      }
    }
  }
  return null;
}

/** 문자열 start 위치의 '['부터 균형 잡힌 JSON 배열 끝까지 잘라 반환 */
function sliceBalancedArray(s: string, start: number): string | null {
  if (s[start] !== "[") return null;
  let depth = 0;
  let inStr = false;
  let esc = false;
  for (let i = start; i < s.length; i++) {
    const ch = s[i];
    if (inStr) {
      if (esc) esc = false;
      else if (ch === "\\") esc = true;
      else if (ch === '"') inStr = false;
      continue;
    }
    if (ch === '"') inStr = true;
    else if (ch === "[") depth++;
    else if (ch === "]") {
      depth--;
      if (depth === 0) return s.slice(start, i + 1);
    }
  }
  return null;
}

/** 중첩 배열에서 인덱스 경로로 값 추출 */
function dig(obj: unknown, path: number[]): unknown {
  let cur: unknown = obj;
  for (const p of path) {
    if (!Array.isArray(cur)) return undefined;
    cur = cur[p];
  }
  return cur;
}

function toHttps(u: unknown): string | null {
  if (typeof u !== "string" || !u) return null;
  return u.startsWith("//") ? "https:" + u : u;
}

interface LdJson {
  name?: string;
  image?: string;
  author?: { name?: string };
  aggregateRating?: { ratingValue?: string | number; ratingCount?: string | number };
}

/** 상세 페이지의 application/ld+json (SoftwareApplication) — 평점·평가수·이름·아이콘 (안정적) */
function parseLdJson(html: string): LdJson | null {
  const m = html.match(
    /<script type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/,
  );
  if (!m) return null;
  try {
    return JSON.parse(m[1]) as LdJson;
  } catch {
    return null;
  }
}

/** 앱 상세 페이지에서 정보 추출 — 평점/평가수는 ld+json, 다운로드 수는 ds:5 데이터 */
export async function playInfo(
  appId: string,
  country: string,
  lang: string,
): Promise<AppInfo> {
  const url =
    "https://play.google.com/store/apps/details?" +
    new URLSearchParams({ id: appId, hl: lang, gl: country }).toString();
  const html = await fetchText(url);

  const num = (v: unknown): number | null =>
    typeof v === "number" ? v : v != null && v !== "" && !isNaN(Number(v)) ? Number(v) : null;
  const str = (v: unknown): string | null =>
    typeof v === "string" && v ? v : null;

  const ld = parseLdJson(html);
  const ds = extractInitData(html, "ds:5");

  // 이름·아이콘·평점: ld+json 우선, 없으면 ds:5 / og 메타 폴백
  let title = ld?.name ?? str(dig(ds, [1, 2, 0, 0]));
  let icon = ld?.image ?? toHttps(dig(ds, [1, 2, 95, 0, 3, 2]));
  const score = num(ld?.aggregateRating?.ratingValue) ?? num(dig(ds, [1, 2, 51, 0, 1]));
  const ratings = num(ld?.aggregateRating?.ratingCount) ?? num(dig(ds, [1, 2, 51, 2, 1]));

  // 다운로드 수: ds:5 (표시용 문자열 + 추정 실제 설치 수)
  const installs = str(dig(ds, [1, 2, 13, 0]));
  const realInstalls = num(dig(ds, [1, 2, 13, 2]));

  if (!title) {
    const m = html.match(/<meta property="og:title" content="([^"]+)"/);
    if (m) title = m[1].replace(/ - (Apps on Google Play|Google Play 앱)$/, "");
  }
  if (!icon) {
    const m = html.match(/<meta property="og:image" content="([^"]+)"/);
    if (m) icon = m[1];
  }

  return { title: title ?? appId, iconUrl: icon, score, ratings, installs, realInstalls };
}

/** 검색: 결과 페이지 HTML에서 순서대로 패키지 ID 추출 → 상세로 정보 보강 */
export async function playSearch(
  term: string,
  country: string,
  lang: string,
): Promise<AppHit[]> {
  const url =
    "https://play.google.com/store/search?" +
    new URLSearchParams({ q: term, c: "apps", hl: lang, gl: country }).toString();
  const html = await fetchText(url);
  const ids: string[] = [];
  const re = /\/store\/apps\/details\?id=([\w.]+)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) && ids.length < 12) {
    if (!ids.includes(m[1])) ids.push(m[1]);
  }
  if (ids.length === 0) return [];

  // 상위 후보만 상세 조회 (무료 subrequest 한도·CPU 절약) — 병렬
  const top = ids.slice(0, 8);
  const infos = await Promise.allSettled(top.map((id) => playInfo(id, country, lang)));
  const hits: AppHit[] = [];
  top.forEach((id, i) => {
    const r = infos[i];
    const info = r.status === "fulfilled" ? r.value : null;
    hits.push({
      store: "play",
      appId: id,
      title: info?.title ?? id,
      iconUrl: info?.iconUrl ?? null,
      score: info?.score ?? null,
      ratings: info?.ratings ?? null,
      installs: info?.installs ?? null,
      realInstalls: info?.realInstalls ?? null,
      developer: null,
      url: `https://play.google.com/store/apps/details?id=${id}`,
    });
  });
  return hits;
}

/** 리뷰 수집: PlayStoreUi batchexecute (rpcid UsvDTd), 페이지네이션 */
export async function playReviews(
  appId: string,
  country: string,
  lang: string,
  limit: number,
): Promise<ReviewRow[]> {
  const rows: ReviewRow[] = [];
  let token: string | null = null;
  const PAGE = 150;
  // 무료 subrequest 한도 보호: 최대 12페이지
  for (let iter = 0; iter < 12; iter++) {
    const want = Math.min(PAGE, limit - rows.length);
    if (want <= 0) break;
    // 내부 파라미터: [null,null,[정렬(2=최신),별점,[개수,null,토큰],null,[]],[appId,7]]
    const inner = JSON.stringify([
      null,
      null,
      [2, null, [want, null, token], null, []],
      [appId, 7],
    ]);
    const freq = JSON.stringify([[["UsvDTd", inner, null, "generic"]]]);
    const url =
      "https://play.google.com/_/PlayStoreUi/data/batchexecute?" +
      new URLSearchParams({
        rpcids: "UsvDTd",
        "source-path": "/store/apps/details",
        hl: lang,
        gl: country,
        "f.sid": "-1",
        bl: "boq_playuiserver",
        authuser: "0",
        "_reqid": String(1000 + iter),
        rt: "c",
      }).toString();

    let text: string;
    try {
      text = await fetchText(
        url,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          },
          body: "f.req=" + encodeURIComponent(freq),
        },
        15000,
      );
    } catch {
      break;
    }

    const parsed = parseBatchExecute(text);
    if (!parsed) break;
    const reviewsArr = parsed.reviews;
    if (!reviewsArr || reviewsArr.length === 0) break;

    for (const r of reviewsArr) {
      const c4 = dig(r, [4]);
      const content = typeof c4 === "string" ? c4 : "";
      const dateSec = dig(r, [5, 0]);
      rows.push({
        score: Number(dig(r, [2])) || 0,
        content,
        at: typeof dateSec === "number" ? dateSec * 1000 : null,
        thumbsUp: Number(dig(r, [6])) || 0,
        userName: (dig(r, [1, 0]) as string) ?? null,
        version: (dig(r, [10]) as string) ?? null,
      });
      if (rows.length >= limit) return rows;
    }

    token = parsed.token;
    if (!token) break;
  }
  return rows;
}

interface BatchParsed {
  reviews: unknown[];
  token: string | null;
}

function parseBatchExecute(text: string): BatchParsed | null {
  // 응답: )]}'\n\n<길이>\n[[...]]\n<길이>\n[...] — 청크 스트림이므로 첫 배열만 균형 파싱
  try {
    const idx = text.indexOf("[");
    if (idx === -1) return null;
    const arr = sliceBalancedArray(text, idx);
    if (!arr) return null;
    const envelope = JSON.parse(arr) as unknown[];
    // envelope: [["wrb.fr","UsvDTd","<json문자열>",...], ...]
    let payload: string | null = null;
    for (const row of envelope) {
      if (Array.isArray(row) && row[0] === "wrb.fr" && row[1] === "UsvDTd") {
        payload = typeof row[2] === "string" ? row[2] : null;
        break;
      }
    }
    if (!payload) return null;
    const data = JSON.parse(payload) as unknown[];
    const reviews = Array.isArray(data?.[0]) ? (data[0] as unknown[]) : [];
    // 다음 토큰: data[1][1]
    const tok = dig(data, [1, 1]);
    return { reviews, token: typeof tok === "string" ? tok : null };
  } catch {
    return null;
  }
}

// ────────────────────────────────────────────────────────────────
// 공용 파사드
// ────────────────────────────────────────────────────────────────

// Play hl(언어)은 국가 코드와 다름 — 주요 지역만 매핑, 나머지는 영어
const PLAY_LANG: Record<string, string> = {
  kr: "ko",
  jp: "ja",
  us: "en",
  gb: "en",
  de: "de",
  vn: "vi",
  tw: "zh-TW",
  hk: "zh-HK",
  ru: "ru",
  in: "en",
  sg: "en",
};
const langFor = (region: string) => PLAY_LANG[region] ?? "en";

export function searchApps(store: StoreKind, term: string, region: string): Promise<AppHit[]> {
  return store === "apple" ? appleSearch(term, region) : playSearch(term, region, langFor(region));
}

export function fetchAppInfo(store: StoreKind, appId: string, region: string): Promise<AppInfo> {
  return store === "apple" ? appleInfo(appId, region) : playInfo(appId, region, langFor(region));
}

export function fetchReviews(
  store: StoreKind,
  appId: string,
  region: string,
  limit: number,
): Promise<ReviewRow[]> {
  return store === "apple"
    ? appleReviews(appId, region, limit)
    : playReviews(appId, region, langFor(region), limit);
}

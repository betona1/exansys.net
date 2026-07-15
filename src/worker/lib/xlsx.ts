// 무의존 XLSX 생성기 — 외부 라이브러리 없이 다중 시트 엑셀 파일(.xlsx) 생성
// ZIP(STORE, 무압축) + 최소 SpreadsheetML. Cloudflare Worker에서 동작.
// 숫자는 <v>, 문자열은 inlineStr 로 기록한다.

export type Cell = string | number | null | undefined;
export interface Sheet {
  name: string;
  rows: Cell[][];
}

const enc = new TextEncoder();

// ── CRC32 ──
const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf: Uint8Array): number {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function xmlEscape(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// 제어문자 제거 (XLSX 허용 안 됨)
function clean(s: string): string {
  return s.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f]/g, "");
}

function colRef(idx: number): string {
  let s = "";
  let n = idx;
  do {
    s = String.fromCharCode(65 + (n % 26)) + s;
    n = Math.floor(n / 26) - 1;
  } while (n >= 0);
  return s;
}

function sheetXml(sheet: Sheet): string {
  let body = "";
  sheet.rows.forEach((row, r) => {
    const rowNum = r + 1;
    let cells = "";
    row.forEach((cell, c) => {
      if (cell === null || cell === undefined || cell === "") return;
      const ref = `${colRef(c)}${rowNum}`;
      if (typeof cell === "number" && isFinite(cell)) {
        cells += `<c r="${ref}"><v>${cell}</v></c>`;
      } else {
        const txt = xmlEscape(clean(String(cell)));
        cells += `<c r="${ref}" t="inlineStr"><is><t xml:space="preserve">${txt}</t></is></c>`;
      }
    });
    body += `<row r="${rowNum}">${cells}</row>`;
  });
  return (
    `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
    `<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">` +
    `<sheetData>${body}</sheetData></worksheet>`
  );
}

function buildParts(sheets: Sheet[]): { path: string; data: Uint8Array }[] {
  const parts: { path: string; content: string }[] = [];

  const sheetOverrides = sheets
    .map(
      (_, i) =>
        `<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`,
    )
    .join("");
  parts.push({
    path: "[Content_Types].xml",
    content:
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
      `<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">` +
      `<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>` +
      `<Default Extension="xml" ContentType="application/xml"/>` +
      `<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>` +
      sheetOverrides +
      `</Types>`,
  });

  parts.push({
    path: "_rels/.rels",
    content:
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
      `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
      `<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>` +
      `</Relationships>`,
  });

  const sheetTags = sheets
    .map(
      (s, i) =>
        `<sheet name="${xmlEscape(clean(s.name)).slice(0, 31)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>`,
    )
    .join("");
  parts.push({
    path: "xl/workbook.xml",
    content:
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
      `<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ` +
      `xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">` +
      `<sheets>${sheetTags}</sheets></workbook>`,
  });

  const relTags = sheets
    .map(
      (_, i) =>
        `<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>`,
    )
    .join("");
  parts.push({
    path: "xl/_rels/workbook.xml.rels",
    content:
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
      `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
      relTags +
      `</Relationships>`,
  });

  sheets.forEach((s, i) => {
    parts.push({ path: `xl/worksheets/sheet${i + 1}.xml`, content: sheetXml(s) });
  });

  return parts.map((p) => ({ path: p.path, data: enc.encode(p.content) }));
}

function u16(n: number): number[] {
  return [n & 0xff, (n >>> 8) & 0xff];
}
function u32(n: number): number[] {
  return [n & 0xff, (n >>> 8) & 0xff, (n >>> 16) & 0xff, (n >>> 24) & 0xff];
}

/** 시트 배열을 .xlsx(Uint8Array)로 생성 */
export function buildXlsx(sheets: Sheet[]): Uint8Array {
  const files = buildParts(sheets);
  const segments: Uint8Array[] = []; // 로컬 헤더 + 데이터 (파일 본문)
  const centrals: Uint8Array[] = []; // 중앙 디렉터리 레코드
  let offset = 0;
  let centralSize = 0;

  for (const f of files) {
    const nameBytes = enc.encode(f.path);
    const crc = crc32(f.data);
    const size = f.data.length;

    const local = Uint8Array.from([
      ...u32(0x04034b50),
      ...u16(20),
      ...u16(0),
      ...u16(0), // method = store
      ...u16(0),
      ...u16(0),
      ...u32(crc),
      ...u32(size),
      ...u32(size),
      ...u16(nameBytes.length),
      ...u16(0),
    ]);
    segments.push(local, nameBytes, f.data);

    const central = Uint8Array.from([
      ...u32(0x02014b50),
      ...u16(20),
      ...u16(20),
      ...u16(0),
      ...u16(0),
      ...u16(0),
      ...u16(0),
      ...u32(crc),
      ...u32(size),
      ...u32(size),
      ...u16(nameBytes.length),
      ...u16(0),
      ...u16(0),
      ...u16(0),
      ...u16(0),
      ...u32(0),
      ...u32(offset),
      ...Array.from(nameBytes),
    ]);
    centrals.push(central);
    centralSize += central.length;

    offset += local.length + nameBytes.length + size;
  }

  const eocd = Uint8Array.from([
    ...u32(0x06054b50),
    ...u16(0),
    ...u16(0),
    ...u16(files.length),
    ...u16(files.length),
    ...u32(centralSize),
    ...u32(offset),
    ...u16(0),
  ]);

  const all = [...segments, ...centrals, eocd];
  const totalLen = all.reduce((n, s) => n + s.length, 0);
  const out = new Uint8Array(totalLen);
  let pos = 0;
  for (const s of all) {
    out.set(s, pos);
    pos += s.length;
  }
  return out;
}

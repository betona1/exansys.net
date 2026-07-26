// 앱기획 AI 구조화 — 브라우저에서 Anthropic API 를 직접 호출한다.
//
// 왜 서버를 안 거치는가:
//  Cloudflare Worker 에서 나가는 요청을 Anthropic 이 403 "Request not allowed" 로
//  막는다(이 저장소의 앱리뷰도 같은 이유로 애플 스토어 서버 수집을 못 한다).
//  브라우저 직접 호출은 anthropic-dangerous-direct-browser-access 헤더로 공식 지원된다.
//
// 부수 효과로 사용자의 API 키가 서버로 전송되지 않는다. 키는 이 브라우저를 벗어나지 않는다.
// 프롬프트는 서버가 만들어 주므로(무엇을 물을지는 서버가 단일 관리) 화면에는 규칙이 흩어지지 않는다.

const MESSAGES_URL = "https://api.anthropic.com/v1/messages";
const MODELS_URL = "https://api.anthropic.com/v1/models?limit=100";
const ANTHROPIC_VERSION = "2023-06-01";

const MODEL_PREFERENCE = [
  "claude-opus-5",
  "claude-sonnet-5",
  "claude-opus-4-8",
  "claude-sonnet-4-6",
  "claude-haiku-4-5",
];

function headers(apiKey: string): Record<string, string> {
  return {
    "content-type": "application/json",
    "anthropic-version": ANTHROPIC_VERSION,
    "anthropic-dangerous-direct-browser-access": "true",
    "x-api-key": apiKey,
  };
}

export type DirectResult<T> = { ok: true; data: T } | { ok: false; error: string };

async function reasonOf(res: Response): Promise<string> {
  try {
    const body = (await res.json()) as { error?: { message?: string } };
    return (body.error?.message ?? "").slice(0, 300);
  } catch {
    return "";
  }
}

/** 모델을 바꾸면 통할 수 있는 실패인가 (권한 없음 / 없는 모델 / 미지원 파라미터) */
function shouldTryNextModel(status: number, reason: string): boolean {
  if (status === 403 || status === 404) return true;
  if (status !== 400) return false;
  return /thinking|output_config|effort|model|not permitted|not support/i.test(reason);
}

/** 코드펜스나 앞뒤 설명이 섞여 와도 JSON 본문만 뽑아낸다 */
function extractJson(text: string): Record<string, unknown> | null {
  const cleaned = text.replace(/```(?:json)?/gi, "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start === -1 || end <= start) return null;
  try {
    return JSON.parse(cleaned.slice(start, end + 1)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** 이 키로 시도해 볼 모델을 선호 순서대로 만든다. */
async function candidateModels(apiKey: string): Promise<DirectResult<string[]>> {
  let res: Response;
  try {
    res = await fetch(MODELS_URL, { headers: headers(apiKey) });
  } catch {
    return { ok: false, error: "브라우저에서 Anthropic 에 연결하지 못했습니다(네트워크·확장프로그램 차단)." };
  }
  if (!res.ok) {
    const reason = await reasonOf(res);
    return {
      ok: false,
      error: `모델 목록 조회 실패 — [HTTP ${res.status}] ${reason || "사유 없음"}`,
    };
  }
  const body = (await res.json()) as { data?: { id: string }[] };
  const available = (body.data ?? []).map((m) => m.id).filter((id) => id.startsWith("claude"));
  const models = [...new Set([...MODEL_PREFERENCE.filter((m) => available.includes(m)), ...available])];
  if (models.length === 0) return { ok: false, error: "이 키로 쓸 수 있는 모델이 없습니다." };
  return { ok: true, data: models };
}

/** 키 점검 — 토큰 몇 개짜리 최소 요청으로 실제 호출까지 확인한다. */
export async function checkKeyDirect(apiKey: string): Promise<DirectResult<{ model: string }>> {
  const candidates = await candidateModels(apiKey);
  if (!candidates.ok) return candidates;

  let lastError = "";
  for (const model of candidates.data.slice(0, 5)) {
    let res: Response;
    try {
      res = await fetch(MESSAGES_URL, {
        method: "POST",
        headers: headers(apiKey),
        body: JSON.stringify({
          model,
          max_tokens: 8,
          messages: [{ role: "user", content: "OK 라고만 답하십시오." }],
        }),
      });
    } catch {
      return { ok: false, error: "브라우저에서 Anthropic 에 연결하지 못했습니다." };
    }
    if (res.ok) return { ok: true, data: { model } };
    const reason = await reasonOf(res);
    lastError = `[HTTP ${res.status}] ${reason || "사유 없음"}`;
    if (!shouldTryNextModel(res.status, reason)) break;
  }
  return { ok: false, error: `모델 목록은 조회됐지만 실제 호출이 모두 거부됨 — ${lastError}` };
}

/** 구조화 초안 생성 — 프롬프트는 서버가 만든 것을 그대로 쓴다. */
export async function structureDirect(
  apiKey: string,
  system: string,
  userMessage: string,
): Promise<DirectResult<{ model: string; draft: Record<string, unknown> }>> {
  const candidates = await candidateModels(apiKey);
  if (!candidates.ok) return candidates;

  let lastError = "";
  for (const model of candidates.data.slice(0, 5)) {
    let res: Response;
    try {
      res = await fetch(MESSAGES_URL, {
        method: "POST",
        headers: headers(apiKey),
        // thinking·output_config 는 신형 모델 전용이라 보내지 않는다.
        // 출력 형식은 프롬프트로 지시하고 응답에서 JSON 만 뽑아낸다.
        body: JSON.stringify({
          model,
          max_tokens: 8000,
          system,
          messages: [{ role: "user", content: userMessage }],
        }),
      });
    } catch {
      return { ok: false, error: "브라우저에서 Anthropic 에 연결하지 못했습니다." };
    }

    if (!res.ok) {
      const reason = await reasonOf(res);
      lastError = `[HTTP ${res.status}] ${reason || "사유 없음"}`;
      if (shouldTryNextModel(res.status, reason)) continue;
      return { ok: false, error: lastError };
    }

    const body = (await res.json()) as {
      content?: { type: string; text?: string }[];
      stop_reason?: string | null;
    };
    // 안전 분류기가 거절하면 HTTP 200 + stop_reason:"refusal" 로 온다.
    if (body.stop_reason === "refusal") {
      return { ok: false, error: "AI가 이 내용의 처리를 거절했습니다. 원문을 확인해 주세요." };
    }
    const text = body.content?.find((b) => b.type === "text")?.text ?? "";
    const draft = extractJson(text);
    if (!draft) {
      lastError =
        body.stop_reason === "max_tokens"
          ? "응답이 잘렸습니다(원문이 너무 깁니다)"
          : "JSON 형식이 아닌 응답";
      continue;
    }
    return { ok: true, data: { model, draft } };
  }
  return { ok: false, error: lastError || "초안을 만들지 못했습니다." };
}

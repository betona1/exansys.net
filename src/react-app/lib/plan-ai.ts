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

// 백만 토큰당 단가(USD). 사용량 표시에만 쓰며 청구는 Anthropic 이 한다.
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  "claude-fable-5": { input: 10, output: 50 },
  "claude-opus-5": { input: 5, output: 25 },
  "claude-opus-4-8": { input: 5, output: 25 },
  "claude-opus-4-7": { input: 5, output: 25 },
  "claude-opus-4-6": { input: 5, output: 25 },
  "claude-sonnet-5": { input: 3, output: 15 },
  "claude-sonnet-4-6": { input: 3, output: 15 },
  "claude-haiku-4-5": { input: 1, output: 5 },
};

/** adaptive thinking·effort 를 받아주는 모델. 구형에 보내면 400 이 난다. */
const THINKING_MODELS = new Set([
  "claude-fable-5",
  "claude-opus-5",
  "claude-opus-4-8",
  "claude-opus-4-7",
  "claude-opus-4-6",
  "claude-sonnet-5",
  "claude-sonnet-4-6",
]);

export type AiUsage = {
  model: string;
  inputTokens: number;
  outputTokens: number;
  /** 추정 비용(USD). 단가표에 없는 모델이면 null */
  costUsd: number | null;
  thinking: boolean;
};

function estimateCost(model: string, input: number, output: number): number | null {
  const p = MODEL_PRICING[model];
  if (!p) return null;
  return (input / 1_000_000) * p.input + (output / 1_000_000) * p.output;
}

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

/** 구조화 초안 생성.
 *
 * 신형 모델에는 adaptive thinking 과 높은 effort 를 준다. 원문에서 무엇을 어느 칸으로
 * 옮길지 판단하는 작업이라 사고를 켜면 결과 품질이 확연히 달라진다. 구형 모델은 이
 * 파라미터를 거부(400)하므로 같은 모델로 파라미터 없이 한 번 더 시도한다.
 */
export async function structureDirect(
  apiKey: string,
  system: string,
  userMessage: string,
  onProgress?: (stage: string) => void,
): Promise<DirectResult<{ model: string; draft: Record<string, unknown>; usage: AiUsage }>> {
  onProgress?.("쓸 수 있는 모델 확인 중…");
  const candidates = await candidateModels(apiKey);
  if (!candidates.ok) return candidates;

  let lastError = "";
  for (const model of candidates.data.slice(0, 5)) {
    // 신형 모델이면 사고를 켜고 한 번, 거부당하면 끄고 한 번
    const attempts = THINKING_MODELS.has(model) ? [true, false] : [false];

    for (const withThinking of attempts) {
      onProgress?.(
        withThinking
          ? `${model} 로 생각하며 작성 중… (30초쯤 걸립니다)`
          : `${model} 로 작성 중…`,
      );

      const payload: Record<string, unknown> = {
        model,
        max_tokens: withThinking ? 16000 : 8000,
        system,
        messages: [{ role: "user", content: userMessage }],
      };
      if (withThinking) {
        payload.thinking = { type: "adaptive" };
        payload.output_config = { effort: "high" };
      }

      let res: Response;
      try {
        res = await fetch(MESSAGES_URL, {
          method: "POST",
          headers: headers(apiKey),
          body: JSON.stringify(payload),
        });
      } catch {
        return { ok: false, error: "브라우저에서 Anthropic 에 연결하지 못했습니다." };
      }

      if (!res.ok) {
        const reason = await reasonOf(res);
        lastError = `[HTTP ${res.status}] ${reason || "사유 없음"}`;
        // 사고 파라미터를 거부한 것이면 같은 모델로 끄고 재시도(다음 attempts 항목)
        if (withThinking && res.status === 400) continue;
        if (shouldTryNextModel(res.status, reason)) break; // 다음 모델로
        return { ok: false, error: lastError };
      }

      const body = (await res.json()) as {
        content?: { type: string; text?: string }[];
        stop_reason?: string | null;
        usage?: { input_tokens?: number; output_tokens?: number };
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

      const inputTokens = body.usage?.input_tokens ?? 0;
      const outputTokens = body.usage?.output_tokens ?? 0;
      return {
        ok: true,
        data: {
          model,
          draft,
          usage: {
            model,
            inputTokens,
            outputTokens,
            costUsd: estimateCost(model, inputTokens, outputTokens),
            thinking: withThinking,
          },
        },
      };
    }
  }
  return { ok: false, error: lastError || "초안을 만들지 못했습니다." };
}

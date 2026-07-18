# TechDex 용어 카테고리 체계 (v1)

시드 소스(바이브코딩/AI 에이전트 용어)에서 도출한 9개 카테고리.
새 소스(RAG·파인튜닝·프로덕션 등)를 추가하면 카테고리를 확장한다.

| key | 한글 라벨 | 설명 | 예시 |
|---|---|---|---|
| `core` | 핵심 개념 | AI·모델·토큰 등 가장 기본이 되는 개념 | AI, Agent, Model, Token, Inference |
| `context` | 컨텍스트·메모리 | 모델이 보는 정보와 그 관리(주의력·압축·리셋) | Context window, Compaction, Attention budget |
| `harness` | 하네스·도구 | 모델을 에이전트로 만드는 도구·프로토콜·환경 | Harness, Tool, MCP, System prompt, Skill |
| `session` | 세션·핸드오프 | 작업 단위(세션)와 세션 간 정보 전달 | Session, Handoff, Spec, Ticket, Turn |
| `workflow` | 작업 방식 | 사람과 에이전트가 협업하는 패턴 | AFK, Vibe coding, Human review, Grilling |
| `permission` | 권한·안전 | 도구 실행 권한과 격리 | Agent mode, Permission mode, Sandbox |
| `cost` | 비용·토큰경제 | 토큰 비용·캐시·추론량 | Input/Output tokens, Cache tokens, Effort |
| `quality` | 품질·리스크 | 잘못된 출력의 양상 | Hallucination, Sycophancy |
| `experience` | 개발/에이전트 경험 | DX·AX | DX, AX |

## 난이도(difficulty) 기준
- 1 입문: 처음 들어도 바로 이해 가능한 기본 어휘 (Token, Model, AI)
- 2 초급: 자주 쓰는 실무 개념 (Context window, Session, Tool)
- 3 중급: 메커니즘 이해 필요 (Attention budget, Compaction, MCP)
- 4 고급: 미묘한 구분/설계 개념 (Attention relationship, Progressive disclosure)

## is_vibe_core
"바이브코딩을 시작할 때 꼭 알아야 할 필수 용어" 플래그. 온보딩 코스("필수 20선")의 소스.

## 출처(라이선스)
- 시드 v1 소스: `mattpocock/dictionary-of-ai-coding` (GitHub). LICENSE 파일 없음 → **정의문 복제 금지**.
  용어명·의미만 참고하고 **한글 정의는 새로 작성**했다. 각 용어에 `source` 필드로 출처를 기록한다.

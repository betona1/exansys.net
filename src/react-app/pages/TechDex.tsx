// TechDex — IT/AI 용어 학습 게임 (스피드 퀴즈 + 도감)
// 홈페이지 용어집 + 바이브코딩 용어(367개)를 D1에서 받아 게임으로 학습. 누구나 플레이.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  api,
  type Me,
  type TechdexCollection,
  type TechdexQuizQuestion,
  type TechdexTerm,
  type TechdexStats,
  type TechdexSuggestion,
  TECHDEX_COLLECTION_LABEL,
} from "../lib/api";
import { isMuted, setMuted, unlockAudio, sfxCorrect, sfxWrong, sfxTick, sfxUrgent } from "../lib/sfx";

const COLL_BADGE: Record<TechdexCollection, string> = {
  ai: "bg-green/10 text-green-deep",
  app: "bg-cobalt/10 text-cobalt",
  vibe: "bg-amber-100 text-amber-700",
  user: "bg-lime/30 text-green-deep",
};

type Level = "beginner" | "intermediate" | "hard";
const LEVELS: Record<Level, { label: string; hint: string; seconds: number }> = {
  beginner: { label: "초급", hint: "쉬운 용어 · 18초", seconds: 18 },
  intermediate: { label: "중급", hint: "표준 · 12초", seconds: 12 },
  hard: { label: "고급", hint: "어려운 용어 · 8초", seconds: 8 },
};

type Scope = { collection: TechdexCollection | "all"; vibeCore: boolean; count: number; level: Level };

export default function TechDex({ me }: { me: Me }) {
  const isAdmin = me?.role === "admin";
  const [tab, setTab] = useState<"quiz" | "dex" | "review">(() =>
    new URLSearchParams(window.location.search).get("tab") === "dex" ? "dex" : "quiz",
  );
  const [stats, setStats] = useState<TechdexStats | null>(null);
  const [pending, setPending] = useState(0);

  useEffect(() => {
    api<TechdexStats>("/api/techdex/stats").then((r) => r.ok && setStats(r.data));
  }, []);
  useEffect(() => {
    if (isAdmin) api<{ pending: number }>("/api/techdex/suggestions/count").then((r) => r.ok && setPending(r.data.pending));
  }, [isAdmin]);

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      <header className="mb-6">
        <div className="flex items-center gap-3.5">
          <img
            src="/techdex-logo.png"
            alt="TechDex"
            className="h-14 w-14 shrink-0 rounded-2xl shadow-lg shadow-green/25"
          />
          <div className="min-w-0">
            <div className="text-[11px] font-bold uppercase tracking-[0.18em] text-green">
              EXANSYS · 용어 학습 게임
            </div>
            <h1 className="font-display text-3xl font-extrabold leading-none tracking-tight">TechDex</h1>
            {stats && (
              <p className="mt-1 text-sm font-semibold text-muted">
                <b className="text-green-deep">{stats.total.toLocaleString()}</b>개 용어 · 필수 {stats.vibeCore}개
              </p>
            )}
          </div>
        </div>
      </header>

      <div className="mb-6 inline-flex flex-wrap rounded-full border border-line bg-card p-1 text-sm font-semibold">
        {(
          [
            ["quiz", "🎯 스피드 퀴즈"],
            ["dex", "📖 용어 도감"],
            ...(isAdmin ? [["review", `🔎 제안 관리${pending ? ` (${pending})` : ""}`] as const] : []),
          ] as const
        ).map(([k, label]) => (
          <button
            key={k}
            onClick={() => setTab(k)}
            className={`rounded-full px-4 py-1.5 transition ${
              tab === k ? "bg-ink text-white" : "text-muted hover:text-ink"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === "quiz" && <Quiz stats={stats} />}
      {tab === "dex" && <Dex me={me} />}
      {tab === "review" && isAdmin && <Review onResolved={() => setPending((n) => Math.max(0, n - 1))} />}
    </main>
  );
}

// ────────────────────────── 스피드 퀴즈 ──────────────────────────
function Quiz({ stats }: { stats: TechdexStats | null }) {
  const [phase, setPhase] = useState<"setup" | "loading" | "playing" | "result">("setup");
  const [scope, setScope] = useState<Scope>({ collection: "all", vibeCore: false, count: 10, level: "intermediate" });
  const [muted, setMutedState] = useState(isMuted());
  const QSEC = LEVELS[scope.level].seconds;
  const [questions, setQuestions] = useState<TechdexQuizQuestion[]>([]);
  const [idx, setIdx] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [answered, setAnswered] = useState(false);
  const [score, setScore] = useState(0);
  const [combo, setCombo] = useState(0);
  const [bestCombo, setBestCombo] = useState(0);
  const [correctCount, setCorrectCount] = useState(0);
  const [wrongList, setWrongList] = useState<TechdexQuizQuestion[]>([]);
  const [timeLeft, setTimeLeft] = useState(12);
  const [error, setError] = useState("");

  const start = useCallback(async () => {
    setPhase("loading");
    setError("");
    unlockAudio(); // 사용자 제스처에서 오디오 활성화
    const params = new URLSearchParams({ count: String(scope.count), level: scope.level });
    if (scope.collection !== "all") params.set("collection", scope.collection);
    if (scope.vibeCore) params.set("vibeCore", "1");
    const r = await api<{ count: number; questions: TechdexQuizQuestion[] }>(`/api/techdex/quiz?${params}`);
    if (!r.ok || r.data.questions.length === 0) {
      setError("문제를 불러오지 못했습니다. 범위를 바꿔 다시 시도해 주세요.");
      setPhase("setup");
      return;
    }
    setQuestions(r.data.questions);
    setIdx(0);
    setSelected(null);
    setAnswered(false);
    setScore(0);
    setCombo(0);
    setBestCombo(0);
    setCorrectCount(0);
    setWrongList([]);
    setTimeLeft(QSEC);
    setPhase("playing");
  }, [scope, QSEC]);

  const advanceRef = useRef<number | null>(null);

  const advance = useCallback(() => {
    if (idx + 1 < questions.length) {
      setIdx((n) => n + 1);
      setSelected(null);
      setAnswered(false);
      setTimeLeft(QSEC);
    } else {
      setPhase("result");
    }
  }, [idx, questions.length, QSEC]);

  const choose = useCallback(
    (i: number | null) => {
      if (answered || phase !== "playing") return;
      const q = questions[idx];
      const isCorrect = i !== null && i === q.answerIndex;
      setSelected(i);
      setAnswered(true);
      if (isCorrect) {
        sfxCorrect();
        const bonus = 10 + Math.round(timeLeft) * 5 + combo * 3;
        setScore((s) => s + bonus);
        setCombo((cmb) => {
          const nc = cmb + 1;
          setBestCombo((b) => Math.max(b, nc));
          return nc;
        });
        setCorrectCount((n) => n + 1);
      } else {
        sfxWrong();
        setCombo(0);
        setWrongList((w) => [...w, q]);
      }
      // 정답/오답 표시 후 자동으로 다음 문제로 (정답은 빠르게, 오답은 정답 확인할 시간 여유)
      advanceRef.current = window.setTimeout(advance, isCorrect ? 1100 : 2200);
    },
    [answered, phase, questions, idx, timeLeft, combo, advance],
  );

  // 언마운트 시 예약된 자동 넘김 정리
  useEffect(() => () => void (advanceRef.current && clearTimeout(advanceRef.current)), []);

  // 문제별 타이머 (째깍 사운드 포함)
  useEffect(() => {
    if (phase !== "playing" || answered) return;
    const t = window.setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 0.1) {
          window.clearInterval(t);
          choose(null); // 시간 초과 = 오답
          return 0;
        }
        const nextVal = prev - 0.1;
        // 정수 초를 넘길 때마다 '째깍' (막판 3초는 경고음)
        if (Math.floor(prev) !== Math.floor(nextVal)) {
          if (nextVal <= 3.4) sfxUrgent();
          else sfxTick();
        }
        return nextVal;
      });
    }, 100);
    return () => window.clearInterval(t);
  }, [phase, answered, idx, choose]);


  if (phase === "setup" || phase === "loading") {
    return (
      <div>
        {error && (
          <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
        )}
        <div className="rounded-2xl border border-line bg-card p-6">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold">퀴즈 범위 고르기</h2>
            <MuteButton
              muted={muted}
              onToggle={() => {
                const m = !muted;
                setMuted(m);
                setMutedState(m);
                unlockAudio();
              }}
            />
          </div>
          <p className="mt-1 text-sm text-muted">정의를 보고 알맞은 용어를 4개 중에 고르는 게임이에요.</p>

          <div className="mt-5 space-y-4">
            <Field label="난이도">
              <div className="grid grid-cols-3 gap-2">
                {(Object.keys(LEVELS) as Level[]).map((lv) => (
                  <button
                    key={lv}
                    onClick={() => setScope((s) => ({ ...s, level: lv }))}
                    className={`rounded-xl border px-2 py-2.5 text-center transition ${
                      scope.level === lv ? "border-green bg-green/10" : "border-line bg-card hover:border-ink"
                    }`}
                  >
                    <div className={`text-sm font-extrabold ${scope.level === lv ? "text-green-deep" : "text-ink"}`}>
                      {LEVELS[lv].label}
                    </div>
                    <div className="mt-0.5 text-[11px] text-muted">{LEVELS[lv].hint}</div>
                  </button>
                ))}
              </div>
            </Field>
            <Field label="분야">
              <div className="flex flex-wrap gap-2">
                {(["all", "ai", "app", "vibe"] as const).map((c) => (
                  <Chip
                    key={c}
                    on={scope.collection === c}
                    onClick={() => setScope((s) => ({ ...s, collection: c }))}
                  >
                    {c === "all" ? "전체" : TECHDEX_COLLECTION_LABEL[c]}
                    {stats && c !== "all" && (
                      <span className="ml-1 opacity-60">
                        {stats.byCollection.find((x) => x.collection === c)?.count ?? 0}
                      </span>
                    )}
                  </Chip>
                ))}
              </div>
            </Field>
            <Field label="문항 수">
              <div className="flex gap-2">
                {[5, 10, 15, 20].map((n) => (
                  <Chip key={n} on={scope.count === n} onClick={() => setScope((s) => ({ ...s, count: n }))}>
                    {n}문제
                  </Chip>
                ))}
              </div>
            </Field>
            <label className="flex cursor-pointer items-center gap-2 text-sm font-semibold">
              <input
                type="checkbox"
                checked={scope.vibeCore}
                onChange={(e) => setScope((s) => ({ ...s, vibeCore: e.target.checked }))}
                className="h-4 w-4 accent-green"
              />
              바이브코딩 <b className="text-green-deep">필수 용어</b>만 (입문용 20선)
            </label>
          </div>

          <button
            onClick={start}
            disabled={phase === "loading"}
            className="mt-6 w-full rounded-full bg-green py-3 text-sm font-bold text-white transition hover:bg-green-deep disabled:opacity-50"
          >
            {phase === "loading" ? "문제 준비 중…" : "시작하기 →"}
          </button>
        </div>
      </div>
    );
  }

  if (phase === "result") {
    const acc = questions.length ? Math.round((correctCount / questions.length) * 100) : 0;
    return (
      <div className="rounded-2xl border border-line bg-card p-6 text-center">
        <div className="text-5xl">{acc >= 80 ? "🏆" : acc >= 50 ? "👍" : "📚"}</div>
        <h2 className="mt-3 font-display text-2xl font-extrabold">결과</h2>
        <div className="mx-auto mt-5 grid max-w-md grid-cols-3 gap-3">
          <ResultTile label="점수" value={score.toLocaleString()} accent="text-green-deep" />
          <ResultTile label="정답" value={`${correctCount}/${questions.length}`} accent="text-ink" />
          <ResultTile label="정확도" value={`${acc}%`} accent="text-cobalt" />
        </div>
        <div className="mt-2 text-sm text-muted">최고 콤보 {bestCombo}연속</div>

        {wrongList.length > 0 && (
          <div className="mx-auto mt-6 max-w-lg text-left">
            <h3 className="mb-2 text-sm font-bold text-muted">틀린 용어 복습 ({wrongList.length})</h3>
            <ul className="space-y-2">
              {wrongList.map((q) => (
                <li key={q.slug} className="rounded-xl bg-paper p-3 text-sm">
                  <div className="font-bold text-ink">
                    {q.reveal.term}
                    {q.reveal.sub && <span className="ml-1 text-xs font-medium text-muted">{q.reveal.sub}</span>}
                  </div>
                  <div className="mt-0.5 text-muted">{q.prompt}</div>
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="mt-6 flex justify-center gap-2">
          <button
            onClick={start}
            className="rounded-full bg-green px-6 py-2.5 text-sm font-bold text-white hover:bg-green-deep"
          >
            같은 범위 다시
          </button>
          <button
            onClick={() => setPhase("setup")}
            className="rounded-full border border-line bg-card px-6 py-2.5 text-sm font-bold hover:border-ink"
          >
            범위 바꾸기
          </button>
        </div>
      </div>
    );
  }

  // playing
  const q = questions[idx];
  const pct = (timeLeft / QSEC) * 100;
  const correct = answered && selected === q.answerIndex;
  return (
    <div className="mx-auto max-w-2xl">
      {/* 상단: 탁상시계 타이머 + 점수 */}
      <div className="mb-2.5 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <TickClock remaining={timeLeft} total={QSEC} paused={answered} />
          <div className={`font-display text-3xl font-extrabold leading-none ${timeLeft <= 3.4 ? "text-red-500" : "text-ink"}`}>
            {Math.ceil(timeLeft)}
            <span className="ml-0.5 text-sm font-bold text-muted">초</span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {combo > 1 && (
            <span className="rounded-full bg-amber-100 px-2.5 py-1 text-sm font-extrabold text-amber-600">🔥 {combo}</span>
          )}
          <span className="font-display text-2xl font-extrabold text-green-deep">{score.toLocaleString()}</span>
          <MuteButton
            small
            muted={muted}
            onToggle={() => {
              const m = !muted;
              setMuted(m);
              setMutedState(m);
            }}
          />
        </div>
      </div>

      {/* 슬림 진행 바 */}
      <div className="mb-6 h-2 overflow-hidden rounded-full bg-line">
        <div
          className={`h-full rounded-full transition-[width] duration-100 ${
            pct > 33 ? "bg-gradient-to-r from-green to-lime" : "bg-red-400"
          }`}
          style={{ width: `${pct}%` }}
        />
      </div>

      {/* 질문 카드 */}
      <div className="rounded-3xl border border-line bg-gradient-to-b from-white to-paper p-7 text-center shadow-sm sm:p-9">
        <div className="text-xs font-extrabold uppercase tracking-[0.15em] text-green">
          문제 {idx + 1} / {questions.length} · 이 뜻의 용어는?
        </div>
        <p className="mx-auto mt-4 max-w-xl text-2xl font-extrabold leading-snug tracking-tight text-ink sm:text-[28px]">
          {q.prompt}
        </p>
      </div>

      {/* 보기 4개 */}
      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        {q.choices.map((choice, i) => {
          const isAnswer = i === q.answerIndex;
          const isPicked = selected === i;
          let cls = "border-line bg-card hover:border-green hover:shadow-md";
          let badge = "bg-paper text-muted";
          if (answered) {
            if (isAnswer) {
              cls = "border-2 border-green bg-green/15";
              badge = "bg-green text-white";
            } else if (isPicked) {
              cls = "border-2 border-red-400 bg-red-50";
              badge = "bg-red-400 text-white";
            } else cls = "border-line bg-card opacity-45";
          }
          return (
            <button
              key={i}
              onClick={() => choose(i)}
              disabled={answered}
              className={`flex items-center gap-3.5 rounded-2xl border px-5 py-4 text-left transition ${cls}`}
            >
              <span className={`grid h-8 w-8 shrink-0 place-items-center rounded-lg text-sm font-extrabold ${badge}`}>
                {"ABCD"[i]}
              </span>
              <span className="min-w-0 flex-1 text-base font-bold text-ink sm:text-lg">{choice}</span>
              {answered && isAnswer && <span className="text-xl font-extrabold text-green">✓</span>}
              {answered && isPicked && !isAnswer && <span className="text-xl font-extrabold text-red-500">✕</span>}
            </button>
          );
        })}
      </div>

      {/* 정답/오답 배너 */}
      {answered && (
        <div
          className={`mt-4 flex items-center gap-3 rounded-2xl px-5 py-4 text-base font-extrabold ${
            correct ? "bg-green/15 text-green-deep" : "bg-red-50 text-red-700"
          }`}
        >
          <span className="text-2xl">{correct ? "🎉" : "💡"}</span>
          <span className="min-w-0">
            {correct ? "정답이에요!" : "아쉬워요"} · 정답은 <b>{q.reveal.term}</b>
            {q.reveal.sub && <span className="ml-1 text-sm font-semibold opacity-70">{q.reveal.sub}</span>}
          </span>
        </div>
      )}
    </div>
  );
}

// ────────────────────────── 용어 도감 ──────────────────────────
function Dex({ me }: { me: Me }) {
  const [q, setQ] = useState("");
  const [collection, setCollection] = useState<TechdexCollection | "all">("all");
  const [terms, setTerms] = useState<TechdexTerm[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [suggestOpen, setSuggestOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams({ limit: "120" });
    if (collection !== "all") params.set("collection", collection);
    if (q.trim()) params.set("q", q.trim());
    const r = await api<{ total: number; terms: TechdexTerm[] }>(`/api/techdex/terms?${params}`);
    setLoading(false);
    if (r.ok) {
      setTerms(r.data.terms);
      setTotal(r.data.total);
    }
  }, [collection, q]);

  useEffect(() => {
    const t = setTimeout(load, 250);
    return () => clearTimeout(t);
  }, [load]);

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="용어 검색… (예: 토큰, 에이전트, 커밋)"
          className="min-w-52 flex-1 rounded-full border border-line bg-card px-5 py-2 text-sm outline-none focus:border-ink"
        />
        {(["all", "ai", "app", "vibe", "user"] as const).map((c) => (
          <Chip key={c} on={collection === c} onClick={() => setCollection(c)}>
            {c === "all" ? "전체" : TECHDEX_COLLECTION_LABEL[c]}
          </Chip>
        ))}
      </div>
      <div className="mb-3 text-sm text-muted">{loading ? "불러오는 중…" : `${total.toLocaleString()}개`}</div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {terms.map((t) => (
          <div key={t.id} className="flex flex-col rounded-2xl border border-line bg-card p-4">
            <span className={`mb-2 self-start rounded-full px-2 py-0.5 text-xs font-bold ${COLL_BADGE[t.collection]}`}>
              {t.category}
            </span>
            <div className="font-bold text-ink">
              {t.term}
              {t.vibeCore && <span className="ml-1 align-middle text-xs text-amber-500">★필수</span>}
            </div>
            {t.sub && <div className="text-xs font-medium text-muted">{t.sub}</div>}
            <div className="mt-2 text-sm text-ink/80">{t.def}</div>
          </div>
        ))}
      </div>
      {!loading && terms.length === 0 && (
        <div className="rounded-2xl border border-dashed border-line bg-card px-6 py-14 text-center">
          <div className="text-3xl">🔍</div>
          <p className="mt-2 font-semibold text-ink">
            {q.trim() ? <>‘{q.trim()}’ 용어가 아직 없어요</> : "검색 결과가 없습니다."}
          </p>
          {q.trim() && (
            <>
              <p className="mt-1 text-sm text-muted">
                찾는 용어가 없다면 추가를 요청해 주세요. 검토 후 도감에 등록됩니다.
              </p>
              <button
                onClick={() => setSuggestOpen(true)}
                className="mt-4 rounded-full bg-green px-5 py-2.5 text-sm font-bold text-white transition hover:bg-green-deep"
              >
                ＋ ‘{q.trim()}’ 추가 요청하기
              </button>
            </>
          )}
        </div>
      )}

      {suggestOpen && (
        <SuggestForm me={me} initialTerm={q.trim()} onClose={() => setSuggestOpen(false)} />
      )}
    </div>
  );
}

// ── 용어 추가 요청 폼 (검색 실패 시) ──
function SuggestForm({ me, initialTerm, onClose }: { me: Me; initialTerm: string; onClose: () => void }) {
  const [term, setTerm] = useState(initialTerm);
  const [sub, setSub] = useState("");
  const [note, setNote] = useState("");
  const [def, setDef] = useState("");
  const [state, setState] = useState<"form" | "sending" | "done" | "dup">("form");
  const [msg, setMsg] = useState("");

  if (!me) {
    return (
      <Overlay onClose={onClose}>
        <h3 className="text-lg font-bold">로그인이 필요해요</h3>
        <p className="mt-2 text-sm text-muted">
          용어 추가 요청은 로그인 후 가능합니다. 우측 상단에서 소셜 계정으로 로그인해 주세요.
        </p>
        <a
          href="/login"
          className="mt-4 inline-block rounded-full bg-ink px-5 py-2.5 text-sm font-bold text-white"
        >
          로그인하러 가기
        </a>
      </Overlay>
    );
  }

  const submit = async () => {
    if (!term.trim()) return;
    setState("sending");
    const r = await api<{ submitted?: boolean; duplicate?: boolean; term?: string; already?: boolean }>(
      "/api/techdex/suggest",
      {
        method: "POST",
        body: JSON.stringify({
          term: term.trim(),
          sub: sub.trim() || undefined,
          def: def.trim() || undefined,
          note: note.trim() || undefined,
        }),
      },
    );
    if (r.ok && r.data.duplicate) {
      setMsg(`‘${r.data.term}’ 은(는) 이미 도감에 있어요. 검색해 보세요!`);
      setState("dup");
    } else if (r.ok && (r.data.submitted || r.data.already)) {
      setState("done");
    } else {
      setMsg("전송에 실패했습니다. 잠시 후 다시 시도해 주세요.");
      setState("form");
    }
  };

  return (
    <Overlay onClose={onClose}>
      {state === "done" ? (
        <div className="text-center">
          <div className="text-4xl">🙌</div>
          <h3 className="mt-2 text-lg font-bold">추가 요청 완료!</h3>
          <p className="mt-1 text-sm text-muted">검토 후 도감에 등록됩니다. 감사합니다.</p>
          <button onClick={onClose} className="mt-4 rounded-full bg-ink px-5 py-2 text-sm font-bold text-white">
            닫기
          </button>
        </div>
      ) : state === "dup" ? (
        <div className="text-center">
          <div className="text-4xl">✅</div>
          <p className="mt-2 text-sm font-semibold text-ink">{msg}</p>
          <button onClick={onClose} className="mt-4 rounded-full bg-ink px-5 py-2 text-sm font-bold text-white">
            닫기
          </button>
        </div>
      ) : (
        <>
          <h3 className="text-lg font-bold">용어 추가 요청</h3>
          <p className="mt-1 text-sm text-muted">
            뜻을 정확히 몰라도 괜찮아요. 용어만 적어도 되고, 아는 만큼만 채워주세요.
          </p>
          <div className="mt-4 space-y-3">
            <Input label="용어 *" value={term} onChange={setTerm} placeholder="예: diff" />
            <Input label="영문/약어 (선택)" value={sub} onChange={setSub} placeholder="예: difference" />
            <Input
              label="맥락·메모 (선택)"
              value={note}
              onChange={setNote}
              placeholder="예: git에서 변경점 비교할 때 쓰는 말"
            />
            <div>
              <div className="mb-1 text-xs font-bold text-muted">아는 뜻 (선택)</div>
              <textarea
                value={def}
                onChange={(e) => setDef(e.target.value)}
                rows={2}
                placeholder="대충 아는 대로 적어주세요. 검토하며 다듬습니다."
                className="w-full rounded-xl border border-line bg-card px-3 py-2 text-sm outline-none focus:border-ink"
              />
            </div>
          </div>
          {msg && <p className="mt-2 text-sm text-red-600">{msg}</p>}
          <div className="mt-4 flex justify-end gap-2">
            <button onClick={onClose} className="rounded-full border border-line px-4 py-2 text-sm font-semibold hover:border-ink">
              취소
            </button>
            <button
              onClick={submit}
              disabled={state === "sending" || !term.trim()}
              className="rounded-full bg-green px-5 py-2 text-sm font-bold text-white hover:bg-green-deep disabled:opacity-50"
            >
              {state === "sending" ? "보내는 중…" : "요청 보내기"}
            </button>
          </div>
        </>
      )}
    </Overlay>
  );
}

// ── 관리자: 제안 검토 ──
function Review({ onResolved }: { onResolved: () => void }) {
  const [items, setItems] = useState<TechdexSuggestion[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    const r = await api<{ suggestions: TechdexSuggestion[] }>("/api/techdex/suggestions?status=pending");
    setLoading(false);
    if (r.ok) setItems(r.data.suggestions);
  }, []);
  useEffect(() => {
    load();
  }, [load]);

  const remove = (id: number) => setItems((xs) => xs.filter((x) => x.id !== id));

  if (loading) return <div className="py-16 text-center text-muted">불러오는 중…</div>;
  if (items.length === 0)
    return <div className="py-16 text-center text-sm text-muted">대기 중인 제안이 없습니다.</div>;

  return (
    <div className="space-y-3">
      <div className="text-sm text-muted">대기 중인 제안 {items.length}건 — 승인하면 도감에 등록됩니다.</div>
      {items.map((s) => (
        <ReviewCard
          key={s.id}
          s={s}
          onDone={() => {
            remove(s.id);
            onResolved();
          }}
        />
      ))}
    </div>
  );
}

function ReviewCard({ s, onDone }: { s: TechdexSuggestion; onDone: () => void }) {
  const [term, setTerm] = useState(s.term);
  const [sub, setSub] = useState(s.sub ?? "");
  const [def, setDef] = useState(s.def ?? "");
  const [category, setCategory] = useState(s.category ?? "사용자 추가");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const approve = async () => {
    if (!term.trim() || !def.trim() || !category.trim()) {
      setErr("용어·뜻·분류는 필수입니다.");
      return;
    }
    setBusy(true);
    const r = await api("/api/techdex/suggestions/" + s.id + "/approve", {
      method: "POST",
      body: JSON.stringify({ term: term.trim(), sub: sub.trim() || null, def: def.trim(), category: category.trim() }),
    });
    setBusy(false);
    if (r.ok) onDone();
    else setErr("승인 실패");
  };
  const reject = async () => {
    setBusy(true);
    const r = await api("/api/techdex/suggestions/" + s.id + "/reject", { method: "POST" });
    setBusy(false);
    if (r.ok) onDone();
  };

  return (
    <div className="rounded-2xl border border-line bg-card p-4">
      <div className="mb-2 flex items-center gap-2 text-xs text-muted">
        <span className="font-semibold text-ink">{s.userName ?? "회원"}</span> 님 제안
        {s.note && <span>· 메모: {s.note}</span>}
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        <Input label="용어 *" value={term} onChange={setTerm} placeholder="용어" />
        <Input label="영문/약어" value={sub} onChange={setSub} placeholder="영문/약어" />
      </div>
      <div className="mt-2">
        <div className="mb-1 text-xs font-bold text-muted">뜻 *</div>
        <textarea
          value={def}
          onChange={(e) => setDef(e.target.value)}
          rows={2}
          placeholder="정의를 작성/보정하세요"
          className="w-full rounded-xl border border-line bg-card px-3 py-2 text-sm outline-none focus:border-ink"
        />
      </div>
      <div className="mt-2 max-w-xs">
        <Input label="분류 *" value={category} onChange={setCategory} placeholder="예: 코드·협업" />
      </div>
      {err && <p className="mt-2 text-sm text-red-600">{err}</p>}
      <div className="mt-3 flex justify-end gap-2">
        <button
          onClick={reject}
          disabled={busy}
          className="rounded-full border border-line px-4 py-1.5 text-sm font-semibold text-muted hover:border-red-300 hover:text-red-600 disabled:opacity-50"
        >
          거절
        </button>
        <button
          onClick={approve}
          disabled={busy}
          className="rounded-full bg-green px-5 py-1.5 text-sm font-bold text-white hover:bg-green-deep disabled:opacity-50"
        >
          {busy ? "처리 중…" : "승인 · 등록"}
        </button>
      </div>
    </div>
  );
}

function Overlay({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-ink/40 p-4" onClick={onClose}>
      <div
        className="w-full max-w-md rounded-2xl border border-line bg-card p-6 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </div>
  );
}

function Input({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-bold text-muted">{label}</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-xl border border-line bg-card px-3 py-2 text-sm outline-none focus:border-ink"
      />
    </label>
  );
}

// ── 움직이는 탁상시계 타이머 ──
function TickClock({ remaining, total, paused }: { remaining: number; total: number; paused: boolean }) {
  const cx = 24;
  const cy = 27;
  const r = 12;
  const frac = total > 0 ? Math.min(1, (total - remaining) / total) : 0;
  const ang = (-90 + frac * 360) * (Math.PI / 180);
  const hx = cx + r * Math.cos(ang);
  const hy = cy + r * Math.sin(ang);
  const urgent = remaining <= 3.4;
  const hand = urgent ? "#ef4444" : "#0E5741";
  // 째깍째깍 좌우로 흔들림 (일시정지 시 정지)
  const rock = paused ? 0 : Math.floor(remaining) % 2 === 0 ? -5 : 5;
  return (
    <svg
      width="44"
      height="44"
      viewBox="0 0 48 48"
      aria-hidden="true"
      style={{ transform: `rotate(${rock}deg)`, transformOrigin: "50% 92%", transition: "transform .16s ease-in-out" }}
    >
      {/* 종(벨) */}
      <g fill="#0E5741">
        <ellipse cx="13" cy="10" rx="6.5" ry="5" transform="rotate(-28 13 10)" />
        <ellipse cx="35" cy="10" rx="6.5" ry="5" transform="rotate(28 35 10)" />
      </g>
      <rect x="22" y="3.5" width="4" height="6" rx="2" fill="#0E5741" />
      {/* 다리 */}
      <g stroke="#0E5741" strokeWidth="3" strokeLinecap="round">
        <line x1="16" y1="41" x2="12" y2="46" />
        <line x1="32" y1="41" x2="36" y2="46" />
      </g>
      {/* 몸통 */}
      <circle cx={cx} cy={cy} r="16" fill="#0E5741" />
      <circle cx={cx} cy={cy} r="13.5" fill="#F6F7FA" />
      {/* 눈금 */}
      <g stroke="#c9cfd8" strokeWidth="1.6" strokeLinecap="round">
        <line x1={cx} y1={cy - 11} x2={cx} y2={cy - 8.5} />
        <line x1={cx + 11} y1={cy} x2={cx + 8.5} y2={cy} />
        <line x1={cx} y1={cy + 11} x2={cx} y2={cy + 8.5} />
        <line x1={cx - 11} y1={cy} x2={cx - 8.5} y2={cy} />
      </g>
      {/* 시침(정적) + 초침(회전) */}
      <line x1={cx} y1={cy} x2={cx} y2={cy - 6.5} stroke="#9aa4af" strokeWidth="2.2" strokeLinecap="round" />
      <line x1={cx} y1={cy} x2={hx} y2={hy} stroke={hand} strokeWidth="2.4" strokeLinecap="round" />
      <circle cx={cx} cy={cy} r="2" fill={hand} />
    </svg>
  );
}

function MuteButton({ muted, onToggle, small }: { muted: boolean; onToggle: () => void; small?: boolean }) {
  return (
    <button
      onClick={onToggle}
      title={muted ? "소리 켜기" : "소리 끄기"}
      aria-label={muted ? "소리 켜기" : "소리 끄기"}
      className={`grid ${small ? "h-8 w-8" : "h-9 w-9"} shrink-0 place-items-center rounded-full border border-line bg-card transition hover:border-ink`}
    >
      {muted ? "🔇" : "🔊"}
    </button>
  );
}

// ── 작은 UI ──
function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <div className="mb-2 text-xs font-bold text-muted">{label}</div>
      {children}
    </div>
  );
}
function Chip({ on, onClick, children }: { on: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-full border px-3.5 py-1.5 text-sm font-semibold transition ${
        on ? "border-ink bg-ink text-white" : "border-line bg-card text-muted hover:border-ink hover:text-ink"
      }`}
    >
      {children}
    </button>
  );
}
function ResultTile({ label, value, accent }: { label: string; value: string; accent: string }) {
  return (
    <div className="rounded-2xl border border-line bg-paper p-4">
      <div className="text-xs text-muted">{label}</div>
      <div className={`mt-1 font-display text-2xl font-extrabold ${accent}`}>{value}</div>
    </div>
  );
}

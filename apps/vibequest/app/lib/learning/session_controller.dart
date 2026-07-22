import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../providers.dart';
import 'mastery.dart';
import 'question_gen.dart';
import 'short_answer.dart';

/// 세션 모드 (§5.2)
enum SessionMode { dailyMission, quickReview, newExplore, wrongFix }

String modeToDb(SessionMode m) => switch (m) {
      SessionMode.dailyMission => 'DAILY_MISSION',
      SessionMode.quickReview => 'QUICK_REVIEW',
      SessionMode.newExplore => 'NEW_EXPLORE',
      SessionMode.wrongFix => 'WRONG_FIX',
    };

/// 직전 답변 피드백 (하단 시트에 표시)
class LastFeedback {
  final bool correct;
  final String explanation;
  final int gems;
  final int xp;
  const LastFeedback({required this.correct, required this.explanation, required this.gems, required this.xp});
}

class SessionState {
  final SessionMode mode;
  final List<QuizQuestion> queue;
  final int index;
  final int combo;
  final int maxCombo;
  final int xp;
  final int gems;
  final int correctCount;
  final int answeredCount;
  final Set<String> newTermIds;
  final Set<String> reviewTermIds;
  final Set<String> wrongTermIds;
  final LastFeedback? feedback; // null = 아직 답 안 함
  final int hintLevel; // 현재 문제에서 사용한 힌트 단계 (0=없음)
  final List<String> hints; // 공개된 힌트 문구들
  final List<QuizQuestion> history; // 답변한 문제들 (이전 문제 다시보기·신고용)
  final bool finished;
  final bool loading;
  final bool empty; // 출제할 문제가 없음 (예: 오답 없음)

  const SessionState({
    this.mode = SessionMode.dailyMission,
    this.queue = const [],
    this.index = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.xp = 0,
    this.gems = 0,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.newTermIds = const {},
    this.reviewTermIds = const {},
    this.wrongTermIds = const {},
    this.feedback,
    this.hintLevel = 0,
    this.hints = const [],
    this.history = const [],
    this.finished = false,
    this.loading = true,
    this.empty = false,
  });

  QuizQuestion? get current => index < queue.length ? queue[index] : null;
  int get total => queue.length;

  SessionState copyWith({
    SessionMode? mode,
    List<QuizQuestion>? queue,
    int? index,
    int? combo,
    int? maxCombo,
    int? xp,
    int? gems,
    int? correctCount,
    int? answeredCount,
    Set<String>? newTermIds,
    Set<String>? reviewTermIds,
    Set<String>? wrongTermIds,
    LastFeedback? feedback,
    bool clearFeedback = false,
    int? hintLevel,
    List<String>? hints,
    List<QuizQuestion>? history,
    bool? finished,
    bool? loading,
    bool? empty,
  }) =>
      SessionState(
        mode: mode ?? this.mode,
        queue: queue ?? this.queue,
        index: index ?? this.index,
        combo: combo ?? this.combo,
        maxCombo: maxCombo ?? this.maxCombo,
        xp: xp ?? this.xp,
        gems: gems ?? this.gems,
        correctCount: correctCount ?? this.correctCount,
        answeredCount: answeredCount ?? this.answeredCount,
        newTermIds: newTermIds ?? this.newTermIds,
        reviewTermIds: reviewTermIds ?? this.reviewTermIds,
        wrongTermIds: wrongTermIds ?? this.wrongTermIds,
        feedback: clearFeedback ? null : (feedback ?? this.feedback),
        hintLevel: hintLevel ?? this.hintLevel,
        hints: hints ?? this.hints,
        history: history ?? this.history,
        finished: finished ?? this.finished,
        loading: loading ?? this.loading,
        empty: empty ?? this.empty,
      );
}

class SessionController extends StateNotifier<SessionState> {
  final VqDatabase db;
  final Random rng = Random();
  QuestionGen? _gen;
  List<Term> _pool = [];
  Set<String> _allNames = {}; // 주관식 '다른 용어' 판정용
  final Map<String, int> _exposure = {}; // 같은 용어 세션 내 최대 2회 (§5.1)
  DateTime _startedAt = DateTime.now();
  DateTime _questionShownAt = DateTime.now();
  bool _saved = false;

  SessionController(this.db) : super(const SessionState());

  /// 세션 시작 (§5.2 세션 종류)
  Future<void> start({SessionMode mode = SessionMode.dailyMission}) async {
    state = SessionState(mode: mode, loading: true);
    _exposure.clear();
    _saved = false;
    _startedAt = DateTime.now();

    _pool = await db.activeTerms();
    _gen = QuestionGen(_pool, rng: rng);
    _allNames = {
      for (final t in _pool) ...[normalizeAnswer(t.termKo), normalizeAnswer(t.termEn)],
    }..remove('');

    List<Term> review = [];
    List<Term> fresh = [];
    switch (mode) {
      case SessionMode.dailyMission: // 하루 목표(3/5/10분)에 따라 7/11/18문제, 신규:복습 60:40
        final goal = int.tryParse(await db.getMeta('dailyGoal') ?? '') ?? 3;
        final count = goal >= 10 ? 18 : (goal >= 5 ? 11 : 7);
        review = await db.dueTerms(DateTime.now(), limit: (count * 0.4).round());
        fresh = await db.freshTerms(limit: count - review.length);
      case SessionMode.quickReview: // 만기 복습 5문제
        review = await db.dueTerms(DateTime.now(), limit: 5);
      case SessionMode.newExplore: // 새 용어 8개
        fresh = await db.freshTerms(limit: 8);
      case SessionMode.wrongFix: // 최근 오답 5개
        review = await db.recentWrongTerms(limit: 5);
    }

    if (review.isEmpty && fresh.isEmpty) {
      state = SessionState(mode: mode, loading: false, empty: true);
      return;
    }

    final queue = <QuizQuestion>[];
    final newIds = <String>{};
    final reviewIds = <String>{};
    for (final t in review) {
      reviewIds.add(t.id);
      queue.add(await _makeQuestion(t, isReview: true));
    }
    for (final t in fresh) {
      newIds.add(t.id);
      queue.add(await _makeQuestion(t, isReview: false));
    }
    queue.shuffle(rng);
    for (final q in queue) {
      _exposure[q.term.id] = 1;
    }

    state = SessionState(
      mode: mode,
      queue: queue,
      newTermIds: newIds,
      reviewTermIds: reviewIds,
      loading: false,
    );
    _questionShownAt = DateTime.now();
  }

  /// 상태 기반 문제 형식 선택 (§9.4)
  /// 익숙하지 않은 용어(NEW·LEARNING, 점수<40)는 쉬움 모드 — 함정 오답 금지 (UX-02)
  Future<QuizQuestion> _makeQuestion(Term t, {required bool isReview, QType? forceType}) async {
    final st = await db.stateOf(t.id);
    final ls = stateFromDb(st?.state ?? 'NEW');
    final easy = (st?.masteryScore ?? 0) < 40 ||
        ls == TermLearningState.newTerm ||
        ls == TermLearningState.learning;
    QType type;
    if (forceType != null) {
      type = forceType;
    } else {
      // §9.4 상태별 출제 형식 — 워드스트립·짝맞추기 포함
      final canStrip = QuestionGen.stripAnswerOf(t) != null;
      type = switch (ls) {
        TermLearningState.newTerm => QType.ox,
        TermLearningState.learning =>
          [QType.ox, QType.mcq4, QType.matchPair][rng.nextInt(3)],
        // REVIEWING 이상: 주관식·워드스트립 등 인출 연습 포함
        _ => ([
          QType.mcq4,
          QType.shortText,
          QType.ox,
          if (canStrip) QType.wordStrip,
          QType.matchPair,
        ]..shuffle(rng))
            .first,
      };
    }
    return _gen!.build(t, type, isReview: isReview, easy: easy);
  }

  /// 주관식 자동완성 후보 (§8.3)
  List<String> suggest(String input) => autocomplete(input, _pool);

  /// 힌트 사다리 (§8.3): 첫글자 → 글자수 → 카테고리 → 영문명 → 보기 4개 전환
  Future<void> requestHint() async {
    final q = state.current;
    if (q == null || q.type != QType.shortText || state.feedback != null) return;
    final t = q.term;
    final next = state.hintLevel + 1;
    if (next >= 5) {
      // 5단계: 보기 4개로 전환
      final mcq = _gen!.build(t, QType.mcq4, isReview: q.isReview);
      final queue = List<QuizQuestion>.of(state.queue)..[state.index] = mcq;
      state = state.copyWith(queue: queue, hintLevel: 4, hints: [...state.hints, '보기 4개로 바꿨어요!']);
      return;
    }
    final hint = switch (next) {
      1 => '첫 글자: ${t.termKo.substring(0, 1)}',
      2 => '글자 수: ${t.termKo.length}글자',
      3 => '분야: ${t.category}',
      _ => '영문명: ${t.termEn}',
    };
    state = state.copyWith(hintLevel: next, hints: [...state.hints, hint]);
  }

  /// 답 제출 — 중복 제출 방지 (FR-QUIZ-004)
  /// [puzzleMistakes]: 워드스트립·짝맞추기의 실수 횟수 (2번 이하면 정답 처리)
  Future<void> answer({int? mcqIndex, bool? oxChoice, String? shortInput, int? puzzleMistakes}) async {
    final q = state.current;
    if (q == null || state.feedback != null || state.finished) return;

    final correct = switch (q.type) {
      QType.ox => oxChoice == q.oxAnswer,
      QType.shortText =>
        gradeShortAnswer(shortInput ?? '', q.term, otherTermNames: _otherNames(q.term)),
      QType.wordStrip || QType.matchPair => (puzzleMistakes ?? 99) <= 2,
      _ => mcqIndex == q.answerIndex,
    };
    final responseTime = DateTime.now().difference(_questionShownAt);
    final hintLevel = q.type == QType.shortText ? state.hintLevel : 0;

    // 숙련도 반영 (§9)
    final st = await db.stateOf(q.term.id);
    final snap = MasterySnapshot(
      state: stateFromDb(st?.state ?? 'NEW'),
      score: st?.masteryScore ?? 0,
      correctStreak: st?.correctStreak ?? 0,
      lapseCount: st?.lapseCount ?? 0,
    );
    final r = applyAnswer(
      snap,
      AnswerEvent(type: q.type, correct: correct, hintLevel: hintLevel, responseTime: responseTime),
    );
    final now = DateTime.now();
    await db.upsertState(TermStatesCompanion(
      termId: Value(q.term.id),
      state: Value(stateToDb(r.state)),
      masteryScore: Value(r.score),
      correctStreak: Value(r.correctStreak),
      lapseCount: Value(r.lapseCount),
      lastSeenAt: Value(now),
      nextReviewAt: Value(now.add(r.nextReviewIn)),
    ));

    // 보상 (§10) — 복습 1.2배, 주관식 무힌트 정답 보너스
    var gems = 0;
    var xp = 0;
    var combo = state.combo;
    if (correct) {
      // 힌트 사용 정답: 콤보 유지·증가 없음 (§10.3)
      if (hintLevel == 0) combo += 1;
      gems = q.isReview ? 3 : 2;
      if (q.type == QType.shortText && hintLevel == 0) gems += 1;
      xp = 10 + (combo >= 3 ? 2 : 0);
      if (hintLevel > 0) xp = (xp * 0.7).round(); // 힌트는 XP만 소폭 조정 (§8.3)
    } else {
      combo = combo > 0 ? combo - 1 : 0;
    }

    // 오답 재출제: 다른 형식으로 2~4문제 뒤 (§5.1)
    final queue = List<QuizQuestion>.of(state.queue);
    final wrong = <String>{...state.wrongTermIds};
    if (!correct) {
      wrong.add(q.term.id);
      if ((_exposure[q.term.id] ?? 0) < 2) {
        _exposure[q.term.id] = (_exposure[q.term.id] ?? 0) + 1;
        final retryType = q.type == QType.ox ? QType.mcq4 : QType.ox;
        final retry = await _makeQuestion(q.term, isReview: q.isReview, forceType: retryType);
        final insertAt = min(queue.length, state.index + 2 + rng.nextInt(3));
        queue.insert(insertAt, retry);
      }
    }

    state = state.copyWith(
      queue: queue,
      combo: combo,
      maxCombo: max(state.maxCombo, combo),
      xp: state.xp + xp,
      gems: state.gems + gems,
      correctCount: state.correctCount + (correct ? 1 : 0),
      answeredCount: state.answeredCount + 1,
      wrongTermIds: wrong,
      history: [...state.history, q],
      feedback: LastFeedback(correct: correct, explanation: q.explanation, gems: gems, xp: xp),
    );
  }

  Set<String> _otherNames(Term t) {
    final mine = answerCandidates(t).toSet();
    return _allNames.difference(mine);
  }

  /// 다음 문제로 (피드백 확인 후)
  Future<void> next() async {
    if (state.feedback == null) return;
    final nextIndex = state.index + 1;
    if (nextIndex >= state.queue.length) {
      await _finish();
    } else {
      state = state.copyWith(index: nextIndex, clearFeedback: true, hintLevel: 0, hints: []);
      _questionShownAt = DateTime.now();
    }
  }

  Future<void> _finish() async {
    if (_saved) return;
    _saved = true;
    // 완주 보너스 +5, 오답 수리 완료 추가 보상 +5 (§10.4)
    final bonus = 5 + (state.mode == SessionMode.wrongFix ? 5 : 0);
    final totalGems = state.gems + bonus;
    await db.addMetaInt('gems', totalGems);
    await db.addMetaInt('xp', state.xp);
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          mode: modeToDb(state.mode),
          startedAt: _startedAt,
          endedAt: Value(DateTime.now()),
          correctCount: Value(state.correctCount),
          newTerms: Value(state.newTermIds.length),
          reviewTerms: Value(state.reviewTermIds.length),
          xpEarned: Value(state.xp),
          gemsEarned: Value(totalGems),
          completed: const Value(true),
        ));
    state = state.copyWith(finished: true, gems: totalGems, clearFeedback: true);
  }
}

final sessionProvider =
    StateNotifierProvider.autoDispose<SessionController, SessionState>((ref) {
  return SessionController(ref.watch(databaseProvider));
});

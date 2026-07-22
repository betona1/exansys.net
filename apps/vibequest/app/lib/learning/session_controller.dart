import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../providers.dart';
import 'mastery.dart';
import 'question_gen.dart';

/// 직전 답변 피드백 (하단 시트에 표시)
class LastFeedback {
  final bool correct;
  final String explanation;
  final int gems;
  final int xp;
  const LastFeedback({required this.correct, required this.explanation, required this.gems, required this.xp});
}

class SessionState {
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
  final bool finished;
  final bool loading;

  const SessionState({
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
    this.finished = false,
    this.loading = true,
  });

  QuizQuestion? get current => index < queue.length ? queue[index] : null;
  int get total => queue.length;

  SessionState copyWith({
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
    bool? finished,
    bool? loading,
  }) =>
      SessionState(
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
        finished: finished ?? this.finished,
        loading: loading ?? this.loading,
      );
}

class SessionController extends StateNotifier<SessionState> {
  final VqDatabase db;
  final Random rng = Random();
  QuestionGen? _gen;
  final Map<String, int> _exposure = {}; // 같은 용어 세션 내 최대 2회 (§5.1)
  DateTime _startedAt = DateTime.now();
  DateTime _questionShownAt = DateTime.now();
  bool _saved = false;

  SessionController(this.db) : super(const SessionState());

  /// 오늘의 미션 시작 — 기본 7문제, 신규:복습 60:40 (§5.1)
  Future<void> start({int count = 7}) async {
    state = const SessionState(loading: true);
    _exposure.clear();
    _saved = false;
    _startedAt = DateTime.now();

    final pool = await db.activeTerms();
    _gen = QuestionGen(pool, rng: rng);

    final reviewTarget = (count * 0.4).round();
    final due = await db.dueTerms(DateTime.now(), limit: reviewTarget);
    final fresh = await db.freshTerms(limit: count - due.length);

    final queue = <QuizQuestion>[];
    final newIds = <String>{};
    final reviewIds = <String>{};

    for (final t in due) {
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
      queue: queue,
      newTermIds: newIds,
      reviewTermIds: reviewIds,
      loading: false,
    );
    _questionShownAt = DateTime.now();
  }

  /// 상태 기반 문제 형식 선택 (§9.4 — V2는 OX·MCQ4만)
  Future<QuizQuestion> _makeQuestion(Term t, {required bool isReview, QType? forceType}) async {
    final st = await db.stateOf(t.id);
    final ls = stateFromDb(st?.state ?? 'NEW');
    QType type;
    if (forceType != null) {
      type = forceType;
    } else if (ls == TermLearningState.newTerm) {
      type = QType.ox;
    } else {
      type = rng.nextBool() ? QType.ox : QType.mcq4;
    }
    return _gen!.build(t, type, isReview: isReview);
  }

  /// 답 제출 (mcqIndex 또는 oxChoice 중 하나) — 중복 제출 방지 (FR-QUIZ-004)
  Future<void> answer({int? mcqIndex, bool? oxChoice}) async {
    final q = state.current;
    if (q == null || state.feedback != null || state.finished) return;

    final correct = q.type == QType.ox ? (oxChoice == q.oxAnswer) : (mcqIndex == q.answerIndex);
    final responseTime = DateTime.now().difference(_questionShownAt);

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
      AnswerEvent(type: q.type, correct: correct, responseTime: responseTime),
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

    // 보상 (§10) — 복습 만기 1.2배
    var gems = 0;
    var xp = 0;
    var combo = state.combo;
    if (correct) {
      combo += 1;
      gems = q.isReview ? 3 : 2;
      xp = 10 + (combo >= 3 ? 2 : 0);
    } else {
      combo = combo > 0 ? combo - 1 : 0; // 0으로 초기화하지 않고 1단계 감소 (§10.3)
    }

    // 오답 재출제: 다른 형식으로 2~4문제 뒤 (§5.1), 용어당 최대 2회 노출
    final queue = List<QuizQuestion>.of(state.queue);
    final wrong = <String>{...state.wrongTermIds};
    if (!correct) {
      wrong.add(q.term.id);
      if ((_exposure[q.term.id] ?? 0) < 2) {
        _exposure[q.term.id] = (_exposure[q.term.id] ?? 0) + 1;
        final retryType = q.type == QType.ox ? QType.mcq4 : QType.ox;
        final retry = await _makeQuestion(q.term, isReview: q.isReview, forceType: retryType);
        final insertAt = min(queue.length, state.index + 2 + rng.nextInt(3)); // +2~4
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
      feedback: LastFeedback(correct: correct, explanation: q.explanation, gems: gems, xp: xp),
    );
  }

  /// 다음 문제로 (피드백 확인 후)
  Future<void> next() async {
    if (state.feedback == null) return;
    final nextIndex = state.index + 1;
    if (nextIndex >= state.queue.length) {
      await _finish();
    } else {
      state = state.copyWith(index: nextIndex, clearFeedback: true);
      _questionShownAt = DateTime.now();
    }
  }

  Future<void> _finish() async {
    if (_saved) return;
    _saved = true;
    final completionBonus = 5;
    final totalGems = state.gems + completionBonus;
    await db.addMetaInt('gems', totalGems);
    await db.addMetaInt('xp', state.xp);
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          mode: 'DAILY_MISSION',
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

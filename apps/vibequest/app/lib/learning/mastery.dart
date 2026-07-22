/// 적응형 학습 엔진 — 숙련도 점수·상태·복습 간격 (TECHSPEC §9)
/// DB에 의존하지 않는 순수 로직: 단위 테스트 대상.
library;

enum TermLearningState { newTerm, learning, reviewing, mastered, lapsed }

TermLearningState stateFromDb(String s) => switch (s) {
      'LEARNING' => TermLearningState.learning,
      'REVIEWING' => TermLearningState.reviewing,
      'MASTERED' => TermLearningState.mastered,
      'LAPSED' => TermLearningState.lapsed,
      _ => TermLearningState.newTerm,
    };

String stateToDb(TermLearningState s) => switch (s) {
      TermLearningState.newTerm => 'NEW',
      TermLearningState.learning => 'LEARNING',
      TermLearningState.reviewing => 'REVIEWING',
      TermLearningState.mastered => 'MASTERED',
      TermLearningState.lapsed => 'LAPSED',
    };

/// 문제 유형 (§13.2 enum 중 MVP 대상)
enum QType { ox, mcq4, shortText, wordStrip, matchPair }

/// 답변 결과 입력
class AnswerEvent {
  final QType type;
  final bool correct;
  final int hintLevel; // 0 = 힌트 없음
  final int confidence; // 1 낮음 / 2 보통 / 3 높음
  final Duration responseTime;
  const AnswerEvent({
    required this.type,
    required this.correct,
    this.hintLevel = 0,
    this.confidence = 2,
    this.responseTime = const Duration(seconds: 5),
  });
}

/// 엔진에 넣는 현재 상태 스냅샷
class MasterySnapshot {
  final TermLearningState state;
  final int score; // 0~100
  final int correctStreak;
  final int lapseCount;
  const MasterySnapshot({
    this.state = TermLearningState.newTerm,
    this.score = 0,
    this.correctStreak = 0,
    this.lapseCount = 0,
  });
}

/// 엔진 출력
class MasteryResult {
  final TermLearningState state;
  final int score;
  final int correctStreak;
  final int lapseCount;
  final Duration nextReviewIn; // now + 이 값 = nextReviewAt
  final bool misconceptionFlag; // 자신감 높음 + 오답 (§9.2)
  const MasteryResult({
    required this.state,
    required this.score,
    required this.correctStreak,
    required this.lapseCount,
    required this.nextReviewIn,
    required this.misconceptionFlag,
  });
}

/// §9.2 기본 정답 점수
int _basePoints(QType t) => switch (t) {
      QType.ox || QType.matchPair || QType.wordStrip => 5,
      QType.mcq4 => 7,
      QType.shortText => 12,
    };

/// §9.2 힌트 보정: 획득 점수 30~70% 적용
double _hintFactor(int hintLevel) {
  if (hintLevel <= 0) return 1.0;
  final f = 0.7 - 0.1 * (hintLevel - 1);
  return f < 0.3 ? 0.3 : f;
}

/// 답변 하나를 반영해 다음 상태를 계산한다.
MasteryResult applyAnswer(MasterySnapshot cur, AnswerEvent e) {
  var score = cur.score;
  var streak = cur.correctStreak;
  var lapses = cur.lapseCount;
  var state = cur.state;
  var misconception = false;

  if (e.correct) {
    var gain = (_basePoints(e.type) * _hintFactor(e.hintLevel)).round();
    // 3초 미만 무작위 추정 가능성: 가산 제한 (§9.2)
    if (e.responseTime < const Duration(seconds: 3)) {
      gain = gain > 3 ? 3 : gain;
    }
    if (e.confidence >= 3) gain += 2;
    score = (score + gain).clamp(0, 100);
    // 힌트 사용 정답은 스트릭 유지·증가 없음 (§10.3 준용)
    if (e.hintLevel == 0) streak += 1;
  } else {
    score = (score - 5).clamp(0, 100);
    if (e.confidence >= 3) {
      score = (score - 3).clamp(0, 100); // 합계 -8 (§9.2)
      misconception = true;
    }
    streak = 0;
  }

  // 상태 전이 (§9.1)
  if (!e.correct && state == TermLearningState.mastered) {
    state = TermLearningState.lapsed;
    lapses += 1;
  } else if (e.correct && score >= 80 && streak >= 3) {
    state = TermLearningState.mastered;
  } else if (state == TermLearningState.newTerm) {
    state = TermLearningState.learning;
  } else if (e.correct &&
      (state == TermLearningState.learning || state == TermLearningState.lapsed)) {
    state = TermLearningState.reviewing;
  }

  // 복습 간격 (§9.3)
  final Duration next;
  if (!e.correct) {
    next = const Duration(minutes: 10);
  } else if (cur.state == TermLearningState.mastered && !e.correct) {
    next = const Duration(days: 1); // unreachable — 위 분기에서 처리되지만 명시
  } else if (streak >= 3) {
    next = const Duration(days: 21);
  } else if (streak == 2) {
    next = const Duration(days: 7);
  } else if (e.confidence <= 1) {
    next = const Duration(days: 1);
  } else {
    next = const Duration(days: 3);
  }

  return MasteryResult(
    state: state,
    score: score,
    correctStreak: streak,
    lapseCount: lapses,
    nextReviewIn: state == TermLearningState.lapsed ? const Duration(days: 1) : next,
    misconceptionFlag: misconception,
  );
}

/// §9.4 상태별 출제 형식
List<QType> allowedTypes(TermLearningState s) => switch (s) {
      TermLearningState.newTerm => [QType.ox],
      TermLearningState.learning => [QType.ox, QType.mcq4, QType.matchPair],
      TermLearningState.reviewing => [QType.mcq4, QType.shortText, QType.wordStrip],
      TermLearningState.mastered ||
      TermLearningState.lapsed =>
        [QType.mcq4, QType.shortText, QType.wordStrip, QType.matchPair],
    };

import 'package:flutter_test/flutter_test.dart';
import 'package:vibequest/learning/mastery.dart';

void main() {
  group('숙련도 엔진 (§9)', () {
    test('첫 O/X 정답: NEW → LEARNING, +5', () {
      final r = applyAnswer(
        const MasterySnapshot(),
        const AnswerEvent(type: QType.ox, correct: true),
      );
      expect(r.state, TermLearningState.learning);
      expect(r.score, 5);
      expect(r.correctStreak, 1);
    });

    test('오답: -5, 스트릭 0, 10분 뒤 복습', () {
      final r = applyAnswer(
        const MasterySnapshot(state: TermLearningState.learning, score: 20, correctStreak: 2),
        const AnswerEvent(type: QType.mcq4, correct: false),
      );
      expect(r.score, 15);
      expect(r.correctStreak, 0);
      expect(r.nextReviewIn, const Duration(minutes: 10));
    });

    test('자신감 높음 + 오답: -8 및 오개념 표시', () {
      final r = applyAnswer(
        const MasterySnapshot(score: 50),
        const AnswerEvent(type: QType.mcq4, correct: false, confidence: 3),
      );
      expect(r.score, 42);
      expect(r.misconceptionFlag, true);
    });

    test('점수는 0 미만으로 내려가지 않는다', () {
      final r = applyAnswer(
        const MasterySnapshot(score: 2),
        const AnswerEvent(type: QType.ox, correct: false),
      );
      expect(r.score, 0);
    });

    test('연속 2회 정답 → 7일, 3회 이상 → 21일', () {
      final r2 = applyAnswer(
        const MasterySnapshot(state: TermLearningState.reviewing, score: 40, correctStreak: 1),
        const AnswerEvent(type: QType.mcq4, correct: true),
      );
      expect(r2.correctStreak, 2);
      expect(r2.nextReviewIn, const Duration(days: 7));

      final r3 = applyAnswer(
        MasterySnapshot(state: r2.state, score: r2.score, correctStreak: r2.correctStreak),
        const AnswerEvent(type: QType.mcq4, correct: true),
      );
      expect(r3.correctStreak, 3);
      expect(r3.nextReviewIn, const Duration(days: 21));
    });

    test('80점·스트릭3 → MASTERED, MASTERED 오답 → LAPSED + 1일', () {
      final m = applyAnswer(
        const MasterySnapshot(state: TermLearningState.reviewing, score: 78, correctStreak: 2),
        const AnswerEvent(type: QType.shortText, correct: true),
      );
      expect(m.state, TermLearningState.mastered);

      final lapsed = applyAnswer(
        MasterySnapshot(state: m.state, score: m.score, correctStreak: m.correctStreak),
        const AnswerEvent(type: QType.mcq4, correct: false),
      );
      expect(lapsed.state, TermLearningState.lapsed);
      expect(lapsed.lapseCount, 1);
      expect(lapsed.nextReviewIn, const Duration(days: 1));
    });

    test('힌트 사용 정답: 점수 감쇠 + 스트릭 증가 없음', () {
      final r = applyAnswer(
        const MasterySnapshot(state: TermLearningState.reviewing, score: 30, correctStreak: 1),
        const AnswerEvent(type: QType.shortText, correct: true, hintLevel: 2),
      );
      expect(r.score, 30 + (12 * 0.6).round()); // 37
      expect(r.correctStreak, 1); // 유지, 증가 없음
    });

    test('3초 미만 빠른 정답: 가산 +3 제한', () {
      final r = applyAnswer(
        const MasterySnapshot(score: 10),
        const AnswerEvent(
          type: QType.shortText,
          correct: true,
          responseTime: Duration(seconds: 1),
        ),
      );
      expect(r.score, 13);
    });
  });
}

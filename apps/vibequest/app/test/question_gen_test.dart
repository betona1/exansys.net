import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibequest/db/database.dart';
import 'package:vibequest/learning/mastery.dart';
import 'package:vibequest/learning/question_gen.dart';

Term term(String id, String ko, String def,
        {String cat = 'DB', int diff = 2, String confusion = '[]'}) =>
    Term(
      id: id,
      termKo: ko,
      termEn: ko,
      def: def,
      whyItMatters: '',
      example: '',
      category: cat,
      subcategory: '',
      tracksJson: '[]',
      aliasesJson: '[]',
      confusionJson: confusion,
      difficulty: diff,
      vibeCore: false,
      volatileInfo: false,
      quizEnabled: true,
      retired: false,
      slug: id,
    );

void main() {
  final pool = [
    term('a', '인증', '본인이 맞는지 확인하는 것', confusion: '["인가"]'),
    term('b', '인가', '무엇을 할 수 있는지 권한을 확인하는 것', confusion: '["인증"]'),
    term('c', '세션', '로그인 상태를 유지하는 정보'),
    term('d', '쿠키', '브라우저에 저장되는 작은 데이터'),
    term('e', '토큰', '권한을 증명하는 문자열'),
  ];

  group('문제 생성기 (§8)', () {
    test('MCQ4: 선택지 4개·정답 1개·중복 없음, confusionSet 우선', () {
      final gen = QuestionGen(pool, rng: Random(42));
      for (var i = 0; i < 20; i++) {
        final q = gen.build(pool[0], QType.mcq4, isReview: false);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4); // 중복 없음
        expect(q.answerIndex, inInclusiveRange(0, 3));
        // 정답 위치 검증: 용어→정의든 정의→용어든 정답이 실제로 맞아야 함
        final correct = q.options[q.answerIndex];
        expect(correct == pool[0].def || correct == pool[0].termKo, true);
        // 혼동쌍 '인가'가 오답 후보에 우선 포함
        final joined = q.options.join();
        expect(joined.contains('인가') || joined.contains('권한을 확인'), true);
      }
    });

    test('OX: X 문장은 다른 용어의 정의를 쓰고 교정 설명 포함', () {
      final gen = QuestionGen(pool, rng: Random(7));
      var sawFalse = false;
      for (var i = 0; i < 30; i++) {
        final q = gen.build(pool[0], QType.ox, isReview: false);
        expect(q.prompt.contains('인증'), true);
        if (!q.oxAnswer) {
          sawFalse = true;
          expect(q.prompt.contains(pool[0].def), false); // 자기 정의가 아님
          expect(q.explanation.contains(pool[0].def), true); // 교정 설명에 올바른 정의
        }
      }
      expect(sawFalse, true);
    });
  });
}

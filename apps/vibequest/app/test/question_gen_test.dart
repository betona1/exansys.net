import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibequest/db/database.dart';
import 'package:vibequest/learning/mastery.dart';
import 'package:vibequest/learning/question_gen.dart';

Term term(String id, String ko, String def,
        {String cat = '백엔드·API', int diff = 2, String confusion = '[]'}) =>
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
    // 다른 분야 (쉬움 모드 오답 후보)
    term('d', '버튼', '누르면 동작이 실행되는 UI 요소', cat: 'UX·UI·제품·학습게임', diff: 1),
    term('e', '커밋', '코드 변경을 저장소에 기록하는 것', cat: 'Git·DevOps·클라우드', diff: 1),
    term('f', '테이블', '데이터를 담는 표', cat: '데이터베이스·데이터', diff: 1),
    term('g', '폰트', '글자의 모양 스타일', cat: 'UX·UI·제품·학습게임', diff: 1),
  ];

  group('문제 생성기 (§8)', () {
    test('숙련 모드(easy=false): confusionSet 우선 오답', () {
      final gen = QuestionGen(pool, rng: Random(42));
      var sawConfusion = false;
      for (var i = 0; i < 20; i++) {
        final q = gen.build(pool[0], QType.mcq4, isReview: false, easy: false);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        final correct = q.options[q.answerIndex];
        expect(correct == pool[0].def || correct == pool[0].termKo, true);
        final joined = q.options.join();
        if (joined.contains('인가') || joined.contains('권한을 확인')) sawConfusion = true;
      }
      expect(sawConfusion, true);
    });

    test('쉬움 모드(easy=true): 혼동쌍 배제 — 함정 없음 (UX-02)', () {
      final gen = QuestionGen(pool, rng: Random(1));
      for (var i = 0; i < 30; i++) {
        final q = gen.build(pool[0], QType.mcq4, isReview: false, easy: true);
        expect(q.options.length, 4);
        // 혼동쌍 '인가'(termKo·def 모두)가 오답에 없어야 한다
        final wrongs = [
          for (var j = 0; j < 4; j++)
            if (j != q.answerIndex) q.options[j],
        ];
        for (final w in wrongs) {
          expect(w == '인가' || w == pool[1].def, false,
              reason: '쉬움 모드에서 혼동쌍이 오답으로 나오면 안 됨');
        }
      }
    });

    test('쉬움 모드 OX: X 문장은 다른 분야 정의 + 교정 설명', () {
      final gen = QuestionGen(pool, rng: Random(7));
      var sawFalse = false;
      for (var i = 0; i < 40; i++) {
        final q = gen.build(pool[0], QType.ox, isReview: false, easy: true);
        expect(q.prompt.contains('인증'), true);
        if (!q.oxAnswer) {
          sawFalse = true;
          expect(q.prompt.contains(pool[0].def), false);
          expect(q.prompt.contains(pool[1].def), false, reason: '혼동쌍 정의 금지');
          expect(q.explanation.contains(pool[0].def), true);
        }
      }
      expect(sawFalse, true);
    });

    test('주관식: 정의가 문제, 설명에 정답 포함', () {
      final gen = QuestionGen(pool, rng: Random(3));
      final q = gen.build(pool[0], QType.shortText, isReview: false);
      expect(q.prompt, pool[0].def);
      expect(q.explanation.contains('인증'), true);
    });
  });
}

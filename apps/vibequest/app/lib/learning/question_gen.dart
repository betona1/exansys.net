import 'dart:convert';
import 'dart:math';

import '../db/database.dart';
import 'mastery.dart';

/// 세션에서 쓰는 문제 한 개.
class QuizQuestion {
  final Term term;
  final QType type;
  final String prompt;
  final List<String> options; // MCQ4 전용
  final int answerIndex; // MCQ4 전용
  final bool oxAnswer; // OX 전용
  final String explanation; // 오답 시 보여줄 교정 설명 (§8.1)
  final bool isReview;
  const QuizQuestion({
    required this.term,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.answerIndex = 0,
    this.oxAnswer = true,
    required this.explanation,
    required this.isReview,
  });
}

List<String> confusionOf(Term t) {
  try {
    return (jsonDecode(t.confusionJson) as List).cast<String>();
  } catch (_) {
    return [];
  }
}

/// 문제 생성기 — 용어 풀에서 오답을 뽑는다.
/// 오답 우선순위: confusionSet 매칭 용어 → 같은 카테고리·비슷한 난이도 (§8.2)
class QuestionGen {
  final List<Term> pool; // 전체(또는 충분히 큰) 용어 풀
  final Random rng;
  late final Map<String, Term> _byKo = {for (final t in pool) t.termKo: t};

  QuestionGen(this.pool, {Random? rng}) : rng = rng ?? Random();

  /// confusionSet 이름 → 실제 용어 (있는 것만)
  List<Term> _confusionTerms(Term t) =>
      confusionOf(t).map((n) => _byKo[n]).whereType<Term>().where((c) => c.id != t.id).toList();

  /// 오답 선택.
  /// [easy]=true (아직 익숙하지 않은 용어): 혼동쌍을 **배제**하고 다른 분야에서
  /// 명백히 다른 것을 뽑는다 — 초보자에게 함정 금지 (UX-02).
  /// [easy]=false (숙련 단계): 혼동쌍 우선 → 같은 카테고리·±1 난이도 (§8.2).
  List<Term> _distractors(Term t, int count, {required bool easy}) {
    final picked = <String>{t.id};
    final out = <Term>[];
    if (easy) {
      final confusionNames = confusionOf(t).toSet();
      final farAway = pool
          .where((p) =>
              !picked.contains(p.id) &&
              p.category != t.category && // 다른 분야 = 명백히 구별됨
              !confusionNames.contains(p.termKo) &&
              p.difficulty <= 2)
          .toList()
        ..shuffle(rng);
      for (final p in farAway) {
        if (out.length >= count) break;
        if (picked.add(p.id)) out.add(p);
      }
    } else {
      for (final c in _confusionTerms(t)) {
        if (out.length >= count) break;
        if (picked.add(c.id)) out.add(c);
      }
      if (out.length < count) {
        final sameCat = pool
            .where((p) =>
                !picked.contains(p.id) &&
                p.category == t.category &&
                (p.difficulty - t.difficulty).abs() <= 1)
            .toList()
          ..shuffle(rng);
        for (final p in sameCat) {
          if (out.length >= count) break;
          if (picked.add(p.id)) out.add(p);
        }
      }
    }
    if (out.length < count) {
      final rest = pool.where((p) => !picked.contains(p.id)).toList()..shuffle(rng);
      for (final p in rest) {
        if (out.length >= count) break;
        if (picked.add(p.id)) out.add(p);
      }
    }
    return out;
  }

  QuizQuestion build(Term t, QType type, {required bool isReview, bool easy = true}) =>
      switch (type) {
        QType.ox => _ox(t, isReview, easy),
        QType.shortText => _short(t, isReview),
        _ => _mcq4(t, isReview, easy),
      };

  /// 주관식: 정의를 보고 용어를 직접 인출 (§8.3)
  QuizQuestion _short(Term t, bool isReview) => QuizQuestion(
        term: t,
        type: QType.shortText,
        prompt: t.def,
        explanation: '${t.termKo} (${t.termEn})\n${t.def}',
        isReview: isReview,
      );

  /// O/X (§8.1). easy: O 비중 60% + X 문장은 다른 분야의 명백히 틀린 정의.
  QuizQuestion _ox(Term t, bool isReview, bool easy) {
    final useTrue = easy ? rng.nextInt(5) < 3 : rng.nextBool();
    if (useTrue) {
      return QuizQuestion(
        term: t,
        type: QType.ox,
        prompt: '‘${t.termKo}’ — ${t.def}',
        oxAnswer: true,
        explanation: '맞아요. ${t.termKo}: ${t.def}',
        isReview: isReview,
      );
    }
    final d = _distractors(t, 1, easy: easy).first;
    return QuizQuestion(
      term: t,
      type: QType.ox,
      prompt: '‘${t.termKo}’ — ${d.def}',
      oxAnswer: false,
      explanation: '이 설명은 ‘${d.termKo}’에 대한 것이에요.\n${t.termKo}: ${t.def}',
      isReview: isReview,
    );
  }

  /// 4지선다: 용어→정의 / 정의→용어 랜덤 (§8.2 변형)
  QuizQuestion _mcq4(Term t, bool isReview, bool easy) {
    final ds = _distractors(t, 3, easy: easy);
    final termToDef = rng.nextBool();
    final correct = termToDef ? t.def : t.termKo;
    final options = [correct, ...ds.map((d) => termToDef ? d.def : d.termKo)]..shuffle(rng);
    return QuizQuestion(
      term: t,
      type: QType.mcq4,
      prompt: termToDef ? '‘${t.termKo}’의 설명으로 알맞은 것은?' : t.def,
      options: options,
      answerIndex: options.indexOf(correct),
      explanation: '${t.termKo}: ${t.def}',
      isReview: isReview,
    );
  }
}

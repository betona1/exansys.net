/// 주관식 채점 (TECHSPEC §8.3)
/// 1. 정확 일치 → 2. 대소문자·공백·하이픈 무시 → 3. aliases 일치
/// 4. 오타 거리 허용 (≤4자:0, 5~8자:1, ≥9자:2)
/// 5. 의미가 다른 유사 단어는 자동 정답 처리하지 않는다.
library;

import 'dart:convert';

import '../db/database.dart';

String normalizeAnswer(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[\s\-_·.,/()]+'), '')
    .trim();

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  final cur = List<int>.filled(b.length + 1, 0);
  for (var i = 0; i < a.length; i++) {
    cur[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      cur[j + 1] = [
        cur[j] + 1,
        prev[j + 1] + 1,
        prev[j] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = List.of(cur);
  }
  return prev[b.length];
}

int _allowedDistance(int len) => len <= 4 ? 0 : (len <= 8 ? 1 : 2);

/// 용어의 정답 후보(한국어명·영문명·별칭) — 정규화된 형태
List<String> answerCandidates(Term t) {
  final list = <String>[t.termKo, t.termEn];
  try {
    list.addAll((jsonDecode(t.aliasesJson) as List).cast<String>());
  } catch (_) {/* 무시 */}
  return list.map(normalizeAnswer).where((s) => s.isNotEmpty).toSet().toList();
}

/// 채점. [otherTermNames] = 다른 용어들의 정규화된 이름 집합
/// (입력이 '다른 용어'와 정확히 일치하면 오타 허용으로도 정답 처리하지 않는다 — §8.3 5항)
bool gradeShortAnswer(String input, Term t, {Set<String>? otherTermNames}) {
  final norm = normalizeAnswer(input);
  if (norm.isEmpty) return false;
  final candidates = answerCandidates(t);
  if (candidates.contains(norm)) return true;
  // 다른 용어명과 정확히 일치 → 오답 확정
  if (otherTermNames != null && otherTermNames.contains(norm)) return false;
  // 오타 거리 허용
  for (final c in candidates) {
    if (levenshtein(norm, c) <= _allowedDistance(c.length)) return true;
  }
  return false;
}

/// 자동완성 후보 — 입력 2글자 이후 최대 5개 (§8.3)
List<String> autocomplete(String input, List<Term> pool) {
  final q = normalizeAnswer(input);
  if (q.length < 2) return [];
  final starts = <String>[];
  final contains = <String>[];
  for (final t in pool) {
    for (final name in [t.termKo, t.termEn]) {
      if (name.isEmpty) continue;
      final n = normalizeAnswer(name);
      if (n.startsWith(q)) {
        starts.add(name);
      } else if (n.contains(q)) {
        contains.add(name);
      }
    }
  }
  return <String>{...starts, ...contains}.take(5).toList();
}

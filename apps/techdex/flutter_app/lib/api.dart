import 'dart:convert';
import 'package:http/http.dart' as http;

/// TechDex 백엔드(exansys.net 워커)와 통신.
class TechdexApi {
  static const String base = 'https://techdex.exansys.net';

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$base$path'));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (body['ok'] != true) throw Exception(body['error'] ?? 'error');
    return body['data'];
  }

  static Future<TechdexStats> stats() async {
    final d = await _get('/api/techdex/stats') as Map<String, dynamic>;
    return TechdexStats.fromJson(d);
  }

  static Future<List<QuizQuestion>> quiz({
    int count = 10,
    String? collection,
    bool vibeCore = false,
    String? level,
  }) async {
    final params = <String, String>{'count': '$count'};
    if (collection != null) params['collection'] = collection;
    if (vibeCore) params['vibeCore'] = '1';
    if (level != null) params['level'] = level;
    final qs = Uri(queryParameters: params).query;
    final d = await _get('/api/techdex/quiz?$qs') as Map<String, dynamic>;
    return (d['questions'] as List)
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 오늘의 용어(데일리 챌린지) — 공개, 전원 동일 5문제
  static Future<List<QuizQuestion>> daily() async {
    final d = await _get('/api/techdex/daily') as Map<String, dynamic>;
    return (d['questions'] as List).map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<CrosswordPuzzle> crossword({
    int count = 10,
    String? collection,
    String? level,
  }) async {
    final params = <String, String>{'count': '$count'};
    if (collection != null) params['collection'] = collection;
    if (level != null) params['level'] = level;
    final qs = Uri(queryParameters: params).query;
    final d = await _get('/api/techdex/crossword?$qs') as Map<String, dynamic>;
    return CrosswordPuzzle.fromJson(d);
  }

  static Future<TermPage> terms({
    String q = '',
    String? collection,
    int limit = 60,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (q.trim().isNotEmpty) params['q'] = q.trim();
    if (collection != null) params['collection'] = collection;
    final qs = Uri(queryParameters: params).query;
    final d = await _get('/api/techdex/terms?$qs') as Map<String, dynamic>;
    return TermPage(
      total: (d['total'] as num).toInt(),
      terms: (d['terms'] as List)
          .map((e) => Term.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TechdexStats {
  final int total;
  final int vibeCore;
  final Map<String, int> byCollection;
  TechdexStats({required this.total, required this.vibeCore, required this.byCollection});
  factory TechdexStats.fromJson(Map<String, dynamic> j) {
    final by = <String, int>{};
    for (final c in (j['byCollection'] as List)) {
      by[c['collection'] as String] = (c['count'] as num).toInt();
    }
    return TechdexStats(
      total: (j['total'] as num).toInt(),
      vibeCore: (j['vibeCore'] as num).toInt(),
      byCollection: by,
    );
  }
}

class QuizQuestion {
  final String slug;
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String term;
  final String? sub;
  final String category;
  QuizQuestion({
    required this.slug,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.term,
    required this.sub,
    required this.category,
  });
  factory QuizQuestion.fromJson(Map<String, dynamic> j) {
    final reveal = j['reveal'] as Map<String, dynamic>;
    return QuizQuestion(
      slug: j['slug'] as String,
      prompt: j['prompt'] as String,
      choices: (j['choices'] as List).map((e) => e as String).toList(),
      answerIndex: (j['answerIndex'] as num).toInt(),
      term: reveal['term'] as String,
      sub: reveal['sub'] as String?,
      category: reveal['category'] as String,
    );
  }
}

class Term {
  final String term;
  final String? sub;
  final String def;
  final String collection;
  final String category;
  final bool vibeCore;
  Term({
    required this.term,
    required this.sub,
    required this.def,
    required this.collection,
    required this.category,
    required this.vibeCore,
  });
  factory Term.fromJson(Map<String, dynamic> j) => Term(
        term: j['term'] as String,
        sub: j['sub'] as String?,
        def: j['def'] as String,
        collection: j['collection'] as String,
        category: j['category'] as String,
        vibeCore: (j['vibeCore'] == true || j['vibeCore'] == 1),
      );
}

class TermPage {
  final int total;
  final List<Term> terms;
  TermPage({required this.total, required this.terms});
}

class CrosswordEntry {
  final int number;
  final int row;
  final int col;
  final String dir; // across | down
  final String answer;
  final int len;
  final String clue;
  CrosswordEntry({
    required this.number,
    required this.row,
    required this.col,
    required this.dir,
    required this.answer,
    required this.len,
    required this.clue,
  });
  factory CrosswordEntry.fromJson(Map<String, dynamic> j) => CrosswordEntry(
        number: (j['num'] as num).toInt(),
        row: (j['row'] as num).toInt(),
        col: (j['col'] as num).toInt(),
        dir: j['dir'] as String,
        answer: j['answer'] as String,
        len: (j['len'] as num).toInt(),
        clue: j['clue'] as String,
      );
}

class CrosswordPuzzle {
  final int rows;
  final int cols;
  final List<CrosswordEntry> entries;
  CrosswordPuzzle({required this.rows, required this.cols, required this.entries});
  factory CrosswordPuzzle.fromJson(Map<String, dynamic> j) => CrosswordPuzzle(
        rows: (j['rows'] as num).toInt(),
        cols: (j['cols'] as num).toInt(),
        entries: (j['entries'] as List).map((e) => CrosswordEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

const collectionLabel = {
  'ai': 'AI·앱 용어',
  'app': '앱 개발 용어',
  'vibe': '바이브코딩 용어',
  'user': '사용자 추가',
};

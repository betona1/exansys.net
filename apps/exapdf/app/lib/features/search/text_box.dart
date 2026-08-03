import 'dart:convert';
import 'dart:ui';

import '../../core/korean.dart';

/// 쪽에서 읽은 줄 하나와 그 자리.
///
/// 좌표는 **쪽 전체를 1로 본 비율**이다 (0~1). 그림을 어떤 배율로 그리든
/// 곱하기만 하면 되고, 좌우로 나눠 봐도 그대로 쓸 수 있다.
class TextBox {
  const TextBox({required this.text, required this.rect, required this.score});

  final String text;

  /// 0~1 로 정규화된 자리
  final Rect rect;

  /// 얼마나 확신하는가 (0~1)
  final double score;

  static List<TextBox> parse(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>)
            TextBox(
              text: e['text'] as String? ?? '',
              rect: _rect(e['box'] as List<dynamic>? ?? const []),
              score: ((e['score'] as num?) ?? 0).toDouble(),
            ),
      ];
    } on Object {
      // 서버가 형태를 바꿔도 앱이 죽으면 안 된다. 칠하기만 못 할 뿐이다
      return const [];
    }
  }

  static Rect _rect(List<dynamic> b) {
    if (b.length < 4) return Rect.zero;
    final v = [for (final n in b) (n as num).toDouble()];
    return Rect.fromLTRB(v[0], v[1], v[2], v[3]);
  }

  /// 이 줄에 [query] 가 들어 있는가.
  ///
  /// **띄어쓰기를 지우고 맞춘다.** PaddleOCR 은 한국어 띄어쓰기를 자주
  /// 뭉개고("수있습니다"), 사람도 검색할 때 띄어쓰기를 제각각 넣는다.
  /// 색인에서 쓰는 규칙과 같아야 결과와 칠한 자리가 어긋나지 않는다 (ADR-0003).
  bool contains(String query) {
    final q = Korean.stripSpaces(Korean.normalize(query));
    if (q.isEmpty) return false;
    return Korean.stripSpaces(Korean.normalize(text)).contains(q);
  }

  /// 이 쪽에서 [query] 가 있는 줄들만
  static List<TextBox> matches(List<TextBox> boxes, String query) =>
      [for (final b in boxes) if (b.contains(query)) b];
}

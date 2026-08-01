import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/search_hit.dart';

/// FTS5 `snippet()` 이 표식으로 감싼 구간을 강조해 그린다.
///
/// 표식은 본문에 나올 수 없는 제어문자다 (`SearchHit.highlightStart/End`).
/// `<b>` 같은 표식을 쓰면 원문에 그 글자가 있을 때 엉뚱한 곳이 강조된다.
class SnippetText extends StatelessWidget {
  const SnippetText({super.key, required this.snippet});

  final String snippet;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans(context)),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  List<InlineSpan> _spans(BuildContext context) {
    const start = SearchHit.highlightStart;
    const end = SearchHit.highlightEnd;
    final spans = <InlineSpan>[];
    var rest = snippet;

    while (true) {
      final s = rest.indexOf(start);
      if (s < 0) break;
      final e = rest.indexOf(end, s + start.length);
      if (e < 0) break;

      if (s > 0) spans.add(TextSpan(text: rest.substring(0, s)));
      spans.add(
        TextSpan(
          text: rest.substring(s + start.length, e),
          style: const TextStyle(
            // 강조는 브랜드 표현이라 앰버를 쓴다. 누르는 요소가 아니다 (BRAND.md §3.2)
            color: AppTokens.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      rest = rest.substring(e + end.length);
    }
    if (rest.isNotEmpty) spans.add(TextSpan(text: rest));
    return spans;
  }
}

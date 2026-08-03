import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../reader/widgets/rendered_page_view.dart';
import '../text_box.dart';

/// 찾은 낱말이 있는 줄을 쪽 위에 칠한다.
///
/// 낱말 하나만 정확히 칠하지 않고 **그 줄 전체**를 칠한다. PaddleOCR 이
/// 주는 좌표가 줄 단위이기 때문이다. 형광펜으로 줄을 죽 그은 모양이 되는데,
/// 눈으로 찾기에는 오히려 이쪽이 낫다.
///
/// 좌표가 없는 책(비전 모델로만 읽은 것, 글자 레이어가 원래 있는 PDF)에서는
/// 아무것도 그리지 않는다 — 조용히 없는 셈 친다.
class MatchLayer extends StatelessWidget {
  const MatchLayer({
    super.key,
    required this.slice,
    required this.boxes,
    required this.query,
    required this.currentPage,
  });

  /// 지금 보이는 조각의 좌표 정보
  final SliceMapper? slice;

  /// 쪽 번호 → 그 쪽의 줄들
  final Map<int, List<TextBox>> boxes;

  /// 찾고 있는 말. 비어 있으면 그리지 않는다
  final String query;

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final s = slice;
    if (s == null || query.trim().isEmpty) return const SizedBox.shrink();
    final lines = boxes[s.pageNumber];
    if (lines == null || lines.isEmpty) return const SizedBox.shrink();

    final hits = TextBox.matches(lines, query);
    if (hits.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _MatchPainter(slice: s, hits: hits),
        ),
      ),
    );
  }
}

class _MatchPainter extends CustomPainter {
  _MatchPainter({required this.slice, required this.hits});

  final SliceMapper slice;
  final List<TextBox> hits;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTokens.amber.withValues(alpha: 0.42)
      // 글자가 비쳐야 한다. 덮어 버리면 무엇을 찾았는지 못 읽는다
      ..blendMode = BlendMode.multiply;

    for (final hit in hits) {
      // 0~1 비율을 쪽 좌표(PDF 포인트)로 되돌린 뒤 화면 좌표로 옮긴다.
      // 조각(반쪽·크롭)에 걸치지 않는 줄은 toLocalRect 가 null 을 준다
      final page = Rect.fromLTRB(
        hit.rect.left * slice.pageSize.width,
        hit.rect.top * slice.pageSize.height,
        hit.rect.right * slice.pageSize.width,
        hit.rect.bottom * slice.pageSize.height,
      );
      final local = slice.toLocalRect(page);
      if (local == null) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(local.inflate(1.5), const Radius.circular(3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MatchPainter old) =>
      old.hits.length != hits.length || old.slice != slice;
}

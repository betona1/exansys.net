import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/annotation.dart';
import '../../reader/widgets/rendered_page_view.dart';

/// 지금 보이는 조각 위에 하이라이트를 그리고, 새로 긋게 한다.
///
/// 글자 선택이 없으므로 **영역**으로 잡는다. 스캔본에는 글자 레이어가 없어
/// 텍스트 범위 하이라이트가 애초에 성립하지 않는다.
class HighlightLayer extends StatefulWidget {
  const HighlightLayer({
    super.key,
    required this.slice,
    required this.highlights,
    required this.drawing,
    required this.colorSlot,
    required this.onAdd,
    required this.onTapHighlight,
  });

  /// 지금 보이는 조각의 좌표 정보. 없으면 아직 그릴 수 없다
  final SliceMapper? slice;

  final List<Highlight> highlights;

  /// 새로 긋는 중인가 (하이라이트 모드)
  final bool drawing;

  /// 새로 그을 색 슬롯 (1~5)
  final int colorSlot;

  /// 쪽 좌표로 넘긴다
  final void Function(Rect pageRect) onAdd;

  final void Function(Highlight) onTapHighlight;

  @override
  State<HighlightLayer> createState() => _HighlightLayerState();
}

class _HighlightLayerState extends State<HighlightLayer> {
  Offset? _start;
  Offset? _current;

  Rect? get _pending =>
      (_start != null && _current != null) ? Rect.fromPoints(_start!, _current!) : null;

  @override
  Widget build(BuildContext context) {
    final slice = widget.slice;
    if (slice == null) return const SizedBox.shrink();

    // 이 조각에 걸치는 것만 화면 좌표로 옮긴다
    final drawn = <(Highlight, Rect)>[];
    for (final h in widget.highlights) {
      if (h.pageNo != slice.pageNumber) continue;
      final r = slice.toLocalRect(h.rect);
      if (r != null) drawn.add((h, r));
    }

    final painter = CustomPaint(
      size: Size.infinite,
      painter: _HighlightPainter(
        rects: drawn.map((e) => (e.$2, AppTokens.highlights[e.$1.colorSlot - 1])).toList(),
        pending: _pending,
        pendingColor: AppTokens.highlights[widget.colorSlot - 1],
      ),
    );

    if (!widget.drawing) {
      // 평소에는 그림만 얹고 탭으로 고른다. 넘기기를 방해하면 안 된다
      return Positioned.fill(
        child: Stack(
          children: [
            IgnorePointer(child: painter),
            for (final (h, r) in drawn)
              Positioned.fromRect(
                rect: r,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onTapHighlight(h),
                ),
              ),
          ],
        ),
      );
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => setState(() {
          _start = d.localPosition;
          _current = d.localPosition;
        }),
        onPanUpdate: (d) => setState(() => _current = d.localPosition),
        onPanEnd: (_) {
          final r = _pending;
          setState(() {
            _start = null;
            _current = null;
          });
          if (r == null || r.width < 8 || r.height < 8) return;
          final pageRect = slice.toPageRect(r);
          if (pageRect != null) widget.onAdd(pageRect);
        },
        child: painter,
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({required this.rects, this.pending, required this.pendingColor});

  final List<(Rect, Color)> rects;
  final Rect? pending;
  final Color pendingColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (r, color) in rects) {
      // 글자가 비쳐야 하므로 반투명으로 곱한다
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()
          ..color = color.withValues(alpha: 0.38)
          ..blendMode = BlendMode.multiply,
      );
    }
    if (pending != null) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(pending!, const Radius.circular(3)),
          Paint()..color = pendingColor.withValues(alpha: 0.45),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(pending!, const Radius.circular(3)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = pendingColor,
        );
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.pending != pending || old.rects.length != rects.length || old.pendingColor != pendingColor;
}

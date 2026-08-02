import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/annotation.dart';
import '../../reader/widgets/rendered_page_view.dart';

/// 지금 보이는 조각 위에 하이라이트를 그리고, 새로 긋게 한다.
///
/// 글자 선택이 없으므로 **영역**으로 잡는다. 스캔본에는 글자 레이어가 없어
/// 텍스트 범위 하이라이트가 애초에 성립하지 않는다.
///
/// 잘못 칠한 것을 지우는 길은 **누르면 그 자리에서** 열린다. 예전에는 화면
/// 아래에서 시트가 올라왔는데, 어느 것을 누른 건지 보이지 않아 헷갈렸다.
/// 이제는 고른 것에 테두리가 생기고 바로 옆에 작은 막대가 뜬다 —
/// 색 다섯 개, 메모, 휴지통. 키보드가 있으면 Del 로도 지운다.
class HighlightLayer extends StatefulWidget {
  const HighlightLayer({
    super.key,
    required this.slice,
    required this.highlights,
    required this.drawing,
    required this.colorSlot,
    required this.selectedId,
    required this.onAdd,
    required this.onSelect,
    required this.onRecolor,
    required this.onNote,
    required this.onDelete,
  });

  /// 지금 보이는 조각의 좌표 정보. 없으면 아직 그릴 수 없다
  final SliceMapper? slice;

  final List<Highlight> highlights;

  /// 새로 긋는 중인가 (하이라이트 모드)
  final bool drawing;

  /// 새로 그을 색 슬롯 (1~5)
  final int colorSlot;

  /// 지금 고른 하이라이트. 없으면 null
  final int? selectedId;

  /// 쪽 좌표로 넘긴다
  final void Function(Rect pageRect) onAdd;

  /// 고르거나(누름) 품(빈 곳을 누름)
  final void Function(Highlight?) onSelect;

  final void Function(Highlight, int slot) onRecolor;
  final void Function(Highlight) onNote;
  final void Function(Highlight) onDelete;

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

    final selected = drawn.where((e) => e.$1.id == widget.selectedId).firstOrNull;

    final painter = CustomPaint(
      size: Size.infinite,
      painter: _HighlightPainter(
        rects: drawn.map((e) => (e.$2, AppTokens.highlights[e.$1.colorSlot - 1])).toList(),
        selected: selected?.$2,
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
            // 고른 것이 있을 때만 빈 곳을 받는다. 늘 깔아 두면 쪽 넘기기가 죽는다
            if (selected != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onSelect(null),
                ),
              ),
            for (final (h, r) in drawn)
              Positioned.fromRect(
                rect: r,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onSelect(h.id == widget.selectedId ? null : h),
                ),
              ),
            if (selected != null)
              _HighlightPopover(
                anchor: selected.$2,
                highlight: selected.$1,
                onRecolor: (slot) => widget.onRecolor(selected.$1, slot),
                onNote: () => widget.onNote(selected.$1),
                onDelete: () => widget.onDelete(selected.$1),
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

/// 고른 하이라이트 옆에 뜨는 작은 막대.
///
/// 위에 자리가 있으면 위로, 없으면 아래로 붙인다. 좌우로도 화면 밖을
/// 넘지 않게 민다 — 가장자리에 칠한 것을 골랐을 때 막대가 잘리면 못 지운다.
class _HighlightPopover extends StatelessWidget {
  const _HighlightPopover({
    required this.anchor,
    required this.highlight,
    required this.onRecolor,
    required this.onNote,
    required this.onDelete,
  });

  final Rect anchor;
  final Highlight highlight;
  final void Function(int slot) onRecolor;
  final VoidCallback onNote;
  final VoidCallback onDelete;

  static const _height = 44.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // 색 5개 + 메모 + 휴지통. 손가락으로 누를 수 있는 크기(44)를 지킨다
        const width = 5 * 34.0 + 2 * 44.0 + 16;
        final above = anchor.top - _height - _gap;
        final top = above >= 0 ? above : (anchor.bottom + _gap).clamp(0.0, c.maxHeight - _height);
        final left = (anchor.center.dx - width / 2).clamp(
          AppTokens.space2,
          (c.maxWidth - width - AppTokens.space2).clamp(AppTokens.space2, double.infinity),
        );

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: _height,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: AppTokens.space2),
                for (var slot = 1; slot <= AppTokens.highlights.length; slot++)
                  _Dot(
                    color: AppTokens.highlights[slot - 1],
                    selected: slot == highlight.colorSlot,
                    onTap: () => onRecolor(slot),
                  ),
                IconButton(
                  onPressed: onNote,
                  tooltip: '메모',
                  iconSize: 20,
                  icon: Icon(
                    highlight.note == null ? Icons.edit_note : Icons.sticky_note_2,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: '삭제 (Del)',
                  iconSize: 20,
                  color: Theme.of(context).colorScheme.error,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: SizedBox(
        width: 34,
        height: 44,
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                  : Border.all(color: Colors.black12),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.rects,
    required this.selected,
    this.pending,
    required this.pendingColor,
  });

  final List<(Rect, Color)> rects;

  /// 고른 것의 자리. 테두리를 둘러 어느 것을 고른 건지 보이게 한다
  final Rect? selected;
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
    if (selected != null) {
      // 어두운 쪽·밝은 쪽 어디서든 보이도록 흰 테두리 위에 검은 점선을 얹는다
      final rr = RRect.fromRectAndRadius(selected!.inflate(2), const Radius.circular(5));
      canvas
        ..drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white,
        )
        ..drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = AppTokens.action,
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
      old.pending != pending ||
      old.selected != selected ||
      old.rects.length != rects.length ||
      old.pendingColor != pendingColor;
}

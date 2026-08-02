import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 캡처 모드에서 화면 위에 덮는 층.
///
/// 드래그로 사각형을 그리면 그 영역을 알려 준다. 좌표는 이 위젯 기준의
/// 로컬 좌표이므로, 받는 쪽에서 전역 좌표로 바꿔 문서 좌표로 옮긴다.
class CaptureOverlay extends StatefulWidget {
  const CaptureOverlay({
    super.key,
    required this.onCapture,
    required this.onCancel,
    this.busy = false,
  });

  /// 드래그가 끝났을 때. 사각형은 이 위젯의 로컬 좌표.
  final void Function(Rect localRect) onCapture;

  final VoidCallback onCancel;

  /// 캡처를 처리하는 중이면 새 드래그를 막는다.
  final bool busy;

  @override
  State<CaptureOverlay> createState() => _CaptureOverlayState();
}

class _CaptureOverlayState extends State<CaptureOverlay> {
  Offset? _start;
  Offset? _current;

  Rect? get _rect => (_start != null && _current != null) ? Rect.fromPoints(_start!, _current!) : null;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.busy ? null : (d) => setState(() {
          _start = d.localPosition;
          _current = d.localPosition;
        }),
        onPanUpdate: widget.busy ? null : (d) => setState(() => _current = d.localPosition),
        onPanEnd: widget.busy
            ? null
            : (_) {
                final r = _rect;
                setState(() {
                  _start = null;
                  _current = null;
                });
                if (r != null && r.width >= 8 && r.height >= 8) widget.onCapture(r);
              },
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _CapturePainter(_rect)),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Material(
                color: AppTokens.action.withValues(alpha: 0.94),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.crop_free, color: Colors.black87, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.busy ? '잘라내는 중…' : '잘라 낼 곳을 드래그하세요',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(foregroundColor: Colors.black87),
                          child: const Text('취소'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _CapturePainter extends CustomPainter {
  _CapturePainter(this.rect);

  final Rect? rect;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.45);

    if (rect == null) {
      canvas.drawRect(full, dim);
      return;
    }
    // 고른 영역만 밝게 — 바깥쪽에만 어둠을 칠한다
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, dim);
    canvas.drawRect(rect!, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.drawRect(
      rect!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTokens.action,
    );
    // 모서리 손잡이
    const len = 14.0;
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppTokens.action;
    for (final (corner, dx, dy) in [
      (rect!.topLeft, 1.0, 1.0),
      (rect!.topRight, -1.0, 1.0),
      (rect!.bottomLeft, 1.0, -1.0),
      (rect!.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(len * dx, 0), handle);
      canvas.drawLine(corner, corner.translate(0, len * dy), handle);
    }
  }

  @override
  bool shouldRepaint(_CapturePainter old) => old.rect != rect;
}

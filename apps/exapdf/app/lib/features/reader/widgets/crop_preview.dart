import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/crop_rect.dart';

/// 크롭 조정용 미리보기.
///
/// 쪽 **전체**를 낮은 해상도로 한 번만 그려 두고, 잘라 낼 자리를 그 위에 겹쳐 보여 준다.
/// 슬라이더를 움직일 때마다 다시 렌더하면 손맛이 죽는다.
class CropPreview extends StatefulWidget {
  const CropPreview({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.crop,
    this.showGuides = true,
  });

  final PdfDocument document;
  final int pageNumber;
  final CropRect crop;

  /// 크롭이 꺼져 있으면 안내선을 흐리게 둔다
  final bool showGuides;

  @override
  State<CropPreview> createState() => _CropPreviewState();
}

class _CropPreviewState extends State<CropPreview> {
  ui.Image? _image;
  int? _loadedPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CropPreview old) {
    super.didUpdateWidget(old);
    if (old.pageNumber != widget.pageNumber) _load();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pageNo = widget.pageNumber;
    if (_loadedPage == pageNo) return;
    final page = widget.document.pages[pageNo - 1];
    const w = 420;
    final h = (w * page.height / page.width).round().clamp(8, 4000);
    final img = await page.render(
      width: w,
      height: h,
      fullWidth: w.toDouble(),
      fullHeight: h.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    if (img == null) return;
    final ui.Image decoded;
    try {
      decoded = await img.createImage();
    } finally {
      img.dispose();
    }
    if (!mounted) {
      decoded.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = decoded;
      _loadedPage = pageNo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const ColoredBox(color: AppTokens.slot);

    return Center(
      child: AspectRatio(
        aspectRatio: image.width / image.height,
        child: CustomPaint(
          painter: _CropPainter(image: image, crop: widget.crop, strong: widget.showGuides),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({required this.image, required this.crop, required this.strong});

  final ui.Image image;
  final CropRect crop;
  final bool strong;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );

    final keep = Rect.fromLTWH(
      crop.left * size.width,
      crop.top * size.height,
      crop.widthRatio * size.width,
      crop.heightRatio * size.height,
    );

    // 잘려 나갈 바깥쪽을 어둡게 — 남는 곳이 아니라 버리는 곳을 표시한다
    canvas
      ..saveLayer(dst, Paint())
      ..drawRect(dst, Paint()..color = Colors.black.withValues(alpha: strong ? 0.55 : 0.2))
      ..drawRect(keep, Paint()..blendMode = BlendMode.clear)
      ..restore()
      ..drawRect(
        keep,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          // 안내선은 기능색이 아니라 표시라 앰버를 쓴다 (BRAND.md §3.2)
          ..color = strong ? AppTokens.amber : AppTokens.amber.withValues(alpha: 0.5),
      );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.crop != crop || old.strong != strong;
}

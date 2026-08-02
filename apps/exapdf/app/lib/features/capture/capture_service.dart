import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// 캡처 한 장의 결과.
class CaptureResult {
  const CaptureResult({required this.file, required this.pageNumber});

  final File file;
  final int pageNumber;
}

/// 쪽의 한 영역을 잘라 이미지로 저장한다.
///
/// 화면을 그대로 찍지 않고 **원본 쪽을 그 영역만 고해상도로 다시 렌더한다.**
/// 화면 캡처는 기기 해상도에 묶여 확대하면 뭉개지지만, 이렇게 하면 글자가 선명하다.
///
/// 저장 위치는 **앱 전용 폴더**다 (확정 사항). 사용자의 사진 갤러리를 어지럽히지
/// 않고, 저장소 권한도 필요 없다. 갤러리로 보내려면 공유 버튼을 쓴다.
class CaptureService {
  /// 출력 해상도(dpi). techspec §9 는 150/300/600 선택을 요구한다 —
  /// 지금은 기본값 300 고정이고, 선택 UI 는 아직 없다.
  static const int dpi = 300;

  /// PDF 좌표는 72dpi 기준이므로 배율은 dpi/72 다.
  static const double renderScale = dpi / 72;

  /// 앱 전용 캡처 폴더. 없으면 만든다.
  static Future<Directory> captureDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}captures');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// [page] 의 [rect] 영역을 잘라 PNG 로 저장한다.
  ///
  /// [rect] 은 쪽 좌표계(PDF 포인트, 왼쪽 위 원점)로 준다.
  /// [sourceLabel] 을 주면 이미지 아래에 출처 띠를 붙인다.
  static Future<CaptureResult> capture({
    required PdfPage page,
    required Rect rect,
    required String bookTitle,
    String? sourceLabel,
  }) async {
    // 쪽 밖으로 나간 영역은 잘라 낸다 — 안 그러면 렌더가 빈 띠를 만든다.
    final clipped = rect.intersect(Rect.fromLTWH(0, 0, page.width, page.height));
    if (clipped.width < 4 || clipped.height < 4) {
      throw const CaptureTooSmall();
    }

    final full = Size(page.width * renderScale, page.height * renderScale);
    final image = await page.render(
      x: (clipped.left * renderScale).round(),
      y: (clipped.top * renderScale).round(),
      width: (clipped.width * renderScale).round(),
      height: (clipped.height * renderScale).round(),
      fullWidth: full.width,
      fullHeight: full.height,
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) throw const CaptureFailed('쪽을 그리지 못했습니다');

    ui.Image rendered;
    try {
      rendered = await image.createImage();
    } finally {
      image.dispose();
    }

    final Uint8List bytes;
    try {
      bytes = await _encode(rendered, sourceLabel);
    } finally {
      rendered.dispose();
    }

    final dir = await captureDir();
    final stamp = DateTime.now();
    final name = '${_safeName(bookTitle)}_p${page.pageNumber}_${_stamp(stamp)}.png';
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return CaptureResult(file: file, pageNumber: page.pageNumber);
  }

  /// 잘라 낸 이미지에 출처 띠를 붙여 PNG 바이트로 만든다.
  static Future<Uint8List> _encode(ui.Image src, String? sourceLabel) async {
    if (sourceLabel == null || sourceLabel.isEmpty) {
      final data = await src.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    }

    final pad = (src.width * 0.022).clamp(10.0, 40.0);
    final painter = TextPainter(
      text: TextSpan(
        text: sourceLabel,
        style: TextStyle(
          color: const Color(0xFF5A6A80),
          fontSize: (src.width * 0.026).clamp(11.0, 34.0),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: src.width - pad * 2);

    final barHeight = painter.height + pad * 1.4;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final totalHeight = src.height + barHeight;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, src.width.toDouble(), totalHeight),
      Paint()..color = Colors.white,
    );
    canvas.drawImage(src, Offset.zero, Paint());
    canvas.drawLine(
      Offset(pad, src.height + 0.5),
      Offset(src.width - pad, src.height + 0.5),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1,
    );
    painter.paint(canvas, Offset(pad, src.height + pad * 0.7));

    final composed = await recorder.endRecording().toImage(src.width, totalHeight.round());
    try {
      final data = await composed.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      composed.dispose();
    }
  }

  static String _safeName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    return cleaned.isEmpty ? 'capture' : cleaned.substring(0, cleaned.length.clamp(0, 40));
  }

  static String _stamp(DateTime t) {
    two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }
}

class CaptureTooSmall implements Exception {
  const CaptureTooSmall();
  @override
  String toString() => '캡처 영역이 너무 작습니다';
}

class CaptureFailed implements Exception {
  const CaptureFailed(this.message);
  final String message;
  @override
  String toString() => message;
}

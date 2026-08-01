import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../../domain/entities/crop_rect.dart';

/// 자동 여백 감지.
///
/// 쪽을 **낮은 해상도로** 그린 뒤 흰 배경이 아닌 픽셀의 바운딩 박스를 찾는다.
/// 원본 해상도로 하면 300쪽 문서에서 몇 십 초가 걸린다.
///
/// **홀수 쪽과 짝수 쪽을 따로 계산한다.** 제본 여백(안쪽 여백)이 좌우로 번갈아
/// 나타나므로 하나로 합치면 한쪽이 잘리거나 여백이 남는다 (SPEC §2.1).
abstract final class CropDetector {
  /// 감지에 쓸 렌더 폭(px). 여백 판정에는 이 정도면 충분하다
  static const _probeWidth = 160;

  /// 흰색으로 볼 밝기 임계값. 스캔본은 완전한 흰색이 아니라 살짝 회색이다
  static const _whiteThreshold = 238;

  /// 잡티 한 점 때문에 여백이 0 이 되지 않도록, 한 줄에서 이만큼은
  /// 어두워야 "내용이 있다"고 본다.
  ///
  /// 비율만 쓰면 안 된다 — 감지용 렌더가 160px 라 비율이 1 픽셀 미만으로 떨어지고,
  /// `ceil()` 때문에 결국 "1 픽셀만 있어도 내용"이 되어 노이즈 제거가 전혀 안 된다.
  /// 스캔본에는 먼지 점이 흔해서 그러면 크롭이 통째로 무력해진다.
  static const _inkRatio = 0.01;
  static const _minInkPixels = 2;

  /// 잘라 낸 자리가 딱 붙지 않도록 남기는 여유. 글자가 살짝 잘리는 것을 막는다
  static const _padding = 0.012;

  /// 문서에서 몇 쪽을 표본으로 볼지. 전부 보면 느리고, 한 쪽만 보면 튄다
  static const _samplesPerSide = 5;

  /// 홀수 쪽·짝수 쪽 여백을 각각 구한다.
  ///
  /// 표본 여러 쪽에서 구한 값 중 **가장 보수적인 것**(가장 적게 자르는 값)을 쓴다.
  /// 평균을 쓰면 표제지처럼 여백이 큰 쪽 때문에 본문 쪽의 글자가 잘린다.
  static Future<({CropRect odd, CropRect even})> detect(PdfDocument doc) async {
    final oddPages = <int>[];
    final evenPages = <int>[];
    for (var i = 1; i <= doc.pages.length; i++) {
      // 앞뒤 표지·간지는 여백 판단을 흐린다. 가운데 쪽들을 본다
      if (i <= 2 || i > doc.pages.length - 2) continue;
      (i.isOdd ? oddPages : evenPages).add(i);
    }

    Future<CropRect> forSide(List<int> pages) async {
      if (pages.isEmpty) return CropRect.none;
      final step = (pages.length / _samplesPerSide).ceil().clamp(1, pages.length);
      final found = <CropRect>[];
      for (var i = 0; i < pages.length && found.length < _samplesPerSide; i += step) {
        final rect = await detectPage(doc.pages[pages[i] - 1]);
        if (rect != null && !rect.isEmpty) found.add(rect);
      }
      if (found.isEmpty) return CropRect.none;
      return CropRect(
        left: found.map((r) => r.left).reduce((a, b) => a < b ? a : b),
        top: found.map((r) => r.top).reduce((a, b) => a < b ? a : b),
        right: found.map((r) => r.right).reduce((a, b) => a < b ? a : b),
        bottom: found.map((r) => r.bottom).reduce((a, b) => a < b ? a : b),
      );
    }

    return (odd: await forSide(oddPages), even: await forSide(evenPages));
  }

  /// 쪽 하나의 여백. 내용을 못 찾으면 null
  static Future<CropRect?> detectPage(PdfPage page) async {
    final w = _probeWidth;
    final h = (w * page.height / page.width).round().clamp(8, 4000);
    final image = await page.render(
      width: w,
      height: h,
      fullWidth: w.toDouble(),
      fullHeight: h.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) return null;
    try {
      return _boundingBox(image.pixels, image.width, image.height);
    } finally {
      image.dispose();
    }
  }

  /// BGRA8888 픽셀에서 내용의 바운딩 박스를 찾아 여백 비율로 돌려준다.
  ///
  /// 화면에 그리지 않고 계산만 하므로 테스트에서 바로 부를 수 있다.
  static CropRect? _boundingBox(Uint8List pixels, int width, int height) {
    int threshold(int len) {
      final byRatio = (len * _inkRatio).ceil();
      return byRatio > _minInkPixels ? byRatio : _minInkPixels;
    }

    final rowThreshold = threshold(width);
    final colThreshold = threshold(height);

    bool rowHasInk(int y) {
      var ink = 0;
      for (var x = 0; x < width; x++) {
        if (_isInk(pixels, (y * width + x) * 4)) {
          ink++;
          if (ink >= rowThreshold) return true;
        }
      }
      return false;
    }

    bool colHasInk(int x) {
      var ink = 0;
      for (var y = 0; y < height; y++) {
        if (_isInk(pixels, (y * width + x) * 4)) {
          ink++;
          if (ink >= colThreshold) return true;
        }
      }
      return false;
    }

    var top = 0;
    while (top < height && !rowHasInk(top)) {
      top++;
    }
    if (top >= height) return null; // 빈 쪽

    var bottom = height - 1;
    while (bottom > top && !rowHasInk(bottom)) {
      bottom--;
    }
    var left = 0;
    while (left < width && !colHasInk(left)) {
      left++;
    }
    var right = width - 1;
    while (right > left && !colHasInk(right)) {
      right--;
    }

    return _withPadding(
      CropRect(
        left: left / width,
        top: top / height,
        right: (width - 1 - right) / width,
        bottom: (height - 1 - bottom) / height,
      ),
    );
  }

  /// 여유를 빼고, 한쪽으로 절반 넘게 자르지 않도록 막는다
  static CropRect _withPadding(CropRect r) {
    double trim(double v) => (v - _padding).clamp(0.0, 0.45);
    return CropRect(
      left: trim(r.left),
      top: trim(r.top),
      right: trim(r.right),
      bottom: trim(r.bottom),
    );
  }

  static bool _isInk(Uint8List px, int i) {
    // BGRA — 밝기만 본다. 색보다 어두운지가 기준이다
    final b = px[i];
    final g = px[i + 1];
    final r = px[i + 2];
    return ((r + g + b) ~/ 3) < _whiteThreshold;
  }

  /// 테스트용 — 픽셀 배열에서 바로 계산한다
  static CropRect? boundingBoxForTest(Uint8List pixels, int width, int height) =>
      _boundingBox(pixels, width, height);
}

import 'dart:typed_data';

import '../../core/reading_filter.dart';

/// 쪽 그림 한 장을 다크 리딩용으로 바꾸는 데 필요한 값들.
///
/// `compute()` 로 아이솔레이트에 넘기므로 단순한 값만 담는다 (CLAUDE.md §5 —
/// 렌더·파싱은 UI 스레드를 막지 않는다).
class TintRequest {
  const TintRequest({
    required this.pixels,
    required this.mode,
    this.brightness = 1,
    this.contrast = 1,
  });

  /// BGRA8888 원본. 아이솔레이트로 넘어가며 소유권도 넘어간다
  final Uint8List pixels;
  final DarkImageMode mode;
  final double brightness;
  final double contrast;
}

/// 다크 리딩 픽셀 변환.
///
/// `compute()` 에 넘기려면 최상위 함수여야 한다.
///
/// **단순 반전(`1-x`)을 쓰지 않는다.** 사진이 네거티브가 되고 색이 보색으로 뒤집힌다.
/// 대신 **휘도만 뒤집는다** — 흰 종이는 검게, 검은 글자는 희게 가면서 색조는 남는다.
///
/// `preserve` 모드는 **채도로 사진을 가려낸다.** pdfrx 가 이미지 객체 좌표를 주지 않아
/// (텍스트·링크만 준다) 어디가 사진인지 알 수 없기 때문이다.
/// 회색에 가까운 픽셀(= 스캔한 글자·선)은 뒤집고, 색이 뚜렷한 픽셀(= 사진·그림)은
/// 밝기만 낮춰 그대로 둔다. 흑백 스캔 책에서는 전부 뒤집히고, 컬러 도판은 살아남는다.
Uint8List tintPage(TintRequest req) {
  final px = req.pixels;
  final invert = ReadingFilter.luminanceInvert();
  final needsBc = req.brightness != 1 || req.contrast != 1;
  final bc = needsBc
      ? ReadingFilter.brightnessContrast(brightness: req.brightness, contrast: req.contrast)
      : null;

  // 사진으로 볼 채도 문턱. 종이 누런빛·잉크 번짐은 이보다 낮다
  const colorThreshold = 46;

  // 사진을 그대로 두면 다크 화면에서 혼자 눈부시다. 조금 낮춘다
  const photoDim = 0.78;

  for (var i = 0; i < px.length; i += 4) {
    final b = px[i];
    final g = px[i + 1];
    final r = px[i + 2];

    var nr = r;
    var ng = g;
    var nb = b;

    var treatAsPhoto = false;
    if (req.mode == DarkImageMode.preserve) {
      final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
      treatAsPhoto = (max - min) > colorThreshold;
    }

    if (req.mode == DarkImageMode.dim || treatAsPhoto) {
      final f = req.mode == DarkImageMode.dim ? 0.62 : photoDim;
      nr = (r * f).round();
      ng = (g * f).round();
      nb = (b * f).round();
    } else {
      final out = ReadingFilter.apply(invert, r, g, b);
      nr = out.$1;
      ng = out.$2;
      nb = out.$3;
    }

    if (bc != null) {
      final out = ReadingFilter.apply(bc, nr, ng, nb);
      nr = out.$1;
      ng = out.$2;
      nb = out.$3;
    }

    px[i] = nb;
    px[i + 1] = ng;
    px[i + 2] = nr;
  }
  return px;
}

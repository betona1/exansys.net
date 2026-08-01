import 'dart:ui' as ui;

/// 다크 리딩에서 이미지(사진·그림)를 어떻게 다룰지 (techspec §8).
enum DarkImageMode {
  /// 전체 반전 — 사진이 네거티브가 된다
  invert,

  /// 이미지 원본 유지 (기본값) — 색이 있는 부분은 그대로 두고 글자만 반전
  preserve,

  /// 이미지 살짝 어둡게 — 반전하지 않고 밝기만 낮춘다
  dim;

  static DarkImageMode parse(String? v) => switch (v) {
    'invert' => DarkImageMode.invert,
    'dim' => DarkImageMode.dim,
    _ => DarkImageMode.preserve,
  };

  String get storageValue => name;
}

/// 쪽 그림에 씌울 색 변환.
///
/// **단순 반전은 쓰지 않는다.** `1 - x` 로 뒤집으면 사진이 네거티브가 되고
/// 색상이 보색으로 바뀐다. 조사한 뷰어들의 최대 불만 지점이다 (techspec §8).
///
/// 대신 **휘도(L)만 뒤집고 색상은 남긴다**:
///
///     C' = C - 2L + 1        (L = 0.2126R + 0.7152G + 0.0722B)
///
/// 흰 종이는 검게, 검은 글자는 희게 가면서 색 있는 부분은 색조를 유지한다.
/// 이것은 선형 변환이라 GPU 의 `ColorFilter.matrix` 한 번으로 끝난다.
abstract final class ReadingFilter {
  // ITU-R BT.709 휘도 계수
  static const _lr = 0.2126;
  static const _lg = 0.7152;
  static const _lb = 0.0722;

  /// 휘도 반전 행렬 (4×5, 0~255 기준)
  static List<double> luminanceInvert() => [
    1 - 2 * _lr, -2 * _lg, -2 * _lb, 0, 255,
    -2 * _lr, 1 - 2 * _lg, -2 * _lb, 0, 255,
    -2 * _lr, -2 * _lg, 1 - 2 * _lb, 0, 255,
    0, 0, 0, 1, 0,
  ];

  /// 밝기·대비. [brightness] 1.0 이 원래, [contrast] 1.0 이 원래
  static List<double> brightnessContrast({double brightness = 1, double contrast = 1}) {
    // 대비는 중간값(128) 기준으로 벌린다. 0 기준으로 하면 어두운 쪽이 뭉갠다
    final s = contrast * brightness;
    final t = (128 * (1 - contrast)) * brightness;
    return [s, 0, 0, 0, t, 0, s, 0, 0, t, 0, 0, s, 0, t, 0, 0, 0, 1, 0];
  }

  /// 세피아 — 눈이 덜 피로한 종이색
  static List<double> sepia() => [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// 밝기만 낮춘다 (`dim` 모드)
  static List<double> dim(double factor) => brightnessContrast(brightness: factor);

  /// 행렬 두 개를 이어 붙인다. `second(first(color))` 순서다.
  static List<double> compose(List<double> first, List<double> second) {
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += second[row * 5 + k] * first[k * 5 + col];
        }
        // 상수항(5열)은 second 의 오프셋도 더해진다
        if (col == 4) sum += second[row * 5 + 4];
        out[row * 5 + col] = sum;
      }
    }
    return out;
  }

  /// 행렬을 색 하나에 적용한다. 테스트와 CPU 경로에서 쓴다.
  static (int r, int g, int b) apply(List<double> m, int r, int g, int b) {
    int ch(int i) {
      final v = m[i * 5] * r + m[i * 5 + 1] * g + m[i * 5 + 2] * b + m[i * 5 + 4];
      return v < 0 ? 0 : (v > 255 ? 255 : v.round());
    }

    return (ch(0), ch(1), ch(2));
  }

  static ui.ColorFilter toColorFilter(List<double> matrix) => ui.ColorFilter.matrix(matrix);

  /// 설정을 하나의 행렬로 만든다. 필요 없으면 null
  ///
  /// [invert] 가 true 면 휘도 반전을 먼저 하고, 그 위에 밝기·대비를 얹는다.
  static List<double>? build({
    bool invert = false,
    bool sepiaTone = false,
    double brightness = 1,
    double contrast = 1,
  }) {
    List<double>? m;
    if (invert) m = luminanceInvert();
    if (sepiaTone) m = m == null ? sepia() : compose(m, sepia());
    if (brightness != 1 || contrast != 1) {
      final bc = brightnessContrast(brightness: brightness, contrast: contrast);
      m = m == null ? bc : compose(m, bc);
    }
    return m;
  }
}

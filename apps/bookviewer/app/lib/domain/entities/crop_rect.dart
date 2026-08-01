import 'dart:convert';

/// 쪽에서 잘라 낼 여백. 각 값은 **쪽 크기에 대한 비율**(0.0~0.49)이다.
///
/// 비율로 두는 이유: 쪽 크기가 제각각인 문서에서도 같은 값이 통하고,
/// 확대 배율이 바뀌어도 다시 계산할 필요가 없다.
class CropRect {
  const CropRect({this.left = 0, this.top = 0, this.right = 0, this.bottom = 0});

  final double left;
  final double top;
  final double right;
  final double bottom;

  static const none = CropRect();

  bool get isEmpty => left <= 0 && top <= 0 && right <= 0 && bottom <= 0;

  /// 남는 영역의 가로/세로 비율
  double get widthRatio => (1 - left - right).clamp(0.05, 1.0);
  double get heightRatio => (1 - top - bottom).clamp(0.05, 1.0);

  CropRect copyWith({double? left, double? top, double? right, double? bottom}) => CropRect(
    left: left ?? this.left,
    top: top ?? this.top,
    right: right ?? this.right,
    bottom: bottom ?? this.bottom,
  );

  /// 쪽 안의 실제 좌표로 바꾼다 (PDF 포인트)
  ({double x, double y, double w, double h}) toPageRect(double pageWidth, double pageHeight) => (
    x: left * pageWidth,
    y: top * pageHeight,
    w: widthRatio * pageWidth,
    h: heightRatio * pageHeight,
  );

  String toJson() => jsonEncode([left, top, right, bottom]);

  static CropRect? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      if (list.length != 4) return null;
      return CropRect(
        left: (list[0] as num).toDouble(),
        top: (list[1] as num).toDouble(),
        right: (list[2] as num).toDouble(),
        bottom: (list[3] as num).toDouble(),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CropRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

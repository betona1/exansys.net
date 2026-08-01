import 'crop_rect.dart';

/// 문서별 뷰어 설정 (화면이 쓰는 형태).
///
/// 크롭·줌·테마를 책마다 기억한다. 없으면 열 때마다 다시 맞춰야 해서
/// 크롭 같은 기능이 사실상 무용지물이 된다.
class ReaderSettings {
  const ReaderSettings({
    this.splitPages = false,
    this.splitRightToLeft = false,
    this.splitPrompted = false,
    this.cropEnabled = false,
    this.cropOdd,
    this.cropEven,
    this.cropPrompted = false,
  });

  /// 한 장에 든 두 쪽을 좌·우로 나눠 본다
  final bool splitPages;

  /// 나눌 때 오른쪽 반쪽을 먼저 읽는가
  final bool splitRightToLeft;

  /// 좌우 분할을 이미 권해 봤는가
  final bool splitPrompted;

  /// 자동 여백 크롭 사용
  final bool cropEnabled;

  /// 홀수/짝수 쪽 여백. 제본 여백이 좌우로 번갈아 나오므로 따로 둔다
  final CropRect? cropOdd;
  final CropRect? cropEven;

  /// 크롭을 이미 권해 봤는가
  final bool cropPrompted;

  /// 쪽 번호(1부터)에 맞는 여백
  CropRect cropFor(int pageNumber) {
    if (!cropEnabled) return CropRect.none;
    return (pageNumber.isOdd ? cropOdd : cropEven) ?? CropRect.none;
  }

  ReaderSettings copyWith({
    bool? splitPages,
    bool? splitRightToLeft,
    bool? splitPrompted,
    bool? cropEnabled,
    CropRect? cropOdd,
    CropRect? cropEven,
    bool? cropPrompted,
  }) => ReaderSettings(
    splitPages: splitPages ?? this.splitPages,
    splitRightToLeft: splitRightToLeft ?? this.splitRightToLeft,
    splitPrompted: splitPrompted ?? this.splitPrompted,
    cropEnabled: cropEnabled ?? this.cropEnabled,
    cropOdd: cropOdd ?? this.cropOdd,
    cropEven: cropEven ?? this.cropEven,
    cropPrompted: cropPrompted ?? this.cropPrompted,
  );
}

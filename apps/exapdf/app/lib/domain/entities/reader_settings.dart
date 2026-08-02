import '../../core/reading_filter.dart';
import 'crop_rect.dart';
import 'fit_mode.dart';
import 'reading_theme.dart';

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
    this.theme = ReadingTheme.system,
    this.darkImageMode = DarkImageMode.preserve,
    this.brightness = 1,
    this.contrast = 1,
    this.fitMode = FitMode.width,
    this.landscapeHintShown = false,
    this.zoomLocked = false,
    this.zoomLevel = 1,
    this.panX = 0,
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

  /// 리딩 테마 (techspec §8)
  final ReadingTheme theme;

  /// 다크에서 사진·그림을 어떻게 다룰지
  final DarkImageMode darkImageMode;

  /// 0.5~1.5. 1 이 원래
  final double brightness;
  final double contrast;

  /// 쪽 그림을 손봐야 하는가
  bool get tintsPage => theme == ReadingTheme.dark || theme == ReadingTheme.sepia
      || brightness != 1 || contrast != 1;

  /// 쪽을 화면에 맞추는 방식
  final FitMode fitMode;

  /// 가로로 보라는 안내를 이미 띄웠는가
  final bool landscapeHintShown;

  /// 확대 배율과 좌우 위치를 잠갔는가. 세로는 잠그지 않는다
  final bool zoomLocked;

  /// 잠갔을 때의 배율과 좌우 위치
  final double zoomLevel;
  final double panX;

  /// 색 변환 설정이 바뀌었는지 가리는 열쇠. 바뀌면 그림을 다시 그린다
  String get tintKey => '${theme.name}/${darkImageMode.name}/$brightness/$contrast';

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
    ReadingTheme? theme,
    DarkImageMode? darkImageMode,
    double? brightness,
    double? contrast,
    FitMode? fitMode,
    bool? landscapeHintShown,
    bool? zoomLocked,
    double? zoomLevel,
    double? panX,
  }) => ReaderSettings(
    splitPages: splitPages ?? this.splitPages,
    splitRightToLeft: splitRightToLeft ?? this.splitRightToLeft,
    splitPrompted: splitPrompted ?? this.splitPrompted,
    cropEnabled: cropEnabled ?? this.cropEnabled,
    cropOdd: cropOdd ?? this.cropOdd,
    cropEven: cropEven ?? this.cropEven,
    cropPrompted: cropPrompted ?? this.cropPrompted,
    theme: theme ?? this.theme,
    darkImageMode: darkImageMode ?? this.darkImageMode,
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    fitMode: fitMode ?? this.fitMode,
    landscapeHintShown: landscapeHintShown ?? this.landscapeHintShown,
    zoomLocked: zoomLocked ?? this.zoomLocked,
    zoomLevel: zoomLevel ?? this.zoomLevel,
    panX: panX ?? this.panX,
  );
}

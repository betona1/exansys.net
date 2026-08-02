import '../../data/db/database.dart';
import '../ocr/ocr_settings.dart' show OcrSettings;

/// 안내를 볼지 말지.
///
/// 처음 쓰는 사람에게는 알려 줘야 하고, 아는 사람에게는 걸리적거린다.
/// **둘 다 만족시키는 방법은 하나뿐이다 — 처음엔 보여 주고, 끌 수 있게 한다.**
/// [OcrSettings] 와 같은 `app_meta` 표를 쓴다.
class HelpSettings {
  const HelpSettings({this.showTips = true, this.readerIntroSeen = false});

  static const _keyShow = 'help.showTips';
  static const _keyIntro = 'help.readerIntroSeen';

  /// 안내를 띄울지. 끄면 첫 안내도 도움말 풍선도 나오지 않는다
  final bool showTips;

  /// 읽기 화면 첫 안내를 이미 봤는가
  final bool readerIntroSeen;

  /// 지금 읽기 화면 안내를 띄워야 하는가
  bool get shouldShowReaderIntro => showTips && !readerIntroSeen;

  HelpSettings copyWith({bool? showTips, bool? readerIntroSeen}) => HelpSettings(
        showTips: showTips ?? this.showTips,
        readerIntroSeen: readerIntroSeen ?? this.readerIntroSeen,
      );

  static Future<HelpSettings> load(AppDatabase db) async {
    final rows = await db.select(db.appMeta).get();
    final map = {for (final r in rows) r.key: r.value};
    return HelpSettings(
      // 값이 없으면 켜진 것으로 본다 — 처음 쓰는 사람이 기본이다
      showTips: map[_keyShow] != 'false',
      readerIntroSeen: map[_keyIntro] == 'true',
    );
  }

  Future<void> save(AppDatabase db) async {
    for (final e in {_keyShow: '$showTips', _keyIntro: '$readerIntroSeen'}.entries) {
      await db.into(db.appMeta).insertOnConflictUpdate(
            AppMetaCompanion.insert(key: e.key, value: e.value),
          );
    }
  }
}

import '../../data/db/database.dart';

/// 어느 서버의 어느 모델로 글자를 읽을지.
///
/// **주소를 코드에 박지 않는다** (CLAUDE.md §2 규칙 3). 사람마다 자기 서버가
/// 다르고, 배포본에 남의 사설망 주소가 들어가 있을 이유가 없다.
/// 값은 `app_meta` 에 담는다 — 표를 새로 만들 만큼 큰 이야기가 아니다.
class OcrSettings {
  const OcrSettings({this.endpoint = defaultEndpoint, this.model = defaultModel});

  /// 개발 중에 쓰는 내 서버. 매번 손으로 넣지 않으려고 채워 둔다.
  ///
  /// **밖에 내보내기 전에 비운다.** 남의 사설망 주소가 배포본에 들어 있을
  /// 이유가 없다. 지울 곳은 여기 한 줄이고, 다른 빌드로 덮어쓸 수도 있다:
  ///   flutter build apk --dart-define=ocrEndpoint=http://내서버:11434
  static const defaultEndpoint = String.fromEnvironment(
    'ocrEndpoint',
    defaultValue: 'http://192.168.219.88:11434',
  );

  /// 실측에서 쓴 모델. 3b 는 오히려 느렸다 — 병목이 그림 인코딩이라
  /// 파라미터 수와 상관이 없다 (docs/engine-verification.md)
  static const defaultModel = 'qwen2.5vl:7b';

  static const _keyEndpoint = 'ocr.endpoint';
  static const _keyModel = 'ocr.model';

  final String endpoint;
  final String model;

  bool get configured => endpoint.trim().isNotEmpty;

  OcrSettings copyWith({String? endpoint, String? model}) =>
      OcrSettings(endpoint: endpoint ?? this.endpoint, model: model ?? this.model);

  static Future<OcrSettings> load(AppDatabase db) async {
    final rows = await db.select(db.appMeta).get();
    final map = {for (final r in rows) r.key: r.value};
    // 저장해 둔 값이 있으면 그것이 우선. 없으면 기본 주소를 채워 준다
    final saved = map[_keyEndpoint];
    return OcrSettings(
      endpoint: (saved == null || saved.isEmpty) ? defaultEndpoint : saved,
      model: map[_keyModel] ?? defaultModel,
    );
  }

  Future<void> save(AppDatabase db) async {
    for (final e in {_keyEndpoint: endpoint.trim(), _keyModel: model.trim()}.entries) {
      await db.into(db.appMeta).insertOnConflictUpdate(
            AppMetaCompanion.insert(key: e.key, value: e.value),
          );
    }
  }

  /// 사람이 적은 주소를 다듬는다.
  ///
  /// `192.168.219.88` 만 적어도 되게 한다 — 포트와 스킴까지 정확히 적으라고
  /// 요구하면 대부분 한 번에 실패한다. 끝의 `/` 도 떼어 낸다
  static String normalizeEndpoint(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    if (!s.contains('://')) s = 'http://$s';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    // 포트가 없으면 Ollama 기본 포트를 붙인다
    final uri = Uri.tryParse(s);
    if (uri != null && !uri.hasPort) s = '$s:11434';
    return s;
  }
}

import '../../data/db/database.dart';

/// 어느 서버의 어느 모델로 글자를 읽을지.
///
/// **주소를 코드에 박지 않는다** (CLAUDE.md §2 규칙 3). 사람마다 자기 서버가
/// 다르고, 배포본에 남의 사설망 주소가 들어가 있을 이유가 없다.
/// 값은 `app_meta` 에 담는다 — 표를 새로 만들 만큼 큰 이야기가 아니다.
class OcrSettings {
  const OcrSettings({this.endpoint = defaultEndpoint, this.model = defaultModel});

  /// 빌드할 때 채워 넣는 기본 서버 주소.
  ///
  /// **소스에 박지 않는다** (CLAUDE.md §2 규칙 3). `.env.json` 에 적고
  /// 빌드에 넘긴다 — 그 파일은 커밋되지 않으므로 남의 사설망 주소가
  /// 배포본이나 저장소에 남지 않는다.
  ///
  ///   flutter build apk --release --dart-define-from-file=.env.json
  ///
  /// 넘기지 않으면 빈 값이고, 그때는 앱에서 직접 입력한다.
  /// 무엇을 적는지는 `.env.example` 에 있다.
  static const defaultEndpoint = String.fromEnvironment('ocrEndpoint');

  /// 실측에서 쓴 모델. 3b 는 오히려 느렸다 — 병목이 그림 인코딩이라
  /// 파라미터 수와 상관이 없다 (docs/engine-verification.md)
  static const defaultModel = String.fromEnvironment(
    'ocrModel',
    defaultValue: 'qwen2.5vl:7b',
  );

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

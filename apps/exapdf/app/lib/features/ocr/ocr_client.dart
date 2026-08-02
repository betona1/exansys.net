import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// 스캔본을 글자로 바꾸는 서버와 이야기한다 (Ollama 비전 모델).
///
/// 왜 앱이 아니라 서버인가 — CLAUDE.md §4. OCR 은 앱에 넣지 않는다.
/// 앱이 하는 일은 쪽을 그림으로 만들어 보내고 글자를 받아 적는 것뿐이다.
///
/// 실측 근거는 `docs/engine-verification.md` 의 "OCR 실측" 절에 있다.
/// 요약: 품질은 원문과 글자 하나 다르지 않았고, 시간의 88% 가 그림을
/// 토큰으로 바꾸는 데 들어간다. 그래서 **보낼 때 폭을 줄이는 것**이 핵심이다.
class OcrClient {
  const OcrClient({required this.endpoint, required this.model, this.client});

  /// 예: `http://192.168.219.88:11434`
  final String endpoint;

  /// 예: `qwen2.5vl:7b`
  final String model;

  /// 테스트에서 가짜 클라이언트를 끼울 자리. 없으면 그때그때 만든다
  final http.Client? client;

  /// 보낼 그림의 최대 폭(px).
  ///
  /// 실측에서 1386px→900px 로 줄이자 87초가 34초가 되었고 **글자는 100% 같았다.**
  /// 700px 아래로는 모델의 타일 격자 때문에 더 빨라지지 않는다.
  static const sendWidth = 900;

  /// 반쪽 한 장에 넉넉한 값. 올리지 않으면 기본값에서 잘린다
  static const maxTokens = 2500;

  static const prompt = '이 그림은 한국어 책의 한 쪽입니다. 보이는 글자를 그대로 옮겨 적으세요. '
      '설명하거나 요약하지 말고 원문 글자만 출력합니다.';

  /// 서버가 살아 있고 그 모델이 있는지.
  ///
  /// 시작하기 전에 확인한다. 두 시간짜리 일을 걸어 놓고 첫 쪽에서
  /// 주소 오타로 실패하는 것만큼 허무한 것이 없다.
  Future<OcrProbe> probe() async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$endpoint/api/tags'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return OcrProbe.fail('서버가 ${res.statusCode} 로 답했습니다');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final names = <String>[
        for (final m in (body['models'] as List<dynamic>? ?? const []))
          (m as Map<String, dynamic>)['name'] as String,
      ];
      if (names.isEmpty) return OcrProbe.fail('서버에 모델이 없습니다');
      if (!names.contains(model)) {
        return OcrProbe.fail('$model 이(가) 없습니다. 있는 것: ${names.join(', ')}');
      }
      return OcrProbe.ok(names);
    } on Object catch (e) {
      return OcrProbe.fail(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  /// 그림 한 장을 글자로. 실패하면 던진다 — 부르는 쪽이 다시 시도를 정한다
  Future<String> readImage(Uint8List jpeg, {Duration timeout = const Duration(minutes: 10)}) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .post(
            Uri.parse('$endpoint/api/generate'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'images': [base64Encode(jpeg)],
              'stream': false,
              // 온도를 0 으로. 글자를 옮겨 적는 일에 창의성은 해롭다
              'options': {'temperature': 0, 'num_predict': maxTokens},
            }),
          )
          .timeout(timeout);
      if (res.statusCode != 200) {
        throw OcrException('서버가 ${res.statusCode} 로 답했습니다');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return (body['response'] as String? ?? '').trim();
    } on OcrException {
      rethrow;
    } on Object catch (e) {
      throw OcrException(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  /// 사용자에게 보일 말로 바꾼다. 스택트레이스를 그대로 보여 주지 않는다
  static String _readable(Object e) {
    final s = '$e';
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return '서버에 닿지 못했습니다. 주소와 같은 망에 있는지 확인해 주세요';
    }
    if (s.contains('TimeoutException')) return '서버가 제때 답하지 않았습니다';
    // 웹에서 http 주소를 부르면 브라우저가 막는다. 원인을 정확히 알려 준다
    if (s.contains('XMLHttpRequest') || s.contains('ClientException')) {
      return '브라우저가 막았습니다. 서버에 CORS 허용이 필요하고, '
          'https 페이지에서는 https 주소여야 합니다';
    }
    return s;
  }
}

class OcrProbe {
  const OcrProbe._(this.ok, this.message, this.models);

  factory OcrProbe.ok(List<String> models) => OcrProbe._(true, null, models);

  factory OcrProbe.fail(String message) => OcrProbe._(false, message, const []);

  final bool ok;
  final String? message;
  final List<String> models;
}

class OcrException implements Exception {
  const OcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// 서버가 맡은 일감의 현재 상태
class ServerJob {
  const ServerJob({
    required this.uuid,
    required this.status,
    required this.pageCount,
    required this.donePages,
    this.lastError = '',
  });

  final String uuid;

  /// QUEUED · RENDERING · OCR · DONE · FAILED · CANCELLED
  final String status;
  final int pageCount;
  final int donePages;
  final String lastError;

  bool get isFinished => status == 'DONE' || status == 'FAILED';
  bool get isFailed => status == 'FAILED';

  static ServerJob fromJson(Map<String, dynamic> j) => ServerJob(
        uuid: j['uuid'] as String,
        status: j['status'] as String? ?? 'QUEUED',
        pageCount: (j['page_count'] as num?)?.toInt() ?? 0,
        donePages: (j['done_pages'] as num?)?.toInt() ?? 0,
        lastError: j['last_error'] as String? ?? '',
      );
}

/// 서버가 읽어 준 쪽 하나
class ServerPage {
  const ServerPage({required this.pageNo, required this.text});

  final int pageNo;
  final String text;
}

/// OCR 서버(Django)와 이야기한다.
///
/// 앱이 직접 Ollama 를 부르던 방식은 **앱을 켜 둔 채로 두 시간**을 요구했다.
/// 홈으로 나가거나 화면이 꺼지면 안드로이드가 앱을 재워 멈춘다.
/// 서버에 맡기면 올려 두고 나가면 되고, 나중에 결과만 받아 오면 된다.
class OcrServerClient {
  const OcrServerClient({
    required this.baseUrl,
    required this.token,
    this.client,
  });

  final String baseUrl;
  final String token;
  final http.Client? client;

  Map<String, String> get _auth => {'Authorization': 'Bearer $token'};

  /// 서버와 그 뒤의 Ollama 가 살아 있는지. 올리기 전에 확인한다
  Future<(bool, String)> health() async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final ollama = body['ollama'] as Map<String, dynamic>? ?? const {};
      if (ollama['ok'] == true) return (true, '연결됐습니다 · ${ollama['message']}');
      return (false, '서버는 살아 있는데 글자 읽기 엔진이 없습니다: ${ollama['message']}');
    } on Object catch (e) {
      return (false, _readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  /// PDF 를 올려 일감을 만든다.
  ///
  /// 같은 파일을 다시 올리면 서버가 **새 일감을 만들지 않고** 이미 있는 것을
  /// 돌려준다. 앱을 지웠다 깔아도 두 시간을 다시 기다리지 않는다.
  Future<ServerJob> createJob({
    required Uint8List bytes,
    required String filename,
    required bool split,
  }) async {
    final c = client ?? http.Client();
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/jobs'))
        ..headers.addAll(_auth)
        ..fields['split'] = split ? 'true' : 'false'
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await c.send(req).timeout(const Duration(minutes: 10));
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw OcrServerException(body['error'] as String? ?? '올리지 못했습니다');
      }
      return ServerJob.fromJson(body['job'] as Map<String, dynamic>);
    } on OcrServerException {
      rethrow;
    } on Object catch (e) {
      throw OcrServerException(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  Future<ServerJob> job(String uuid) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$baseUrl/api/jobs/$uuid'), headers: _auth)
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw OcrServerException(body['error'] as String? ?? '상태를 읽지 못했습니다');
      }
      return ServerJob.fromJson(body['job'] as Map<String, dynamic>);
    } on OcrServerException {
      rethrow;
    } on Object catch (e) {
      throw OcrServerException(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  /// [since] 쪽 **다음부터** 읽은 글자를 가져온다.
  /// 전체를 매번 내려받으면 500쪽짜리에서 낭비가 크다
  Future<(List<ServerPage>, ServerJob)> pages(String uuid, {int since = 0}) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$baseUrl/api/jobs/$uuid/pages?since=$since'), headers: _auth)
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw OcrServerException(body['error'] as String? ?? '글자를 받지 못했습니다');
      }
      final list = [
        for (final p in (body['pages'] as List<dynamic>? ?? const []))
          ServerPage(
            pageNo: ((p as Map<String, dynamic>)['page_no'] as num).toInt(),
            text: p['text'] as String? ?? '',
          ),
      ];
      final job = ServerJob(
        uuid: uuid,
        status: body['status'] as String? ?? 'OCR',
        pageCount: (body['page_count'] as num?)?.toInt() ?? 0,
        donePages: (body['done_pages'] as num?)?.toInt() ?? 0,
      );
      return (list, job);
    } on OcrServerException {
      rethrow;
    } on Object catch (e) {
      throw OcrServerException(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  Future<void> cancel(String uuid) async {
    final c = client ?? http.Client();
    try {
      await c
          .post(Uri.parse('$baseUrl/api/jobs/$uuid/cancel'), headers: _auth)
          .timeout(const Duration(seconds: 20));
    } on Object {
      // 못 멈춰도 앱은 계속 써야 한다. 서버가 알아서 끝낼 것이다
    } finally {
      if (client == null) c.close();
    }
  }

  static String _readable(Object e) {
    final s = '$e';
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return '서버에 닿지 못했습니다. 같은 망에 있는지 확인해 주세요';
    }
    if (s.contains('TimeoutException')) return '서버가 제때 답하지 않았습니다';
    return s;
  }
}

class OcrServerException implements Exception {
  const OcrServerException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:convert';

import 'package:http/http.dart' as http;

/// exansys.net 워커 API — 문제 신고 + 원격 콘텐츠 (TECHSPEC §15.3)
class VqApi {
  static const base = 'https://exansys.net';
  static const _timeout = Duration(seconds: 6);

  /// 문제 신고. 성공 시 true (오프라인이면 false).
  static Future<bool> sendReport({
    required String termId,
    required String termKo,
    String? questionType,
    required String reason, // wrong_answer | typo | bad_explanation | other
    String? detail,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$base/api/vibequest/reports'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'termId': termId,
              'termKo': termKo,
              'questionType': questionType,
              'reason': reason,
              'detail': detail,
            }),
          )
          .timeout(_timeout);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return res.statusCode == 200 && body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 콘텐츠 메타 — {contentVersion, glossaryUrl, sha256}
  static Future<Map<String, dynamic>?> contentMeta() async {
    try {
      final res = await http.get(Uri.parse('$base/api/vibequest/content/meta')).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['ok'] == true ? body['data'] as Map<String, dynamic> : null;
    } catch (_) {
      return null;
    }
  }

  /// 최신 용어집 다운로드 (버전 업데이트 시)
  static Future<List<Map<String, dynamic>>?> fetchGlossary() async {
    try {
      final res = await http
          .get(Uri.parse('$base/api/vibequest/content/glossary.json'))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      if (list.isEmpty) return null;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }
}

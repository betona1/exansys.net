import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/db/database.dart';


/// 지금 로그인한 사람과, 무엇을 쓸 수 있는지.
class Account {
  const Account({
    required this.userId,
    required this.name,
    required this.plan,
    required this.features,
    this.avatarUrl,
    this.proUntil,
  });

  final int userId;
  final String name;

  /// `free` 또는 `pro`
  final String plan;

  /// 쓸 수 있는 유료 기능 이름들 (`ocr`, `image_to_text`)
  final List<String> features;

  final String? avatarUrl;

  /// 유료 기한 (초). 무기한이면 null
  final int? proUntil;

  bool get isPro => plan == 'pro';

  bool can(String feature) => features.contains(feature);

  static Account fromJson(Map<String, dynamic> j) => Account(
        userId: (j['userId'] as num).toInt(),
        name: j['name'] as String? ?? '',
        plan: j['plan'] as String? ?? 'free',
        avatarUrl: j['avatarUrl'] as String?,
        proUntil: (j['proUntil'] as num?)?.toInt(),
        features: [
          for (final f in (j['features'] as List<dynamic>? ?? const [])) f as String,
        ],
      );
}

/// 연결 코드 한 벌 — 화면에 띄울 코드와, 결과를 물어볼 기기 번호
class LinkStart {
  const LinkStart({required this.code, required this.device});

  final String code;
  final String device;
}

/// exansys.net 계정과 앱을 잇고, 권한을 물어본다.
///
/// **앱 안에 로그인 창을 띄우지 않는다.** 앱이 여섯 자리 코드를 보여 주면
/// 사용자는 아무 브라우저에서 로그인한 뒤 그 코드를 넣는다. 이러면 앱이
/// 비밀번호를 볼 일이 없고, 이미 만들어 둔 소셜·이메일 로그인을 그대로 쓴다.
///
/// 웹(PWA)에서는 같은 상위 도메인이라 쿠키만으로도 된다 — 토큰이 없으면
/// 쿠키로 물어본다.
class AccountService {
  AccountService(this._db, {this.client, String? baseUrl})
      : _base = baseUrl ?? defaultBase;

  /// 계정 서버. 배포본은 exansys.net 을 본다
  static const defaultBase = String.fromEnvironment(
    'accountServer',
    defaultValue: 'https://exansys.net',
  );

  static const _keyToken = 'account.token';

  final AppDatabase _db;
  /// 테스트에서 가짜 클라이언트를 끼울 자리
  final http.Client? client;
  final String _base;

  Future<String?> readToken() async {
    final rows = await _db.select(_db.appMeta).get();
    for (final r in rows) {
      if (r.key == _keyToken) return r.value.isEmpty ? null : r.value;
    }
    return null;
  }

  Future<void> _saveToken(String token) async {
    await _db.into(_db.appMeta).insertOnConflictUpdate(
          AppMetaCompanion.insert(key: _keyToken, value: token),
        );
  }

  Future<void> clearToken() async {
    await _db.into(_db.appMeta).insertOnConflictUpdate(
          AppMetaCompanion.insert(key: _keyToken, value: ''),
        );
  }

  /// 코드를 받아 온다. 사용자가 브라우저에서 넣을 것이다
  Future<LinkStart> startLink() async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .post(Uri.parse('$_base/api/exapdf/link/start'))
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode != 200 || body['ok'] != true) {
        throw AccountException('연결을 시작하지 못했습니다');
      }
      final data = body['data'] as Map<String, dynamic>;
      return LinkStart(code: data['code'] as String, device: data['device'] as String);
    } on AccountException {
      rethrow;
    } on Object catch (e) {
      throw AccountException(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  /// 사용자가 코드를 넣었는지 한 번 확인한다.
  /// 아직이면 null — 부르는 쪽이 잠시 뒤 다시 묻는다
  Future<Account?> pollLink(String device) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$_base/api/exapdf/link/poll?device=$device'))
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode == 404) throw AccountException('코드가 만료됐습니다. 다시 받아 주세요');
      if (body['ok'] != true) throw AccountException('연결을 확인하지 못했습니다');
      final data = body['data'] as Map<String, dynamic>;
      if (data['pending'] == true) return null;
      await _saveToken(data['token'] as String);
      return Account.fromJson(data['me'] as Map<String, dynamic>);
    } on AccountException {
      rethrow;
    } on Object catch (e) {
      throw AccountException(_readable(e));
    } finally {
      if (client == null) c.close();
    }
  }

  /// 지금 계정과 권한. 로그인 안 돼 있으면 null.
  ///
  /// 앱을 켤 때마다 물어본다 — 유료 기한이 지났는지 앱이 스스로 알 수 없다
  Future<Account?> fetchMe() async {
    final token = await readToken();
    final c = client ?? http.Client();
    try {
      final res = await c.get(
        Uri.parse('$_base/api/exapdf/me'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (body['ok'] != true) return null;
      return Account.fromJson(body['data'] as Map<String, dynamic>);
    } on Object {
      // 서버에 못 닿아도 앱은 계속 써야 한다. 권한을 모르면 무료로 본다
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  Future<void> logout() async {
    final token = await readToken();
    if (token != null) {
      final c = client ?? http.Client();
      try {
        await c.post(
          Uri.parse('$_base/api/exapdf/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      } on Object {
        // 서버에 못 닿아도 이 기기에서는 지운다
      } finally {
        if (client == null) c.close();
      }
    }
    await clearToken();
  }

  /// 브라우저로 열어 줄 주소. 코드를 미리 채워 손으로 옮겨 적지 않게 한다
  Uri linkUrl(String code) => Uri.parse('$_base/exapdf/link?code=$code');

  static String _readable(Object e) {
    final s = '$e';
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return '인터넷에 닿지 못했습니다';
    }
    if (s.contains('TimeoutException')) return '서버가 제때 답하지 않았습니다';
    return s;
  }
}

class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 잠긴 기능을 눌렀을 때 쓸 이름들. 서버와 같은 문자열이어야 한다
abstract final class ProFeature {
  static const ocr = 'ocr';
  static const imageToText = 'image_to_text';
}


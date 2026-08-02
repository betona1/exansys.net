import 'dart:convert';

import 'package:drift/native.dart';
import 'package:exapdf/data/db/database.dart';
import 'package:exapdf/features/account/account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 서버를 실제로 부르지 않는다. 권한 판정과 토큰 보관이 핵심이고,
/// 둘 다 틀리면 "유료인데 안 열린다" 또는 그 반대가 된다.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('권한 판정', () {
    test('pro 면 그 기능을 쓸 수 있다', () {
      final a = Account.fromJson({
        'userId': 1,
        'name': '비투나',
        'plan': 'pro',
        'features': ['ocr', 'image_to_text'],
      });
      expect(a.isPro, isTrue);
      expect(a.can(ProFeature.ocr), isTrue);
    });

    test('free 면 유료 기능이 잠긴다', () {
      final a = Account.fromJson({
        'userId': 1,
        'name': '비투나',
        'plan': 'free',
        'features': <String>[],
      });
      expect(a.isPro, isFalse);
      expect(a.can(ProFeature.ocr), isFalse);
    });

    test('서버가 모르는 기능을 줘도 있는 것만 인정한다', () {
      final a = Account.fromJson({
        'userId': 1,
        'name': 'x',
        'plan': 'pro',
        'features': ['ocr'],
      });
      expect(a.can(ProFeature.ocr), isTrue);
      expect(a.can(ProFeature.imageToText), isFalse);
    });
  });

  group('연결', () {
    test('코드를 받아 온다', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => http.Response(
              jsonEncode({'ok': true, 'data': {'code': 'ABC-123', 'device': 'dev1'}}),
              200,
            )),
      );
      final link = await s.startLink();
      expect(link.code, 'ABC-123');
      expect(link.device, 'dev1');
    });

    test('아직 안 넣었으면 null 을 준다', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => http.Response(
              jsonEncode({'ok': true, 'data': {'pending': true}}),
              200,
            )),
      );
      expect(await s.pollLink('dev1'), isNull);
    });

    test('연결되면 토큰을 담아 둔다 — 다음에 다시 연결하지 않게', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'ok': true,
                'data': {
                  'pending': false,
                  'token': 'tok-1',
                  'me': {'userId': 7, 'name': '비투나', 'plan': 'pro', 'features': ['ocr']},
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      final me = await s.pollLink('dev1');
      expect(me!.name, '비투나');
      expect(await s.readToken(), 'tok-1');
    });

    test('만료된 코드는 읽을 수 있는 말로 알린다', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => http.Response(
              jsonEncode({'ok': false, 'error': 'expired'}), 404)),
      );
      expect(
        () => s.pollLink('dev1'),
        throwsA(isA<AccountException>().having((e) => e.message, '설명', contains('만료'))),
      );
    });
  });

  group('내 계정 조회', () {
    test('로그인 안 됐으면 null', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => http.Response('{"ok":false}', 401)),
      );
      expect(await s.fetchMe(), isNull);
    });

    test('서버에 못 닿아도 앱은 멈추지 않는다 — 무료로 본다', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => throw Exception('SocketException')),
      );
      expect(await s.fetchMe(), isNull);
    });

    test('로그아웃하면 토큰을 지운다', () async {
      final s = AccountService(
        db,
        baseUrl: 'https://x',
        client: MockClient((_) async => http.Response('{"ok":true,"data":{}}', 200)),
      );
      await db.into(db.appMeta).insertOnConflictUpdate(
            AppMetaCompanion.insert(key: 'account.token', value: 'tok-1'),
          );
      await s.logout();
      expect(await s.readToken(), isNull);
    });
  });
}

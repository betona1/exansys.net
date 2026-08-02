import 'dart:convert';
import 'dart:typed_data';

import 'package:bookviewer/features/ocr/ocr_client.dart';
import 'package:bookviewer/features/ocr/ocr_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 서버를 실제로 부르지 않고 확인한다. 주소 다듬기와 응답 해석이 핵심이고,
/// 둘 다 틀리면 "서버에 안 닿는다"로만 보여 원인을 못 찾는다.
void main() {
  group('주소 다듬기', () {
    test('스킴과 포트를 알아서 채운다', () {
      expect(OcrSettings.normalizeEndpoint('192.168.219.88'), 'http://192.168.219.88:11434');
    });

    test('이미 적어 준 것은 건드리지 않는다', () {
      expect(
        OcrSettings.normalizeEndpoint('https://ocr.example.com:8443'),
        'https://ocr.example.com:8443',
      );
    });

    test('끝의 빗금을 떼어 낸다 — 붙어 있으면 //api/tags 가 된다', () {
      expect(OcrSettings.normalizeEndpoint('http://a.b:11434/'), 'http://a.b:11434');
    });

    test('빈 값은 빈 값으로 둔다', () {
      expect(OcrSettings.normalizeEndpoint('   '), '');
    });

    test('기본 주소가 채워져 있어 바로 시작할 수 있다', () {
      // 개발 편의용. 배포 전에는 비워야 한다 (OcrSettings.defaultEndpoint 주석)
      expect(const OcrSettings().configured, isTrue);
    });
  });

  group('연결 확인', () {
    test('모델이 있으면 통과', () async {
      final c = OcrClient(
        endpoint: 'http://x',
        model: 'qwen2.5vl:7b',
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'models': [
                  {'name': 'qwen2.5vl:7b'},
                  {'name': 'exaone3.5:7.8b'},
                ],
              }),
              200,
            )),
      );
      final r = await c.probe();
      expect(r.ok, isTrue);
      expect(r.models.length, 2);
    });

    test('모델이 없으면 있는 것을 알려 준다 — 오타를 스스로 찾게', () async {
      final c = OcrClient(
        endpoint: 'http://x',
        model: 'qwen2.5vl:70b',
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'models': [
                  {'name': 'qwen2.5vl:7b'},
                ],
              }),
              200,
            )),
      );
      final r = await c.probe();
      expect(r.ok, isFalse);
      expect(r.message, contains('qwen2.5vl:7b'));
    });
  });

  group('글자 읽기', () {
    test('response 를 꺼내 준다', () async {
      final c = OcrClient(
        endpoint: 'http://x',
        model: 'm',
        client: MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          // 창의성이 끼면 원문이 아니라 요약이 온다. 온도는 0 이어야 한다
          expect((body['options'] as Map)['temperature'], 0);
          // 올리지 않으면 기본값에서 잘린다 (engine-verification 의 함정)
          expect((body['options'] as Map)['num_predict'], OcrClient.maxTokens);
          expect(body['stream'], isFalse);
          return http.Response(
            jsonEncode({'response': '  가장 고통스러운 감정  '}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      expect(await c.readImage(Uint8List(4)), '가장 고통스러운 감정');
    });

    test('실패는 읽을 수 있는 말로 바꾼다', () async {
      final c = OcrClient(
        endpoint: 'http://x',
        model: 'm',
        client: MockClient((_) async => http.Response('nope', 500)),
      );
      expect(
        () => c.readImage(Uint8List(4)),
        throwsA(isA<OcrException>().having((e) => e.message, '설명', contains('500'))),
      );
    });
  });
}

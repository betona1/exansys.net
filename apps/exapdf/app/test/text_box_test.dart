import 'dart:convert';

import 'package:exapdf/features/search/text_box.dart';
import 'package:flutter_test/flutter_test.dart';

/// 좌표를 잘못 읽으면 엉뚱한 자리에 칠해지고, 맞추기를 잘못하면
/// 찾았는데도 안 칠해진다. 둘 다 눈으로만 확인하기 어려운 종류다.
void main() {
  String json(List<Map<String, Object>> lines) => jsonEncode(lines);

  group('좌표 읽기', () {
    test('줄과 사각형을 읽어 낸다', () {
      final boxes = TextBox.parse(json([
        {
          'text': '외로움은 고통스럽습니다',
          'box': [0.1, 0.2, 0.9, 0.24],
          'score': 0.93,
        },
      ]));
      expect(boxes.length, 1);
      expect(boxes.first.text, '외로움은 고통스럽습니다');
      expect(boxes.first.rect.left, 0.1);
      expect(boxes.first.rect.bottom, 0.24);
      expect(boxes.first.score, closeTo(0.93, 0.001));
    });

    test('좌표가 없으면 빈 목록 — 비전 모델로만 읽은 책이 그렇다', () {
      expect(TextBox.parse(null), isEmpty);
      expect(TextBox.parse(''), isEmpty);
    });

    test('형태가 깨져도 앱이 죽지 않는다', () {
      // 서버가 형태를 바꿔도 칠하기만 못 할 뿐이어야 한다
      expect(TextBox.parse('{{{'), isEmpty);
      expect(TextBox.parse('[{"text":"x"}]').first.rect.width, 0);
    });
  });

  group('찾은 말 맞추기', () {
    final lines = TextBox.parse(json([
      {'text': '떠올려보면 외로움의고통을 짐작할 수있습니다', 'box': [0.0, 0.1, 1.0, 0.14], 'score': 0.9},
      {'text': '따돌림을 당한 사람들은', 'box': [0.0, 0.2, 1.0, 0.24], 'score': 0.9},
    ]));

    test('그대로 있으면 찾는다', () {
      expect(TextBox.matches(lines, '따돌림').length, 1);
    });

    test('띄어쓰기가 달라도 찾는다', () {
      // PaddleOCR 은 한국어 띄어쓰기를 자주 뭉갠다("수있습니다").
      // 사람도 검색할 때 제각각 넣는다 — 둘 다 지우고 맞춰야 한다
      expect(TextBox.matches(lines, '수 있습니다').length, 1);
      expect(TextBox.matches(lines, '외로움의 고통').length, 1);
    });

    test('없는 말은 안 걸린다', () {
      expect(TextBox.matches(lines, '고양이'), isEmpty);
    });

    test('빈 말에는 아무것도 안 걸린다 — 온 줄이 칠해지면 안 된다', () {
      expect(TextBox.matches(lines, ''), isEmpty);
      expect(TextBox.matches(lines, '   '), isEmpty);
    });

    test('여러 줄에 있으면 여러 줄이 걸린다', () {
      expect(TextBox.matches(lines, '을').length, 2);
    });
  });
}

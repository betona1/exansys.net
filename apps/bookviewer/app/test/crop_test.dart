import 'dart:typed_data';

import 'package:bookviewer/domain/entities/crop_rect.dart';
import 'package:bookviewer/features/reader/crop_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// 크롭 좌표 계산은 CLAUDE.md §9 가 **반드시 테스트하라**고 지정한 항목이다.
/// 여기가 틀리면 "페이지 번호가 잘렸다"는 불만으로 직행한다.

/// 흰 배경에 검은 사각형 하나를 그린 BGRA8888 픽셀을 만든다
Uint8List canvas(int w, int h, {required int left, required int top, required int right, required int bottom}) {
  final px = Uint8List(w * h * 4);
  px.fillRange(0, px.length, 255); // 흰 배경 + 불투명
  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      final i = (y * w + x) * 4;
      px[i] = 0; // B
      px[i + 1] = 0; // G
      px[i + 2] = 0; // R
      px[i + 3] = 255;
    }
  }
  return px;
}

void main() {
  test('가운데 내용의 여백을 네 방향 모두 찾는다', () {
    // 200x100 화폭에서 x 20~179, y 10~89 만 내용
    final px = canvas(200, 100, left: 20, top: 10, right: 179, bottom: 89);
    final r = CropDetector.boundingBoxForTest(px, 200, 100)!;

    // 여유 패딩(1.2%)이 빠진 값이 나온다 — 글자가 딱 붙어 잘리지 않게
    expect(r.left, closeTo(0.10 - 0.012, 0.006));
    expect(r.right, closeTo(0.10 - 0.012, 0.006));
    expect(r.top, closeTo(0.10 - 0.012, 0.006));
    expect(r.bottom, closeTo(0.10 - 0.012, 0.006));
  });

  test('한쪽으로 치우친 제본 여백을 그대로 잡는다', () {
    // 왼쪽만 30% 비어 있는 경우 (홀수 쪽의 안쪽 여백)
    final px = canvas(200, 100, left: 60, top: 2, right: 197, bottom: 97);
    final r = CropDetector.boundingBoxForTest(px, 200, 100)!;

    expect(r.left, greaterThan(0.25));
    expect(r.right, lessThan(0.03));
  });

  test('빈 쪽은 null 을 준다 — 통째로 잘라 버리면 안 된다', () {
    final px = canvas(100, 100, left: 0, top: 0, right: -1, bottom: -1);
    expect(CropDetector.boundingBoxForTest(px, 100, 100), isNull);
  });

  test('점 하나짜리 잡티는 내용으로 보지 않는다', () {
    // 스캔본에는 먼지 점이 흔하다. 이것 때문에 여백이 0 이 되면 크롭이 무의미해진다
    final px = canvas(200, 100, left: 100, top: 50, right: 100, bottom: 50);
    final r = CropDetector.boundingBoxForTest(px, 200, 100);
    expect(r, isNull, reason: '한 점은 내용이 아니다');
  });

  test('절반 넘게 자르지 않는다', () {
    // 오른쪽 끝에만 아주 조금 내용이 있는 극단적인 경우
    final px = canvas(200, 100, left: 196, top: 2, right: 199, bottom: 97);
    final r = CropDetector.boundingBoxForTest(px, 200, 100)!;
    expect(r.left, lessThanOrEqualTo(0.45));
    expect(r.widthRatio, greaterThan(0.05));
  });

  group('CropRect', () {
    test('쪽 좌표로 바꾼다', () {
      const crop = CropRect(left: 0.1, top: 0.05, right: 0.1, bottom: 0.05);
      final r = crop.toPageRect(1000, 800);
      expect(r.x, 100);
      expect(r.y, 40);
      expect(r.w, closeTo(800, 0.001));
      expect(r.h, closeTo(720, 0.001));
    });

    test('JSON 으로 갔다 와도 같다', () {
      const crop = CropRect(left: 0.11, top: 0.22, right: 0.33, bottom: 0.44);
      expect(CropRect.fromJson(crop.toJson()), crop);
    });

    test('깨진 JSON 은 null — 앱이 죽지 않는다', () {
      expect(CropRect.fromJson(null), isNull);
      expect(CropRect.fromJson(''), isNull);
      expect(CropRect.fromJson('[1,2]'), isNull, reason: '값이 넷이 아니면 못 쓴다');
    });
  });
}

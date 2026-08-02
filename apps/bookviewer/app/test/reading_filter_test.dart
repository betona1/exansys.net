import 'dart:typed_data';

import 'package:exapdf/core/reading_filter.dart';
import 'package:exapdf/features/reader/page_tint.dart';
import 'package:flutter_test/flutter_test.dart';

/// 다크 리딩의 핵심은 **휘도만 뒤집고 색은 남기는 것**이다.
/// 단순 반전(`1-x`)이면 사진이 네거티브가 되는데, 그게 조사에서 확인된
/// 기존 뷰어들의 최대 불만이었다 (techspec §8).

/// BGRA 픽셀 하나짜리 버퍼
Uint8List pixel(int r, int g, int b) => Uint8List.fromList([b, g, r, 255]);

(int r, int g, int b) tint(
  int r,
  int g,
  int b, {
  DarkImageMode mode = DarkImageMode.preserve,
  double brightness = 1,
  double contrast = 1,
}) {
  final out = tintPage(
    TintRequest(
      pixels: pixel(r, g, b),
      mode: mode,
      brightness: brightness,
      contrast: contrast,
    ),
  );
  return (out[2], out[1], out[0]);
}

void main() {
  group('휘도 반전 행렬', () {
    final m = ReadingFilter.luminanceInvert();

    test('흰 종이가 검게 간다', () {
      expect(ReadingFilter.apply(m, 255, 255, 255), (0, 0, 0));
    });

    test('검은 글자가 희게 간다', () {
      expect(ReadingFilter.apply(m, 0, 0, 0), (255, 255, 255));
    });

    test('중간 회색은 거의 그대로다', () {
      final (r, g, b) = ReadingFilter.apply(m, 128, 128, 128);
      expect(r, closeTo(127, 2));
      expect(g, closeTo(127, 2));
      expect(b, closeTo(127, 2));
    });

    test('색조가 뒤집히지 않는다 — 빨강은 빨강으로 남는다', () {
      // 단순 반전이면 빨강(255,0,0)이 청록(0,255,255)이 된다. 그건 안 된다
      final (r, g, b) = ReadingFilter.apply(m, 255, 0, 0);
      expect(r, greaterThan(g), reason: '여전히 붉은 쪽이어야 한다');
      expect(r, greaterThan(b));
      expect(g, equals(b), reason: '빨강 성분만 남으므로 G 와 B 는 같다');
    });
  });

  group('밝기·대비', () {
    test('밝기 1·대비 1 은 아무것도 바꾸지 않는다', () {
      final m = ReadingFilter.brightnessContrast();
      expect(ReadingFilter.apply(m, 30, 140, 220), (30, 140, 220));
    });

    test('밝기를 낮추면 어두워진다', () {
      final m = ReadingFilter.brightnessContrast(brightness: 0.5);
      final (r, _, _) = ReadingFilter.apply(m, 200, 200, 200);
      expect(r, closeTo(100, 1));
    });

    test('대비는 중간값 기준으로 벌린다', () {
      final m = ReadingFilter.brightnessContrast(contrast: 1.5);
      expect(ReadingFilter.apply(m, 128, 128, 128).$1, closeTo(128, 1), reason: '중간값은 고정점');
      expect(ReadingFilter.apply(m, 200, 200, 200).$1, greaterThan(200));
      expect(ReadingFilter.apply(m, 60, 60, 60).$1, lessThan(60));
    });
  });

  group('행렬 합성', () {
    test('두 행렬을 이어 붙인 결과가 차례로 적용한 것과 같다', () {
      final a = ReadingFilter.luminanceInvert();
      final b = ReadingFilter.brightnessContrast(brightness: 0.8);
      final composed = ReadingFilter.compose(a, b);

      final step = ReadingFilter.apply(a, 200, 120, 40);
      final expected = ReadingFilter.apply(b, step.$1, step.$2, step.$3);
      final actual = ReadingFilter.apply(composed, 200, 120, 40);

      expect(actual.$1, closeTo(expected.$1, 1));
      expect(actual.$2, closeTo(expected.$2, 1));
      expect(actual.$3, closeTo(expected.$3, 1));
    });
  });

  group('픽셀 변환 (다크 리딩)', () {
    test('스캔한 흰 종이는 검게, 검은 글자는 희게', () {
      expect(tint(255, 255, 255), (0, 0, 0));
      expect(tint(0, 0, 0), (255, 255, 255));
    });

    test('누런 종이도 뒤집는다 — 사진으로 오해하면 안 된다', () {
      // 스캔한 옛 책은 완전한 흰색이 아니라 살짝 누렇다
      final (r, g, b) = tint(238, 232, 216);
      expect(r, lessThan(60), reason: '어두워져야 한다');
      expect(g, lessThan(60));
      expect(b, lessThan(60));
    });

    test('색이 뚜렷한 사진은 뒤집지 않고 남긴다', () {
      final (r, g, b) = tint(220, 40, 40); // 선명한 빨강
      expect(r, greaterThan(g), reason: '색조가 유지된다');
      expect(r, greaterThan(120), reason: '뒤집히지 않았다');
      expect(g, lessThan(60));
      expect(b, lessThan(60));
    });

    test('전체 반전 모드는 사진도 뒤집는다', () {
      final (r, _, _) = tint(220, 40, 40, mode: DarkImageMode.invert);
      final preserved = tint(220, 40, 40).$1;
      expect(r, isNot(equals(preserved)), reason: '모드에 따라 결과가 달라야 한다');
    });

    test('어둡게만 모드는 뒤집지 않는다', () {
      final (r, g, b) = tint(255, 255, 255, mode: DarkImageMode.dim);
      expect(r, lessThan(255), reason: '어두워진다');
      expect(r, greaterThan(100), reason: '검게 뒤집히지는 않는다');
      expect(r, equals(g));
      expect(g, equals(b));
    });

    test('밝기·대비가 함께 걸린다', () {
      final normal = tint(255, 255, 255).$1;
      final brighter = tint(255, 255, 255, brightness: 1.4).$1;
      expect(brighter, greaterThanOrEqualTo(normal));
    });
  });
}

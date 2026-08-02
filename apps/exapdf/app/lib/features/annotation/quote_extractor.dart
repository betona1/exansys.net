import 'dart:ui';

import 'package:pdfrx/pdfrx.dart';

import '../../core/korean.dart';

/// 하이라이트 자리의 원문을 뽑아낸다.
///
/// 인용문이 없으면 내보낸 노트가 "p.128 · 중요" 뿐이라 나중에 아무 쓸모가 없다.
///
/// **좌표계가 두 가지라는 것이 함정이다.**
/// - 우리가 쓰는 렌더 좌표: 원점 좌상단, Y 가 아래로
/// - pdfrx 의 `PdfRect`: 원점 **좌하단**, Y 가 **위로** (top > bottom)
///
/// 변환을 빠뜨리면 쪽의 위아래가 뒤집힌 자리의 글이 딸려 온다. 조용히 틀리는 종류다.
abstract final class QuoteExtractor {
  /// 렌더 좌표 사각형을 PDF 좌표로 뒤집는다
  static PdfRect toPdfRect(Rect render, double pageHeight) => PdfRect(
    render.left,
    pageHeight - render.top, // 위쪽이 더 큰 값
    render.right,
    pageHeight - render.bottom,
  );

  /// 두 PDF 사각형이 겹치는가
  static bool overlaps(PdfRect a, PdfRect b) =>
      a.left < b.right && b.left < a.right && a.bottom < b.top && b.bottom < a.top;

  /// [rect](렌더 좌표) 안에 들어오는 글자를 이어 붙인다.
  ///
  /// 글자 상자가 조금이라도 겹치면 넣는다. 딱 맞게 자르려 들면 줄 끝 글자가 빠져
  /// 인용이 어색해진다.
  static String extract({
    required PdfPageText text,
    required Rect rect,
    required double pageHeight,
  }) {
    final target = toPdfRect(rect, pageHeight);
    final buffer = StringBuffer();
    final chars = text.charRects;
    final full = text.fullText;
    final count = chars.length < full.length ? chars.length : full.length;

    for (var i = 0; i < count; i++) {
      if (overlaps(chars[i], target)) buffer.write(full[i]);
    }
    // 줄바꿈 결합은 한글·영문 규칙이 다르다 (CLAUDE.md §6-4)
    return Korean.smartCopy(buffer.toString()).trim();
  }
}

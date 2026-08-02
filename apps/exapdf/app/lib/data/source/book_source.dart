import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

export 'source_io.dart' if (dart.library.js_interop) 'source_web.dart';

/// 책을 여는 방법은 플랫폼마다 다르다.
///
/// - 네이티브: 사용자가 고른 **파일 경로**를 들고 있다가 그때그때 연다.
///   원본을 복사하지 않는다 (CLAUDE.md §5 원칙)
/// - 웹: 브라우저는 경로를 주지 않는다. 바이트만 준다.
///   그래서 바이트를 IndexedDB(Drift)에 담아 두고 그걸로 연다
abstract class BookSource {
  /// 서재에 넣을 때 쓸 식별자. 네이티브는 경로, 웹은 `web:<uuid>`
  String get locator;

  /// 파일 크기
  int get size;

  /// 화면에 보일 이름
  String get displayName;

  /// 웹에서만 채워진다. DB 에 담아 둘 원본 바이트
  Uint8List? get bytesToStore;
}

/// 저장해 둔 책을 실제로 연다
typedef DocumentOpener = Future<PdfDocument> Function(String locator);

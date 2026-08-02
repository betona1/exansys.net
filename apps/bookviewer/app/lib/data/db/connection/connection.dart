import 'package:drift/drift.dart';

// 플랫폼마다 SQLite 를 여는 방법이 다르다.
// 네이티브는 dart:ffi 로 번들 SQLite 를, 웹은 WASM + IndexedDB 를 쓴다.
// dart:ffi 는 웹에 아예 없으므로 조건부로 갈라야 컴파일이 된다.
export 'unsupported.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.js_interop) 'web.dart';

/// 각 구현이 제공해야 하는 것
typedef OpenDatabase = QueryExecutor Function();

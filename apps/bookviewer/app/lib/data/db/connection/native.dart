import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 안드로이드·Windows·macOS·Linux — 번들 SQLite(FTS5 포함)를 파일로 연다
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'bookviewer.sqlite')),
    );
  });
}

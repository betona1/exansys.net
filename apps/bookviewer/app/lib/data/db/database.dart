import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// 앱 로컬 DB.
///
/// SQLite 는 `package:sqlite3` 3.x 가 직접 번들한다 (FTS5 포함).
/// `sqlite3_flutter_libs` 는 폐기되어 넣지 않는다 — ADR-0003 갱신 참고.
@DriftDatabase(
  tables: [Books, ReadingProgress, BookSettings, Anchors, Captures, Bookmarks, AppMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// 테스트용 — 메모리 DB
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // 외래키는 기본이 꺼져 있다. 켜지 않으면 참조 무결성이 조용히 무시된다
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'bookviewer.sqlite')),
    );
  });
}

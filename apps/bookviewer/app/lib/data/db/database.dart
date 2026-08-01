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
  tables: [
    Books,
    ReadingProgress,
    BookSettings,
    Anchors,
    Annotations,
    Captures,
    Bookmarks,
    PageTexts,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// 테스트용 — 메모리 DB
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createFts();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(pageTexts);
        await _createFts();
      }
      if (from < 3) {
        // 컬럼 추가만 한다. 테이블을 다시 만들면 사용자의 읽던 자리와 주석이 날아간다
        await m.addColumn(bookSettings, bookSettings.splitPages);
        await m.addColumn(bookSettings, bookSettings.splitRightToLeft);
        await m.addColumn(bookSettings, bookSettings.splitPrompted);
      }
      if (from < 4) {
        await m.addColumn(bookSettings, bookSettings.cropPrompted);
      }
      if (from < 5) {
        await m.addColumn(bookSettings, bookSettings.brightness);
        await m.addColumn(bookSettings, bookSettings.contrast);
      }
      if (from < 6) {
        await m.addColumn(bookSettings, bookSettings.landscapeHintShown);
      }
      if (from < 7) {
        // 주석 표를 빠뜨리고 있었다. DB스키마.xlsx 에는 처음부터 있었다
        await m.createTable(annotations);
      }
    },
    beforeOpen: (details) async {
      // 외래키는 기본이 꺼져 있다. 켜지 않으면 참조 무결성이 조용히 무시된다
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// FTS5 가상 테이블과 동기화 트리거.
  ///
  /// Drift 로는 가상 테이블을 선언할 수 없어 raw SQL 로 만든다.
  /// `content=` 로 외부 콘텐츠 방식을 쓴다 — 원문을 두 번 저장하지 않는다.
  /// 외부 콘텐츠 FTS5 는 자동 동기화가 없으므로 **트리거 3종이 필수**다.
  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS page_fts USING fts5(
        bigram,
        nospace,
        content='page_texts',
        content_rowid='id',
        tokenize='unicode61'
      )
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS page_texts_ai AFTER INSERT ON page_texts BEGIN
        INSERT INTO page_fts(rowid, bigram, nospace) VALUES (new.id, new.bigram, new.nospace);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS page_texts_ad AFTER DELETE ON page_texts BEGIN
        INSERT INTO page_fts(page_fts, rowid, bigram, nospace)
          VALUES ('delete', old.id, old.bigram, old.nospace);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS page_texts_au AFTER UPDATE ON page_texts BEGIN
        INSERT INTO page_fts(page_fts, rowid, bigram, nospace)
          VALUES ('delete', old.id, old.bigram, old.nospace);
        INSERT INTO page_fts(rowid, bigram, nospace) VALUES (new.id, new.bigram, new.nospace);
      END
    ''');
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'bookviewer.sqlite')),
    );
  });
}

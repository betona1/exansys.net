import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// 웹 — SQLite 를 WASM 으로 돌리고 IndexedDB(또는 OPFS)에 담는다.
///
/// `web/sqlite3.wasm` 과 `web/drift_worker.js` 가 있어야 한다.
/// 없으면 앱이 뜨자마자 죽으므로 배포 전에 반드시 확인한다.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'exapdf',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

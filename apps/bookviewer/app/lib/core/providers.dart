import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/library_repository_impl.dart';
import '../domain/entities/book.dart';
import '../domain/repositories/library_repository.dart';

/// 앱 전역 프로바이더.
///
/// `build()` 안에서 프로바이더를 만들지 않는다 — 여기서 한 번 만들고 `ref.watch` 로 구독만 한다
/// (CLAUDE.md §5).

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepositoryImpl(ref.watch(databaseProvider)),
);

/// 서재 목록. DB 가 바뀌면 화면이 알아서 따라온다
final booksProvider = StreamProvider<List<Book>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchBooks(),
);

/// 책 한 권 (읽기 화면이 쓴다)
final bookProvider = FutureProvider.family<Book?, int>(
  (ref, id) => ref.watch(libraryRepositoryProvider).findById(id),
);

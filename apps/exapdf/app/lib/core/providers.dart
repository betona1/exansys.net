import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/annotation_repository_impl.dart';
import '../data/repositories/library_repository_impl.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/entities/annotation.dart';
import '../domain/entities/book.dart';
import '../domain/repositories/annotation_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/search_repository.dart';

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

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(databaseProvider)),
);

/// 지금 돌고 있는 색인 작업. 없으면 null.
/// 검색 화면 상단에 "78% 인덱싱 중 — 결과가 늘어날 수 있습니다" 를 띄우는 데 쓴다 (techspec §12)
final indexProgressProvider = StateProvider<IndexProgress?>((ref) => null);

final annotationRepositoryProvider = Provider<AnnotationRepository>(
  (ref) => AnnotationRepositoryImpl(ref.watch(databaseProvider)),
);

/// 책 한 권의 하이라이트. DB 가 바뀌면 화면이 알아서 따라온다
final highlightsProvider = StreamProvider.family<List<Highlight>, int>(
  (ref, bookId) => ref.watch(annotationRepositoryProvider).watchHighlights(bookId),
);

final bookmarksProvider = StreamProvider.family<List<BookmarkEntry>, int>(
  (ref, bookId) => ref.watch(annotationRepositoryProvider).watchBookmarks(bookId),
);

import 'dart:ui';

import 'package:bookviewer/data/db/database.dart';
import 'package:bookviewer/data/repositories/annotation_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 하이라이트·북마크는 **원본 PDF 를 건드리지 않고** 앱 DB 에만 쌓인다 (ADR-0002).
/// 소프트 삭제를 지키는지도 함께 본다 — 물리 삭제하면 동기화 시 되살아난다.
void main() {
  late AppDatabase db;
  late AnnotationRepositoryImpl repo;
  late int bookId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AnnotationRepositoryImpl(db);
    final now = DateTime.now().toUtc().toIso8601String();
    bookId = await db.into(db.books).insert(
      BooksCompanion.insert(
        uuid: 'b1',
        filePath: '/tmp/b.pdf',
        fileChecksum: 'sum',
        addedAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() => db.close());

  group('하이라이트', () {
    test('넣고 쪽별로 찾는다', () async {
      await repo.addHighlight(
        bookId: bookId,
        pageNo: 7,
        rect: const Rect.fromLTRB(10, 20, 110, 60),
        colorSlot: 3,
        documentChecksum: 'sum',
      );

      final onPage = await repo.highlightsOfPage(bookId, 7);
      expect(onPage.length, 1);
      expect(onPage.single.colorSlot, 3);
      expect(onPage.single.rect, const Rect.fromLTRB(10, 20, 110, 60));

      expect(await repo.highlightsOfPage(bookId, 8), isEmpty);
    });

    test('색과 메모를 고친다', () async {
      final h = await repo.addHighlight(
        bookId: bookId,
        pageNo: 1,
        rect: const Rect.fromLTRB(0, 0, 10, 10),
        colorSlot: 1,
        documentChecksum: 'sum',
      );

      await repo.updateHighlight(h.id, colorSlot: 5, note: '다시 볼 것');
      final after = (await repo.highlightsOfPage(bookId, 1)).single;
      expect(after.colorSlot, 5);
      expect(after.note, '다시 볼 것');
    });

    test('색만 바꿔도 메모가 지워지지 않는다', () async {
      final h = await repo.addHighlight(
        bookId: bookId,
        pageNo: 1,
        rect: const Rect.fromLTRB(0, 0, 10, 10),
        colorSlot: 1,
        documentChecksum: 'sum',
      );
      await repo.updateHighlight(h.id, note: '남아 있어야 한다');
      await repo.updateHighlight(h.id, colorSlot: 2);

      final after = (await repo.highlightsOfPage(bookId, 1)).single;
      expect(after.note, '남아 있어야 한다');
      expect(after.colorSlot, 2);
    });

    test('삭제는 소프트 삭제다 — 행이 남는다', () async {
      final h = await repo.addHighlight(
        bookId: bookId,
        pageNo: 2,
        rect: const Rect.fromLTRB(0, 0, 10, 10),
        colorSlot: 1,
        documentChecksum: 'sum',
      );
      await repo.deleteHighlight(h.id);

      expect(await repo.highlightsOfPage(bookId, 2), isEmpty);
      final raw = await db.select(db.annotations).get();
      expect(raw.length, 1, reason: '물리 삭제하면 동기화 시 다른 기기에서 되살아난다');
      expect(raw.single.deletedAt, isNotNull);
    });

    test('쪽 순서로 나온다', () async {
      for (final page in [9, 3, 6]) {
        await repo.addHighlight(
          bookId: bookId,
          pageNo: page,
          rect: const Rect.fromLTRB(0, 0, 10, 10),
          colorSlot: 1,
          documentChecksum: 'sum',
        );
      }
      final all = await repo.watchHighlights(bookId).first;
      expect(all.map((h) => h.pageNo).toList(), [3, 6, 9]);
    });
  });

  group('북마크', () {
    test('토글로 넣고 뺀다', () async {
      expect(await repo.isBookmarked(bookId, 12), isFalse);

      expect(await repo.toggleBookmark(bookId: bookId, pageNo: 12), isTrue);
      expect(await repo.isBookmarked(bookId, 12), isTrue);

      expect(await repo.toggleBookmark(bookId: bookId, pageNo: 12), isFalse);
      expect(await repo.isBookmarked(bookId, 12), isFalse);
    });

    test('같은 쪽을 두 번 넣어도 하나만 남는다', () async {
      await repo.toggleBookmark(bookId: bookId, pageNo: 5);
      await repo.toggleBookmark(bookId: bookId, pageNo: 5); // 뺀다
      await repo.toggleBookmark(bookId: bookId, pageNo: 5); // 다시 넣는다

      final list = await repo.watchBookmarks(bookId).first;
      expect(list.where((b) => b.pageNo == 5).length, 1);
    });

    test('쪽 순서로 나온다', () async {
      for (final p in [20, 4, 11]) {
        await repo.toggleBookmark(bookId: bookId, pageNo: p);
      }
      final list = await repo.watchBookmarks(bookId).first;
      expect(list.map((b) => b.pageNo).toList(), [4, 11, 20]);
    });
  });
}

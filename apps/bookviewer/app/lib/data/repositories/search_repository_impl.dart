import 'package:drift/drift.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/korean.dart';
import '../../domain/entities/search_hit.dart';
import '../../domain/repositories/search_repository.dart';
import '../db/database.dart';
import '../source/book_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<IndexProgress> indexBook(int bookId, {bool force = false}) async* {
    final book = await (_db.select(_db.books)..where((t) => t.id.equals(bookId))).getSingleOrNull();
    if (book == null) return;
    if (book.isIndexed && !force) {
      yield IndexProgress(bookId: bookId, done: book.pageCount, total: book.pageCount);
      return;
    }

    await clearIndex(bookId: bookId);

    // 뷰어와 별개로 문서를 연다. **점진 로드를 끈다** —
    // 켜져 있으면 1쪽 말고는 loadText() 가 조용히 빈 값을 준다
    // (docs/engine-verification.md 의 점진 로드 함정).
    // 웹은 경로가 없어 담아 둔 바이트로 연다
    final blob = await (_db.select(_db.bookBlobs)..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();
    final doc = blob != null
        ? await openDocument(book.filePath, bytes: blob.bytes)
        : await PdfDocument.openFile(book.filePath, useProgressiveLoading: false);
    try {
      final total = doc.pages.length;
      yield IndexProgress(bookId: bookId, done: 0, total: total);

      var hangulSum = 0.0;
      var textPages = 0;

      // 쪽마다 따로 INSERT 하면 매번 트랜잭션이 커밋된다.
      // 500쪽 실측에서 색인 5.6초 중 5.1초(92%)가 여기서 났다 —
      // 텍스트 추출(277ms)·정규화(166ms)·bigram(17ms) 을 다 합친 것보다 열 배 넘게 컸다.
      // 묶어서 한 번에 쓴다.
      const batchSize = 50;
      var pending = <PageTextsCompanion>[];

      Future<void> flush() async {
        if (pending.isEmpty) return;
        final rows = pending;
        pending = [];
        await _db.batch((b) => b.insertAll(_db.pageTexts, rows, mode: InsertMode.insertOrReplace));
      }

      for (var i = 0; i < total; i++) {
        final page = doc.pages[i];
        final raw = (await page.loadText())?.fullText ?? '';
        if (raw.trim().isNotEmpty) {
          textPages++;
          hangulSum += Korean.hangulRatio(raw);
          final norm = Korean.normalize(raw);
          pending.add(
            PageTextsCompanion.insert(
              bookId: bookId,
              pageNo: page.pageNumber,
              raw: raw,
              norm: norm,
              nospace: Korean.stripSpaces(norm),
              bigram: Korean.bigrams(norm),
            ),
          );
          if (pending.length >= batchSize) await flush();
        }
        yield IndexProgress(bookId: bookId, done: i + 1, total: total);
      }
      await flush();

      // 텍스트가 거의 없으면 스캔본이다. 검색이 안 된다는 것을 사용자에게 알려야 한다
      final hasTextLayer = textPages > 0 && textPages / total > 0.1;
      await (_db.update(_db.books)..where((t) => t.id.equals(bookId))).write(
        BooksCompanion(
          isIndexed: const Value(true),
          hasTextLayer: Value(hasTextLayer),
          pageCount: Value(total),
          updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
        ),
      );
      // 한글 비율이 비정상적으로 낮으면 CID 폰트가 깨진 것일 수 있다 (CLAUDE.md §6-5).
      // 판정만 해 두고 OCR 권유 UI 는 서버 작업이 생길 때 붙인다
      _lastHangulRatio = textPages == 0 ? 0 : hangulSum / textPages;
    } finally {
      await doc.dispose();
    }
  }

  double _lastHangulRatio = 0;

  /// 마지막으로 색인한 책의 한글 비율 (진단용)
  double get lastHangulRatio => _lastHangulRatio;

  @override
  Future<List<SearchHitGroup>> search(String query, {int? bookId, int limit = 200}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final rows = Korean.needsLikeFallback(trimmed)
        ? await _likeSearch(trimmed, bookId: bookId, limit: limit)
        : await _ftsSearch(trimmed, bookId: bookId, limit: limit);

    // 책별로 묶는다 (techspec §12)
    final grouped = <int, List<SearchHit>>{};
    final titles = <int, String>{};
    for (final hit in rows) {
      grouped.putIfAbsent(hit.bookId, () => []).add(hit);
      titles[hit.bookId] = hit.bookTitle;
    }
    final groups = grouped.entries
        .map((e) => SearchHitGroup(bookId: e.key, bookTitle: titles[e.key]!, hits: e.value))
        .toList()
      // 많이 걸린 책이 위로
      ..sort((a, b) => b.hits.length.compareTo(a.hits.length));
    return groups;
  }

  Future<List<SearchHit>> _ftsSearch(String query, {int? bookId, required int limit}) async {
    // 질의도 인덱싱과 **같은 변환**을 거쳐야 한다. 한쪽만 바꾸면 아무것도 안 걸린다
    final bigram = Korean.queryToBigram(query);
    if (bigram.isEmpty) return const [];

    // 토큰을 모두 포함해야 한다 — bigram 은 겹치므로 AND 가 곧 구(phrase) 근사가 된다.
    // 각 토큰을 따옴표로 감싸 FTS5 문법 문자가 섞여도 깨지지 않게 한다
    final match = bigram.split(' ').map((t) => '"${t.replaceAll('"', '""')}"').join(' AND ');

    final where = bookId == null ? '' : 'AND pt.book_id = ?3';
    final result = await _db
        .customSelect(
          '''
          SELECT pt.book_id AS book_id,
                 pt.page_no AS page_no,
                 b.title    AS title,
                 b.file_path AS file_path,
                 bm25(page_fts) AS score,
                 snippet(page_fts, 1, ?4, ?5, ' … ', 12) AS snip
            FROM page_fts
            JOIN page_texts pt ON pt.id = page_fts.rowid
            JOIN books b ON b.id = pt.book_id
           WHERE page_fts MATCH ?1
             AND b.deleted_at IS NULL
             $where
           ORDER BY score
           LIMIT ?2
          ''',
          variables: [
            Variable<String>(match),
            Variable<int>(limit),
            if (bookId != null) Variable<int>(bookId) else const Variable<int>(0),
            const Variable<String>(SearchHit.highlightStart),
            const Variable<String>(SearchHit.highlightEnd),
          ],
          readsFrom: {_db.pageTexts, _db.books},
        )
        .get();

    return result.map(_rowToHit).toList();
  }

  /// 한 글자 질의 — bigram 으로는 못 찾으므로 공백 제거 사본에서 LIKE 로 찾는다.
  /// 느리지만 한 글자 검색은 드물고, 없으면 "안 되는 기능"이 된다.
  Future<List<SearchHit>> _likeSearch(String query, {int? bookId, required int limit}) async {
    final needle = Korean.stripSpaces(Korean.normalize(query));
    if (needle.isEmpty) return const [];
    final where = bookId == null ? '' : 'AND pt.book_id = ?3';
    final result = await _db
        .customSelect(
          '''
          SELECT pt.book_id AS book_id,
                 pt.page_no AS page_no,
                 b.title    AS title,
                 b.file_path AS file_path,
                 0.0        AS score,
                 substr(pt.norm, 1, 120) AS snip
            FROM page_texts pt
            JOIN books b ON b.id = pt.book_id
           WHERE pt.nospace LIKE ?1 ESCAPE '\\'
             AND b.deleted_at IS NULL
             $where
           LIMIT ?2
          ''',
          variables: [
            Variable<String>('%${_escapeLike(needle)}%'),
            Variable<int>(limit),
            if (bookId != null) Variable<int>(bookId) else const Variable<int>(0),
          ],
          readsFrom: {_db.pageTexts, _db.books},
        )
        .get();
    return result.map(_rowToHit).toList();
  }

  SearchHit _rowToHit(QueryRow row) {
    final title = row.read<String?>('title');
    final path = row.read<String>('file_path');
    return SearchHit(
      bookId: row.read<int>('book_id'),
      bookTitle: (title == null || title.isEmpty) ? _titleFromPath(path) : title,
      pageNo: row.read<int>('page_no'),
      snippet: row.read<String>('snip'),
      score: row.read<double>('score'),
    );
  }

  @override
  Future<(int, int)> indexedCount() async {
    final total = await (_db.select(_db.books)..where((t) => t.deletedAt.isNull())).get();
    final indexed = total.where((b) => b.isIndexed).length;
    return (indexed, total.length);
  }

  @override
  Future<void> clearIndex({int? bookId}) async {
    if (bookId == null) {
      await _db.delete(_db.pageTexts).go();
      await (_db.update(_db.books)).write(const BooksCompanion(isIndexed: Value(false)));
    } else {
      await (_db.delete(_db.pageTexts)..where((t) => t.bookId.equals(bookId))).go();
      await (_db.update(_db.books)..where((t) => t.id.equals(bookId)))
          .write(const BooksCompanion(isIndexed: Value(false)));
    }
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static String _titleFromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}

import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_repository.dart';
import '../db/database.dart';

class AnnotationRepositoryImpl implements AnnotationRepository {
  AnnotationRepositoryImpl(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // ── 하이라이트 ─────────────────────────────────────────

  JoinedSelectStatement<HasResultSet, dynamic> _highlightQuery(int bookId) {
    final q = _db.select(_db.annotations).join([
      innerJoin(_db.anchors, _db.anchors.id.equalsExp(_db.annotations.anchorId)),
    ])..where(
        _db.annotations.bookId.equals(bookId) &
            _db.annotations.deletedAt.isNull() &
            _db.annotations.annoType.equals('highlight'),
      );
    q.orderBy([OrderingTerm.asc(_db.anchors.pageNo)]);
    return q;
  }

  Highlight _toHighlight(TypedResult row) {
    final a = row.readTable(_db.annotations);
    final anchor = row.readTable(_db.anchors);
    final coords = (jsonDecode(anchor.rects) as List<dynamic>).first as List<dynamic>;
    return Highlight(
      id: a.id,
      uuid: a.uuid,
      pageNo: anchor.pageNo,
      rect: Rect.fromLTRB(
        (coords[0] as num).toDouble(),
        (coords[1] as num).toDouble(),
        (coords[2] as num).toDouble(),
        (coords[3] as num).toDouble(),
      ),
      colorSlot: a.colorSlot,
      note: a.note,
    );
  }

  @override
  Stream<List<Highlight>> watchHighlights(int bookId) =>
      _highlightQuery(bookId).watch().map((rows) => rows.map(_toHighlight).toList());

  @override
  Future<List<Highlight>> highlightsOfPage(int bookId, int pageNo) async {
    final rows = await (_highlightQuery(bookId)..where(_db.anchors.pageNo.equals(pageNo))).get();
    return rows.map(_toHighlight).toList();
  }

  @override
  Future<Highlight> addHighlight({
    required int bookId,
    required int pageNo,
    required Rect rect,
    required int colorSlot,
    required String documentChecksum,
  }) async {
    final now = _now();
    // 앵커를 따로 두는 이유: 캡처와 같은 자리 참조를 공유하고,
    // 파일이 바뀌었을 때 원문·문맥으로 다시 붙일 수 있게 하기 위해서다 (ADR-0002)
    final anchorId = await _db.into(_db.anchors).insert(
      AnchorsCompanion.insert(
        uuid: _uuid.v4(),
        bookId: bookId,
        kind: const Value('area'),
        pageNo: pageNo,
        rects: jsonEncode([
          [rect.left, rect.top, rect.right, rect.bottom],
        ]),
        documentChecksum: documentChecksum,
        createdAt: now,
      ),
    );
    final id = await _db.into(_db.annotations).insert(
      AnnotationsCompanion.insert(
        uuid: _uuid.v4(),
        bookId: bookId,
        anchorId: anchorId,
        annoType: 'highlight',
        colorSlot: Value(colorSlot),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return Highlight(
      id: id,
      uuid: _uuid.v4(),
      pageNo: pageNo,
      rect: rect,
      colorSlot: colorSlot,
    );
  }

  @override
  Future<void> updateHighlight(int id, {int? colorSlot, String? note}) async {
    await (_db.update(_db.annotations)..where((t) => t.id.equals(id))).write(
      AnnotationsCompanion(
        colorSlot: colorSlot == null ? const Value.absent() : Value(colorSlot),
        note: note == null ? const Value.absent() : Value(note),
        updatedAt: Value(_now()),
      ),
    );
  }

  @override
  Future<void> deleteHighlight(int id) async {
    await (_db.update(_db.annotations)..where((t) => t.id.equals(id)))
        .write(AnnotationsCompanion(deletedAt: Value(_now()), updatedAt: Value(_now())));
  }

  // ── 북마크 ─────────────────────────────────────────────

  @override
  Stream<List<BookmarkEntry>> watchBookmarks(int bookId) {
    final q = _db.select(_db.bookmarks)
      ..where((t) => t.bookId.equals(bookId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.pageNo)]);
    return q.watch().map(
          (rows) => rows
              .map((r) => BookmarkEntry(id: r.id, uuid: r.uuid, pageNo: r.pageNo, label: r.label))
              .toList(),
        );
  }

  @override
  Future<bool> isBookmarked(int bookId, int pageNo) async {
    final row = await (_db.select(_db.bookmarks)
          ..where((t) => t.bookId.equals(bookId) & t.pageNo.equals(pageNo) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<bool> toggleBookmark({required int bookId, required int pageNo}) async {
    final existing = await (_db.select(_db.bookmarks)
          ..where((t) => t.bookId.equals(bookId) & t.pageNo.equals(pageNo) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (existing != null) {
      await deleteBookmark(existing.id);
      return false;
    }
    await _db.into(_db.bookmarks).insert(
      BookmarksCompanion.insert(
        uuid: _uuid.v4(),
        bookId: bookId,
        pageNo: pageNo,
        createdAt: _now(),
      ),
    );
    return true;
  }

  @override
  Future<void> deleteBookmark(int id) async {
    await (_db.update(_db.bookmarks)..where((t) => t.id.equals(id)))
        .write(BookmarksCompanion(deletedAt: Value(_now())));
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}

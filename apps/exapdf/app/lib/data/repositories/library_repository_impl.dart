import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/book.dart';
import '../../core/reading_filter.dart';
import '../../domain/entities/crop_rect.dart';
import '../../domain/entities/fit_mode.dart';
import '../../domain/entities/reading_theme.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/repositories/library_repository.dart';
import '../db/database.dart';
import '../source/book_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// 파일 전체를 해싱하면 300MB PDF 에서 UI 가 멈춘다.
  /// 앞 1MB + 크기로도 "같은 파일인가"를 가리기에 충분하다.
  static const _hashHeadBytes = 1024 * 1024;

  @override
  Future<List<Book>> listBooks() async {
    final rows = await _selectJoined().get();
    return rows.map(_toBook).toList();
  }

  @override
  Stream<List<Book>> watchBooks() =>
      _selectJoined().watch().map((rows) => rows.map(_toBook).toList());

  JoinedSelectStatement<HasResultSet, dynamic> _selectJoined() {
    final q = _db.select(_db.books).join([
      leftOuterJoin(_db.readingProgress, _db.readingProgress.bookId.equalsExp(_db.books.id)),
    ])..where(_db.books.deletedAt.isNull());
    // 최근 읽은 것이 위로. 한 번도 안 읽었으면 등록 순서로
    q.orderBy([
      OrderingTerm.desc(_db.readingProgress.lastReadAt),
      OrderingTerm.desc(_db.books.addedAt),
    ]);
    return q;
  }

  Book _toBook(TypedResult row) {
    final b = row.readTable(_db.books);
    final pr = row.readTableOrNull(_db.readingProgress);
    return Book(
      id: b.id,
      uuid: b.uuid,
      filePath: b.filePath,
      title: (b.title == null || b.title!.isEmpty) ? _titleFromPath(b.filePath) : b.title!,
      pageCount: b.pageCount,
      lastPage: pr?.lastPage ?? 1,
      farthestPage: pr?.farthestPage ?? 1,
      addedAt: DateTime.parse(b.addedAt),
      author: b.author,
      coverPath: b.coverPath,
      lastReadAt: pr?.lastReadAt == null ? null : DateTime.tryParse(pr!.lastReadAt!),
      hasTextLayer: b.hasTextLayer,
      // 책장에서 지우지 않는다. 배지로 알리고 "위치 다시 지정"을 유도한다 (techspec §13)
      // 웹은 바이트를 들고 있으므로 사라질 일이 없다
      fileMissing: !sourceExists(b.filePath),
    );
  }

  @override
  Future<Book> addBook(BookSource source) async {
    final filePath = source.locator;
    final checksum = await _checksum(source);
    final size = source.size;
    final now = _now();

    // 같은 파일이 이미 있으면 새로 만들지 않는다. 파일을 옮겼으면 경로만 고쳐 준다
    final existing = await (_db.select(_db.books)
          ..where((t) => t.fileChecksum.equals(checksum) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.filePath != filePath) {
        await (_db.update(_db.books)..where((t) => t.id.equals(existing.id)))
            .write(BooksCompanion(filePath: Value(filePath), updatedAt: Value(now)));
      }
      return (await findById(existing.id))!;
    }

    final id = await _db.into(_db.books).insert(
          BooksCompanion.insert(
            uuid: _uuid.v4(),
            filePath: filePath,
            fileChecksum: checksum,
            fileSize: Value(size),
            title: Value(_titleFromPath(source.displayName)),
            addedAt: now,
            updatedAt: now,
          ),
        );
    // 웹은 경로가 없어 원본을 들고 있어야 다시 열 수 있다
    final blob = source.bytesToStore;
    if (blob != null) {
      await _db.into(_db.bookBlobs).insert(
            BookBlobsCompanion.insert(bookId: Value(id), bytes: blob),
          );
    }
    await _db.into(_db.readingProgress).insert(
          ReadingProgressCompanion.insert(bookId: Value(id)),
          mode: InsertMode.insertOrIgnore,
        );
    await _db.into(_db.bookSettings).insert(
          BookSettingsCompanion.insert(bookId: Value(id), updatedAt: now),
          mode: InsertMode.insertOrIgnore,
        );
    return (await findById(id))!;
  }

  @override
  Future<Book?> findById(int id) async {
    final rows = await (_selectJoined()..where(_db.books.id.equals(id))).get();
    return rows.isEmpty ? null : _toBook(rows.first);
  }

  @override
  Future<void> saveProgress(int bookId, {required int lastPage, int? pageCount}) async {
    final current = await (_db.select(_db.readingProgress)
          ..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();

    // 가장 멀리 읽은 쪽은 뒤로 가지 않는다.
    // 검색·목차로 앞쪽에 갔다 왔다고 진도가 줄어들면 사용자가 진도율을 신뢰하지 않게 된다
    final farthest = current == null ? lastPage : (lastPage > current.farthestPage ? lastPage : current.farthestPage);
    final total = pageCount ?? (await findById(bookId))?.pageCount ?? 0;
    final percent = total > 0 ? (farthest / total * 100).clamp(0, 100).toDouble() : 0.0;
    final now = _now();

    await _db.into(_db.readingProgress).insertOnConflictUpdate(
          ReadingProgressCompanion.insert(
            bookId: Value(bookId),
            lastPage: Value(lastPage),
            farthestPage: Value(farthest),
            percent: Value(percent),
            status: Value(total > 0 && farthest >= total ? 'finished' : 'reading'),
            lastReadAt: Value(now),
            finishedAt: Value(total > 0 && farthest >= total ? now : current?.finishedAt),
          ),
        );
  }

  @override
  Future<void> updateDocumentInfo(
    int bookId, {
    required int pageCount,
    required bool hasTextLayer,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId))).write(
      BooksCompanion(
        pageCount: Value(pageCount),
        hasTextLayer: Value(hasTextLayer),
        updatedAt: Value(_now()),
      ),
    );
  }

  @override
  Future<void> removeBook(int bookId) async {
    // 소프트 삭제. 물리 삭제하면 동기화 시 다른 기기에서 되살아난다 (CLAUDE.md §7).
    // 원본 PDF 파일은 건드리지 않는다
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId)))
        .write(BooksCompanion(deletedAt: Value(_now()), updatedAt: Value(_now())));
  }

  @override
  Future<ReaderSettings> readerSettings(int bookId) async {
    final row = await (_db.select(_db.bookSettings)..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();
    if (row == null) return const ReaderSettings();
    return ReaderSettings(
      splitPages: row.splitPages,
      splitRightToLeft: row.splitRightToLeft,
      splitPrompted: row.splitPrompted,
      cropEnabled: row.cropEnabled,
      cropOdd: CropRect.fromJson(row.cropOdd),
      cropEven: CropRect.fromJson(row.cropEven),
      cropPrompted: row.cropPrompted,
      theme: ReadingTheme.parse(row.theme),
      darkImageMode: DarkImageMode.parse(row.darkImageMode),
      brightness: row.brightness,
      contrast: row.contrast,
      fitMode: FitMode.parse(row.fitMode),
      landscapeHintShown: row.landscapeHintShown,
      zoomLocked: row.zoomLocked,
      zoomLevel: row.zoomLevel,
      panX: row.panX,
    );
  }

  @override
  Future<void> saveReaderSettings(int bookId, ReaderSettings settings) async {
    await _db.into(_db.bookSettings).insertOnConflictUpdate(
          BookSettingsCompanion.insert(
            bookId: Value(bookId),
            splitPages: Value(settings.splitPages),
            splitRightToLeft: Value(settings.splitRightToLeft),
            splitPrompted: Value(settings.splitPrompted),
            cropEnabled: Value(settings.cropEnabled),
            cropOdd: Value(settings.cropOdd?.toJson()),
            cropEven: Value(settings.cropEven?.toJson()),
            cropPrompted: Value(settings.cropPrompted),
            theme: Value(settings.theme.storageValue),
            darkImageMode: Value(settings.darkImageMode.storageValue),
            brightness: Value(settings.brightness),
            contrast: Value(settings.contrast),
            fitMode: Value(settings.fitMode.storageValue),
            landscapeHintShown: Value(settings.landscapeHintShown),
            zoomLocked: Value(settings.zoomLocked),
            zoomLevel: Value(settings.zoomLevel),
            panX: Value(settings.panX),
            updatedAt: _now(),
          ),
        );
  }

  @override
  Future<Uint8List?> bookBytes(int bookId) async {
    final row = await (_db.select(_db.bookBlobs)..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();
    return row?.bytes;
  }

  /// 앞 [_hashHeadBytes] + 파일 크기로 만든 SHA-256.
  ///
  /// 파일 전체를 해싱하면 300MB PDF 에서 UI 가 멈춘다.
  Future<String> _checksum(BookSource source) async {
    final bytes = source.bytesToStore;
    if (bytes != null) {
      final head = bytes.length <= _hashHeadBytes
          ? bytes
          : Uint8List.sublistView(bytes, 0, _hashHeadBytes);
      return sha256.convert([...head, ...'${source.size}'.codeUnits]).toString();
    }
    return sha256
        .convert([...await readHead(source.locator, _hashHeadBytes), ...'${source.size}'.codeUnits])
        .toString();
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  static String _titleFromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}

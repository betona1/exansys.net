import 'package:bookviewer/core/korean.dart';
import 'package:bookviewer/data/db/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// FTS5 + bigram 파이프라인이 **실제 SQLite 에서** 동작하는지 확인한다.
///
/// ADR-0003 이 요구하는 것: 조사가 붙어도 어간이 걸릴 것, **2글자 검색어가 동작할 것**.
/// 단위 테스트에서 bigram 문자열만 맞춰 봐야 소용없다 — FTS5 가상 테이블과 트리거가
/// 제대로 걸려 있어야 검색이 된다.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 마이그레이션(FTS5 가상 테이블 + 트리거 3종)을 실제로 돌린다
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<int> addBook(String title) async {
    final now = DateTime.now().toUtc().toIso8601String();
    return db.into(db.books).insert(
          BooksCompanion.insert(
            uuid: 'uuid-$title',
            filePath: '/tmp/$title.pdf',
            fileChecksum: 'sum-$title',
            title: Value(title),
            addedAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> addPage(int bookId, int pageNo, String text) async {
    final norm = Korean.normalize(text);
    await db.into(db.pageTexts).insert(
          PageTextsCompanion.insert(
            bookId: bookId,
            pageNo: pageNo,
            raw: text,
            norm: norm,
            nospace: Korean.stripSpaces(norm),
            bigram: Korean.bigrams(norm),
          ),
        );
  }

  Future<List<int>> find(String query) async {
    final bigram = Korean.queryToBigram(query);
    final match = bigram.split(' ').map((t) => '"$t"').join(' AND ');
    final rows = await db.customSelect(
      '''
      SELECT pt.page_no AS page_no
        FROM page_fts
        JOIN page_texts pt ON pt.id = page_fts.rowid
       WHERE page_fts MATCH ?1
       ORDER BY bm25(page_fts)
      ''',
      variables: [Variable<String>(match)],
    ).get();
    return rows.map((r) => r.read<int>('page_no')).toList();
  }

  test('FTS5 가 켜져 있다 — 없으면 한국어 검색이 통째로 죽는다', () async {
    final row = await db.customSelect(
      "SELECT sqlite_compileoption_used('ENABLE_FTS5') AS on_",
    ).getSingle();
    expect(row.read<int>('on_'), 1, reason: 'sqlite3 번들에 FTS5 가 있어야 한다 (ADR-0003)');
  });

  test('조사가 붙어도 어간으로 찾는다', () async {
    final book = await addBook('책1');
    await addPage(book, 7, '머신러닝을 배우는 과정');
    await addPage(book, 9, '통계학의 기초');

    expect(await find('머신러닝'), [7], reason: 'unicode61 토크나이저로는 안 되는 경우다');
  });

  test('2글자 검색어가 동작한다 — 한국어에서 매우 흔하다', () async {
    final book = await addBook('책2');
    await addPage(book, 1, '인공지능과 기계학습 입문');
    await addPage(book, 2, '경제학 원론');

    expect(await find('인공'), [1]);
    expect(await find('학습'), [1]);
    expect(await find('경제'), [2]);
  });

  test('여러 쪽에 걸쳐 찾는다', () async {
    final book = await addBook('책3');
    await addPage(book, 1, '검색은 문서 전체에서 이루어져야 한다');
    await addPage(book, 2, '복사와 캡처');
    await addPage(book, 3, '검색 결과에서 바로 이동한다');

    expect(await find('검색'), containsAll([1, 3]));
  });

  test('없는 낱말은 찾지 않는다', () async {
    final book = await addBook('책4');
    await addPage(book, 1, '한국어 문서');
    expect(await find('존재하지않는낱말'), isEmpty);
  });

  test('영어는 쪼개지 않고 그대로 찾는다', () async {
    final book = await addBook('책5');
    await addPage(book, 1, 'machine learning basics');
    expect(await find('learning'), [1]);
    expect(await find('machine'), [1]);
  });

  test('페이지를 지우면 색인에서도 빠진다 — 트리거 확인', () async {
    final book = await addBook('책6');
    await addPage(book, 1, '지워질 내용');
    expect(await find('지워질'), [1]);

    await (db.delete(db.pageTexts)..where((t) => t.bookId.equals(book))).go();
    expect(await find('지워질'), isEmpty, reason: 'AFTER DELETE 트리거가 없으면 유령 결과가 남는다');
  });

  test('페이지를 고치면 색인도 따라온다 — 트리거 확인', () async {
    final book = await addBook('책7');
    await addPage(book, 1, '옛날 내용');

    const fresh = '새로운 내용';
    final norm = Korean.normalize(fresh);
    await (db.update(db.pageTexts)..where((t) => t.bookId.equals(book))).write(
      PageTextsCompanion(
        raw: const Value(fresh),
        norm: Value(norm),
        nospace: Value(Korean.stripSpaces(norm)),
        bigram: Value(Korean.bigrams(norm)),
      ),
    );

    expect(await find('옛날'), isEmpty);
    expect(await find('새로운'), [1]);
  });
}

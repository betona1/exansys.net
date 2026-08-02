import 'dart:io';

import 'package:exapdf/data/db/database.dart';
import 'package:exapdf/data/repositories/library_repository_impl.dart';
import 'package:exapdf/data/source/book_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 순수 로직 위주로 검증한다 (CLAUDE.md §9 — UI 위젯 테스트는 강제하지 않는다).
/// 특히 **진행률 계산**은 반드시 테스트하라고 못박혀 있다.
void main() {
  late AppDatabase db;
  late LibraryRepositoryImpl repo;
  late Directory tmp;
  late File pdf;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LibraryRepositoryImpl(db);
    tmp = await Directory.systemTemp.createTemp('exapdf_test');
    pdf = File('${tmp.path}${Platform.pathSeparator}책.pdf')
      ..writeAsBytesSync(List<int>.generate(2048, (i) => i % 256));
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('같은 파일을 두 번 넣어도 책이 하나만 생긴다', () async {
    final a = await repo.addBook(FileBookSource(File(pdf.path)));
    final b = await repo.addBook(FileBookSource(File(pdf.path)));
    expect(a.id, b.id);
    expect((await repo.listBooks()).length, 1);
  });

  test('파일을 옮기면 새 책이 아니라 경로만 갱신된다', () async {
    final first = await repo.addBook(FileBookSource(File(pdf.path)));
    final moved = File('${tmp.path}${Platform.pathSeparator}옮긴책.pdf');
    pdf.copySync(moved.path);

    final again = await repo.addBook(FileBookSource(File(moved.path)));
    expect(again.id, first.id, reason: 'checksum 이 같으면 같은 책이다');
    expect(again.filePath, moved.path);
    expect((await repo.listBooks()).length, 1);
  });

  test('가장 멀리 읽은 쪽은 뒤로 가지 않는다', () async {
    final book = await repo.addBook(FileBookSource(File(pdf.path)));
    await repo.updateDocumentInfo(book.id, pageCount: 200, hasTextLayer: true);

    await repo.saveProgress(book.id, lastPage: 120, pageCount: 200);
    expect((await repo.findById(book.id))!.farthestPage, 120);

    // 검색·목차로 앞쪽으로 점프한 상황. 진도율이 줄면 안 된다
    await repo.saveProgress(book.id, lastPage: 10, pageCount: 200);
    final after = (await repo.findById(book.id))!;
    expect(after.lastPage, 10, reason: '다시 열면 방금 보던 자리로 간다');
    expect(after.farthestPage, 120, reason: '진도는 뒤로 가지 않는다');
    expect(after.progress, closeTo(0.6, 0.001));
  });

  test('쪽 수를 모르면 진행률은 0 이다', () async {
    final book = await repo.addBook(FileBookSource(File(pdf.path)));
    await repo.saveProgress(book.id, lastPage: 5);
    expect((await repo.findById(book.id))!.progress, 0.0);
  });

  test('서재에서 빼도 원본 파일은 남는다', () async {
    final book = await repo.addBook(FileBookSource(File(pdf.path)));
    await repo.removeBook(book.id);

    expect(await repo.listBooks(), isEmpty);
    expect(pdf.existsSync(), isTrue, reason: '원본 PDF 를 지우지 않는다 (절대 규칙 2)');
  });

  test('파일이 사라지면 목록에서 빼지 않고 표시만 한다', () async {
    final book = await repo.addBook(FileBookSource(File(pdf.path)));
    pdf.deleteSync();

    final list = await repo.listBooks();
    expect(list.length, 1, reason: '책장에서 지우면 사용자가 되찾을 방법이 없다');
    expect(list.single.fileMissing, isTrue);
    expect(book.fileMissing, isFalse);
  });
}

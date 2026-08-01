import 'package:bookviewer/models/book_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1754000000000);

  test('책 정보를 저장했다가 그대로 읽어 온다', () {
    final books = [
      BookEntry(path: r'E:\books\한글 제목.pdf', title: '한글 제목', lastPage: 42, pageCount: 300, openedAt: now),
      BookEntry(path: '/home/u/manual.pdf', title: 'manual', openedAt: now),
    ];
    final back = BookEntry.decodeList(BookEntry.encodeList(books));

    expect(back.length, 2);
    expect(back[0].path, r'E:\books\한글 제목.pdf');
    expect(back[0].title, '한글 제목');
    expect(back[0].lastPage, 42);
    expect(back[0].pageCount, 300);
    expect(back[0].openedAt, now);
    expect(back[1].lastPage, 1, reason: '기본값은 1쪽');
  });

  test('저장된 내용이 깨져도 앱이 죽지 않고 빈 책장이 된다', () {
    expect(BookEntry.decodeList(null), isEmpty);
    expect(BookEntry.decodeList(''), isEmpty);
    expect(BookEntry.decodeList('{이건 JSON 이 아니다'), isEmpty);
  });

  test('진행률은 쪽 수를 알 때만 계산한다', () {
    expect(BookEntry(path: 'a', title: 'a', lastPage: 5, openedAt: now).progress, 0.0);
    expect(
      BookEntry(path: 'a', title: 'a', lastPage: 50, pageCount: 200, openedAt: now).progress,
      0.25,
    );
    expect(
      BookEntry(path: 'a', title: 'a', lastPage: 500, pageCount: 200, openedAt: now).progress,
      1.0,
      reason: '쪽 수를 넘겨도 100% 를 넘지 않는다',
    );
  });
}

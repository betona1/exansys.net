import 'dart:convert';
import 'dart:ui';

import 'package:bookviewer/domain/entities/annotation.dart';
import 'package:bookviewer/domain/entities/book.dart';
import 'package:bookviewer/features/annotation/export.dart';
import 'package:bookviewer/features/annotation/quote_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

final _book = Book(
  id: 7,
  uuid: 'book-uuid',
  filePath: r'E:\books\딥러닝입문.pdf',
  title: '딥러닝입문',
  pageCount: 300,
  lastPage: 12,
  farthestPage: 40,
  addedAt: DateTime.utc(2026),
);

Highlight _h(int page, int slot, {String? note, String uuid = 'h1'}) => Highlight(
  id: page,
  uuid: uuid,
  pageNo: page,
  rect: const Rect.fromLTRB(10, 20, 200, 60),
  colorSlot: slot,
  note: note,
);

void main() {
  group('좌표 뒤집기', () {
    // 우리 좌표는 좌상단 원점·Y 아래, PdfRect 는 좌하단 원점·Y 위다.
    // 이 변환을 빠뜨리면 쪽의 위아래가 뒤집힌 자리의 글이 딸려 온다
    test('렌더 좌표를 PDF 좌표로 뒤집는다', () {
      final r = QuoteExtractor.toPdfRect(const Rect.fromLTRB(10, 100, 50, 140), 800);
      expect(r.left, 10);
      expect(r.right, 50);
      expect(r.top, 700, reason: '800 - 100');
      expect(r.bottom, 660, reason: '800 - 140');
      expect(r.top, greaterThan(r.bottom), reason: 'PdfRect 는 top 이 더 크다');
    });

    test('겹침 판정', () {
      const a = PdfRect(0, 100, 50, 50); // top=100, bottom=50
      expect(QuoteExtractor.overlaps(a, const PdfRect(25, 80, 75, 60)), isTrue);
      expect(QuoteExtractor.overlaps(a, const PdfRect(60, 100, 90, 50)), isFalse, reason: '오른쪽');
      expect(QuoteExtractor.overlaps(a, const PdfRect(0, 40, 50, 10)), isFalse, reason: '아래');
    });
  });

  group('Markdown', () {
    test('딥링크를 반드시 붙인다 — 없으면 돌아갈 수 없는 죽은 텍스트다', () {
      final md = AnnotationExport.build(
        book: _book,
        items: [ExportItem(highlight: _h(128, 1), quote: '중요한 문장')],
        bookmarks: const [],
        format: ExportFormat.markdown,
      );
      expect(md, contains('bookviewer://book/7/page/128?anno=h1'));
      expect(md, contains('> 중요한 문장'));
      expect(md, contains('p.128'));
      expect(md, contains('중요'), reason: '색 슬롯의 뜻을 글로도 적는다');
    });

    test('원문을 못 뽑았으면 감추지 않고 밝힌다', () {
      final md = AnnotationExport.build(
        book: _book,
        items: [ExportItem(highlight: _h(5, 2))],
        bookmarks: const [],
        format: ExportFormat.markdown,
      );
      expect(md, contains('스캔본이라 원문을 뽑지 못했습니다'));
    });

    test('메모를 함께 낸다', () {
      final md = AnnotationExport.build(
        book: _book,
        items: [ExportItem(highlight: _h(3, 4, note: '다시 볼 것'), quote: '문장')],
        bookmarks: const [],
        format: ExportFormat.markdown,
      );
      expect(md, contains('메모: 다시 볼 것'));
    });

    test('북마크도 링크로 낸다', () {
      final md = AnnotationExport.build(
        book: _book,
        items: const [],
        bookmarks: [const BookmarkEntry(id: 1, uuid: 'bm', pageNo: 44)],
        format: ExportFormat.markdown,
      );
      expect(md, contains('[p.44](bookviewer://book/7/page/44)'));
    });

    test('Obsidian 은 앞머리 속성을 붙인다', () {
      final md = AnnotationExport.build(
        book: _book,
        items: [ExportItem(highlight: _h(1, 1), quote: 'q')],
        bookmarks: const [],
        format: ExportFormat.obsidian,
      );
      expect(md.startsWith('---'), isTrue);
      expect(md, contains('title: "딥러닝입문"'));
    });

    test('빈 목록도 깨지지 않는다', () {
      final md = AnnotationExport.build(
        book: _book,
        items: const [],
        bookmarks: const [],
        format: ExportFormat.markdown,
      );
      expect(md, contains('표시해 둔 것이 없습니다'));
    });
  });

  group('JSON', () {
    test('다시 읽을 수 있는 모양이다', () {
      final json = AnnotationExport.build(
        book: _book,
        items: [ExportItem(highlight: _h(9, 3, note: 'm'), quote: '인용')],
        bookmarks: [const BookmarkEntry(id: 1, uuid: 'bm', pageNo: 2)],
        format: ExportFormat.json,
      );
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect((data['book'] as Map)['title'], '딥러닝입문');

      final h = ((data['highlights'] as List).single) as Map<String, dynamic>;
      expect(h['page'], 9);
      expect(h['quote'], '인용');
      expect(h['note'], 'm');
      expect(h['colorLabel'], '인용 후보');
      expect((h['rect'] as List).length, 4);
      expect(h['link'], contains('anno=h1'));

      expect((data['bookmarks'] as List).length, 1);
    });
  });

  group('CSV', () {
    test('쉼표·따옴표·줄바꿈이 든 글도 표를 깨뜨리지 않는다', () {
      final csv = AnnotationExport.build(
        book: _book,
        items: [
          ExportItem(
            highlight: _h(1, 1, note: '따옴표 "인용" 포함'),
            quote: '쉼표, 그리고\n줄바꿈',
          ),
        ],
        bookmarks: const [],
        format: ExportFormat.csv,
      );
      final lines = csv.trimRight().split('\n');
      expect(lines.first, 'page,color,quote,note,link');
      // 줄바꿈은 따옴표 안에 있으므로 데이터 줄은 이어져 있다
      expect(csv, contains('""인용""'), reason: '따옴표는 두 번 겹쳐 쓴다');
      expect(csv, contains('"쉼표, 그리고'));
    });
  });

  test('파일 이름에 경로 문자를 남기지 않는다', () {
    final book = Book(
      id: 1,
      uuid: 'u',
      filePath: '/x.pdf',
      title: 'a/b:c*d?.pdf',
      pageCount: 1,
      lastPage: 1,
      farthestPage: 1,
      addedAt: DateTime.utc(2026),
    );
    final name = AnnotationExport.fileName(book, ExportFormat.markdown);
    expect(name, isNot(contains('/')));
    expect(name, isNot(contains(':')));
    expect(name.endsWith('.md'), isTrue);
  });
}

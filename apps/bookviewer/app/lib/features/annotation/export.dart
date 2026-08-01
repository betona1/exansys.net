import 'dart:convert';

import '../../core/tokens.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/book.dart';

/// 내보내기 형식 (techspec §7).
enum ExportFormat {
  markdown('Markdown', 'md'),
  obsidian('Obsidian', 'md'),
  json('JSON', 'json'),
  csv('CSV', 'csv');

  const ExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

/// 하이라이트 하나에 원문을 붙인 것. 스캔본은 원문이 없어 null 이다
class ExportItem {
  const ExportItem({required this.highlight, this.quote});

  final Highlight highlight;
  final String? quote;
}

/// 하이라이트·북마크를 밖으로 꺼낸다.
///
/// 쌓아 두기만 하고 꺼낼 수 없으면 락인이다. 언제든 내보낼 수 있다는 것이
/// 앱 DB 를 정본으로 삼는 근거였다 (ADR-0002).
///
/// **딥링크를 반드시 붙인다.** 없이 내보낸 노트는 원문으로 돌아갈 수 없는
/// 죽은 텍스트가 된다 (ADR-0002).
abstract final class AnnotationExport {
  /// `bookviewer://book/{id}/page/{n}?anno={uuid}`
  static String deepLink(int bookId, int pageNo, [String? annoUuid]) {
    final base = 'bookviewer://book/$bookId/page/$pageNo';
    return annoUuid == null ? base : '$base?anno=$annoUuid';
  }

  static String fileName(Book book, ExportFormat format) {
    final safe = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    return '$safe.${format.extension}';
  }

  static String build({
    required Book book,
    required List<ExportItem> items,
    required List<BookmarkEntry> bookmarks,
    required ExportFormat format,
  }) =>
      switch (format) {
        ExportFormat.markdown => _markdown(book, items, bookmarks, obsidian: false),
        ExportFormat.obsidian => _markdown(book, items, bookmarks, obsidian: true),
        ExportFormat.json => _json(book, items, bookmarks),
        ExportFormat.csv => _csv(book, items),
      };

  static String _markdown(
    Book book,
    List<ExportItem> items,
    List<BookmarkEntry> bookmarks, {
    required bool obsidian,
  }) {
    final out = StringBuffer();

    if (obsidian) {
      // Obsidian 은 앞머리 속성(frontmatter)으로 검색·정렬한다
      out
        ..writeln('---')
        ..writeln('title: "${book.title}"')
        ..writeln('source: bookviewer')
        ..writeln('pages: ${book.pageCount}')
        ..writeln('highlights: ${items.length}')
        ..writeln('---')
        ..writeln();
    }

    out
      ..writeln('# ${book.title}')
      ..writeln();

    if (items.isEmpty && bookmarks.isEmpty) {
      out.writeln('_표시해 둔 것이 없습니다._');
      return out.toString();
    }

    if (items.isNotEmpty) {
      out
        ..writeln('## 하이라이트')
        ..writeln();
      for (final item in items) {
        final h = item.highlight;
        final label = AppTokens.highlightLabels[h.colorSlot - 1];
        out.writeln('### p.${h.pageNo} · $label');
        final quote = item.quote;
        if (quote != null && quote.isNotEmpty) {
          for (final line in quote.split('\n')) {
            out.writeln('> $line');
          }
        } else {
          // 스캔본은 글자 레이어가 없어 원문을 뽑을 수 없다. 감추지 않고 밝힌다
          out.writeln('> _(스캔본이라 원문을 뽑지 못했습니다)_');
        }
        if (h.note?.isNotEmpty ?? false) {
          out
            ..writeln()
            ..writeln('메모: ${h.note}');
        }
        out
          ..writeln()
          ..writeln('[원문으로](${deepLink(book.id, h.pageNo, h.uuid)})')
          ..writeln();
      }
    }

    if (bookmarks.isNotEmpty) {
      out
        ..writeln('## 북마크')
        ..writeln();
      for (final b in bookmarks) {
        out.writeln('- [p.${b.pageNo}](${deepLink(book.id, b.pageNo)})');
      }
      out.writeln();
    }
    return out.toString();
  }

  static String _json(Book book, List<ExportItem> items, List<BookmarkEntry> bookmarks) {
    final data = {
      'book': {
        'uuid': book.uuid,
        'title': book.title,
        'pageCount': book.pageCount,
        'fileName': book.fileName,
      },
      'highlights': [
        for (final item in items)
          {
            'uuid': item.highlight.uuid,
            'page': item.highlight.pageNo,
            'colorSlot': item.highlight.colorSlot,
            'colorLabel': AppTokens.highlightLabels[item.highlight.colorSlot - 1],
            'rect': [
              item.highlight.rect.left,
              item.highlight.rect.top,
              item.highlight.rect.right,
              item.highlight.rect.bottom,
            ],
            'quote': item.quote,
            'note': item.highlight.note,
            'link': deepLink(book.id, item.highlight.pageNo, item.highlight.uuid),
          },
      ],
      'bookmarks': [
        for (final b in bookmarks)
          {'uuid': b.uuid, 'page': b.pageNo, 'link': deepLink(book.id, b.pageNo)},
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String _csv(Book book, List<ExportItem> items) {
    String cell(String? v) {
      final s = v ?? '';
      // 쉼표·따옴표·줄바꿈이 들어가면 표가 깨진다
      if (s.contains(RegExp('[,"\n]'))) return '"${s.replaceAll('"', '""')}"';
      return s;
    }

    final out = StringBuffer()..writeln('page,color,quote,note,link');
    for (final item in items) {
      final h = item.highlight;
      out.writeln(
        [
          '${h.pageNo}',
          cell(AppTokens.highlightLabels[h.colorSlot - 1]),
          cell(item.quote),
          cell(h.note),
          cell(deepLink(book.id, h.pageNo, h.uuid)),
        ].join(','),
      );
    }
    return out.toString();
  }
}

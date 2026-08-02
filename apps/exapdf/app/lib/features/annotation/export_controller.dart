import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import '../../domain/entities/book.dart';
import 'export.dart';
import 'quote_extractor.dart';

final exportControllerProvider = Provider<ExportController>(ExportController.new);

/// 하이라이트·북마크를 파일로 꺼내 공유한다.
class ExportController {
  ExportController(this._ref);

  final Ref _ref;

  /// 파일을 만들어 돌려준다. 공유는 화면이 정한다.
  Future<Result<File>> export({
    required Book book,
    required ExportFormat format,
    PdfDocument? doc,
  }) async {
    try {
      final repo = _ref.read(annotationRepositoryProvider);
      final highlights = await repo.watchHighlights(book.id).first;
      final bookmarks = await repo.watchBookmarks(book.id).first;

      // 하이라이트 자리의 원문을 뽑는다. 스캔본은 못 뽑으므로 null 로 둔다
      final items = <ExportItem>[];
      final textCache = <int, PdfPageText?>{};
      for (final h in highlights) {
        String? quote;
        if (doc != null && h.pageNo <= doc.pages.length) {
          final page = doc.pages[h.pageNo - 1];
          final text = textCache.putIfAbsent(h.pageNo, () => null) ??
              await page.loadStructuredText();
          textCache[h.pageNo] = text;
          final extracted = QuoteExtractor.extract(
            text: text,
            rect: h.rect,
            pageHeight: page.height,
          );
          if (extracted.isNotEmpty) quote = extracted;
        }
        items.add(ExportItem(highlight: h, quote: quote));
      }

      final content = AnnotationExport.build(
        book: book,
        items: items,
        bookmarks: bookmarks,
        format: format,
      );

      final dir = await getApplicationDocumentsDirectory();
      final out = Directory('${dir.path}${Platform.pathSeparator}exports');
      if (!out.existsSync()) await out.create(recursive: true);
      final file = File(
        '${out.path}${Platform.pathSeparator}${AnnotationExport.fileName(book, format)}',
      );
      await file.writeAsString(content, flush: true);
      return Result.ok(file);
    } on Object catch (e) {
      return Result.failed('내보내지 못했습니다 — $e');
    }
  }

  /// 만든 파일이 어디 있는지 알려 준다.
  ///
  /// 시스템 공유 시트는 share_plus 가 맡았는데, 그 패키지가 Kotlin Gradle Plugin 을
  /// 적용해 AGP 9 의 내장 Kotlin 과 부딪힌다. file_picker 와는 win32 버전도 충돌해
  /// 둘을 함께 쓸 수 없다. 우선 경로를 보여 주고, 공유는 따로 붙인다.
  String whereIs(File file) => file.path;
}

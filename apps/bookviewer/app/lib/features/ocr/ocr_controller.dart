import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../core/korean.dart';
import '../../data/db/database.dart';
import '../../domain/entities/crop_rect.dart';
import '../export/page_image_export.dart';
import 'ocr_client.dart';

/// 줄이기 거리 — 아이솔레이트로 넘긴다.
///
/// 그림 줄이기는 순수 CPU 다. 메인에서 돌리면 진행률조차 갱신되지 않아
/// 멈춘 것처럼 보인다 (CLAUDE.md §5)
class ShrinkJob {
  const ShrinkJob(this.jpeg, this.width);

  final Uint8List jpeg;
  final int width;
}

/// `compute()` 에 넘기려면 최상위 함수여야 한다
Uint8List shrinkJpeg(ShrinkJob job) {
  final decoded = img.decodeJpg(job.jpeg);
  if (decoded == null || decoded.width <= job.width) return job.jpeg;
  final small = img.copyResize(
    decoded,
    width: job.width,
    interpolation: img.Interpolation.average,
  );
  return img.encodeJpg(small, quality: 90);
}

/// 한 쪽을 마칠 때마다 알린다
class OcrProgress {
  const OcrProgress({required this.done, required this.total, this.text});

  final int done;
  final int total;

  /// 방금 읽은 글자 (미리보기용)
  final String? text;
}

/// 스캔본을 글자로 바꾸는 일을 이끈다.
///
/// **한 쪽 끝날 때마다 DB 에 적는다.** 두 시간짜리 일이라 중간에 죽는 것이
/// 정상이고, 다시 열면 남은 쪽부터 이어 돈다 (CLAUDE.md §2 규칙 7).
class OcrController {
  const OcrController(this._db);

  final AppDatabase _db;

  /// 아직 글자가 없는 쪽 번호들. 여기가 곧 "남은 일"이다
  Future<List<int>> pendingPages(int bookId, int pageCount) async {
    final rows = await (_db.select(_db.pageTexts)..where((t) => t.bookId.equals(bookId))).get();
    final have = rows.map((r) => r.pageNo).toSet();
    return [for (var p = 1; p <= pageCount; p++) if (!have.contains(p)) p];
  }

  Future<OcrJob?> jobOf(int bookId) =>
      (_db.select(_db.ocrJobs)..where((t) => t.bookId.equals(bookId))).getSingleOrNull();

  /// 책 한 권을 글자로 바꾼다.
  ///
  /// [split] 이면 한 장에 두 쪽이 들어 있는 스캔본이다 — 반쪽씩 따로 보내고
  /// 결과를 이어 붙인다. 펼침을 통째로 보내면 모델이 몇 자 내놓고 멈춘다
  /// (docs/engine-verification.md 의 함정).
  Stream<OcrProgress> run({
    required int bookId,
    required PdfDocument doc,
    required OcrClient client,
    required CropRect Function(int pageNumber) cropFor,
    required bool split,
    required ExportCancelToken cancel,
  }) async* {
    final total = doc.pages.length;
    final pending = await pendingPages(bookId, total);

    await _mark(bookId, done: total - pending.length, total: total, status: 'running', client: client);
    yield OcrProgress(done: total - pending.length, total: total);

    var done = total - pending.length;
    for (final pageNo in pending) {
      if (cancel.isCancelled) {
        await _mark(bookId, done: done, total: total, status: 'paused', client: client);
        return;
      }
      try {
        final page = doc.pages[pageNo - 1];
        final parts = <String>[];
        for (final half in split ? const [0, 1] : const [null]) {
          if (cancel.isCancelled) break;
          final jpeg = await PageImageExport.renderPageJpeg(
            page,
            dpi: PageImageExport.defaultDpi,
            crop: cropFor(pageNo),
            half: half,
          );
          final small = await compute(shrinkJpeg, ShrinkJob(jpeg, OcrClient.sendWidth));
          parts.add(await client.readImage(small));
        }
        // 반쪽 둘은 이어지는 글이다. 한글은 줄 끝에서 공백 없이 붙는 편이
        // 자연스럽지만, 쪽이 바뀌는 자리는 문단 경계로 보는 것이 안전하다
        final text = parts.where((t) => t.isNotEmpty).join('\n\n');
        if (text.isNotEmpty) await _savePage(bookId, pageNo, text);
        done++;
        await _mark(bookId, done: done, total: total, status: 'running', client: client);
        yield OcrProgress(done: done, total: total, text: text);
      } on Object catch (e) {
        // 한 쪽이 실패해도 멈추지 않는다. 이미 끝낸 쪽은 그대로 두고,
        // 남은 쪽은 다음에 다시 돌리면 된다
        await _mark(
          bookId,
          done: done,
          total: total,
          status: 'failed',
          client: client,
          error: '$pageNo쪽: $e',
        );
        rethrow;
      }
    }

    await _mark(bookId, done: done, total: total, status: 'done', client: client);
    // 이제 글자가 생겼다. 검색이 되도록 표시한다
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId)))
        .write(const BooksCompanion(hasTextLayer: Value(true), isIndexed: Value(true)));
  }

  /// 읽은 글자를 색인까지 되게 넣는다.
  ///
  /// 글자 레이어에서 뽑을 때와 **똑같은 변환**을 거쳐야 한다. 한쪽만 다르면
  /// 검색이 그냥 안 된다 (CLAUDE.md §6-6)
  Future<void> _savePage(int bookId, int pageNo, String raw) async {
    final norm = Korean.normalize(raw);
    await _db.into(_db.pageTexts).insert(
          PageTextsCompanion.insert(
            bookId: bookId,
            pageNo: pageNo,
            raw: raw,
            norm: norm,
            nospace: Korean.stripSpaces(norm),
            bigram: Korean.bigrams(norm),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _mark(
    int bookId, {
    required int done,
    required int total,
    required String status,
    required OcrClient client,
    String? error,
  }) async {
    await _db.into(_db.ocrJobs).insertOnConflictUpdate(
          OcrJobsCompanion.insert(
            bookId: Value(bookId),
            done: Value(done),
            total: Value(total),
            status: Value(status),
            lastError: Value(error),
            endpoint: Value(client.endpoint),
            model: Value(client.model),
            updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
  }
}

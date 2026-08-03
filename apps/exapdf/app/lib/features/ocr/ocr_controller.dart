import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../core/korean.dart';
import '../../data/db/database.dart';
import '../../domain/entities/crop_rect.dart';
import '../export/page_image_export.dart';
import 'ocr_client.dart';
import 'ocr_server.dart';

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
    List<int>? only,
  }) async* {
    final total = doc.pages.length;
    // [only] 를 주면 그 쪽만. 두 시간짜리 일을 걸기 전에 한 쪽으로 시험해
    // 보게 하려는 것이다 — 서버·모델·판형이 맞는지 30초면 안다
    final pending = only ?? await pendingPages(bookId, total);

    // 한 쪽만 돌릴 때는 진행률도 그 한 쪽 기준이어야 한다
    final scope = only != null ? only.length : total;
    var done = only != null ? 0 : total - pending.length;

    await _mark(bookId, done: done, total: scope, status: 'running', client: client);
    yield OcrProgress(done: done, total: scope);
    for (final pageNo in pending) {
      if (cancel.isCancelled) {
        await _mark(bookId, done: done, total: scope, status: 'paused', client: client);
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
        await _mark(bookId, done: done, total: scope, status: 'running', client: client);
        yield OcrProgress(done: done, total: scope, text: text);
      } on Object catch (e) {
        // 한 쪽이 실패해도 멈추지 않는다. 이미 끝낸 쪽은 그대로 두고,
        // 남은 쪽은 다음에 다시 돌리면 된다
        await _mark(
          bookId,
          done: done,
          total: scope,
          status: 'failed',
          client: client,
          error: '$pageNo쪽: $e',
        );
        rethrow;
      }
    }

    await _mark(bookId, done: done, total: scope, status: only != null ? 'paused' : 'done', client: client);
    // 이제 글자가 생겼다. 검색이 되도록 표시한다.
    // 한 쪽만 돌렸어도 그 쪽은 찾을 수 있어야 하므로 똑같이 표시한다
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId)))
        .write(const BooksCompanion(hasTextLayer: Value(true), isIndexed: Value(true)));
  }

  /// 읽은 글자를 색인까지 되게 넣는다.
  ///
  /// 글자 레이어에서 뽑을 때와 **똑같은 변환**을 거쳐야 한다. 한쪽만 다르면
  /// 검색이 그냥 안 된다 (CLAUDE.md §6-6)
  Future<void> _savePage(int bookId, int pageNo, String raw, {String? boxes}) async {
    final norm = Korean.normalize(raw);
    await _db.into(_db.pageTexts).insert(
          PageTextsCompanion.insert(
            bookId: bookId,
            pageNo: pageNo,
            raw: raw,
            norm: norm,
            nospace: Korean.stripSpaces(norm),
            bigram: Korean.bigrams(norm),
            boxes: Value(boxes),
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

  // ── 서버에 맡기기 ──────────────────────────────────────

  /// 서버가 대신 돌린다.
  ///
  /// 앱이 직접 돌리면 **앱을 켜 둔 채로 두 시간**이 필요하다 — 홈으로 나가거나
  /// 화면이 꺼지면 안드로이드가 앱을 재워 멈춘다. 서버에 맡기면 올려 두고
  /// 나가면 되고, 다시 들어왔을 때 남은 결과만 받아 오면 된다.
  Stream<OcrProgress> runOnServer({
    required int bookId,
    required Uint8List bytes,
    required String filename,
    required OcrServerClient server,
    required bool split,
    required ExportCancelToken cancel,
  }) async* {
    // 이미 맡겨 둔 일감이 있으면 그것에 다시 붙는다.
    // 없으면 올린다 — 서버가 같은 파일을 알아보고 새로 만들지 않는다
    var uuid = (await jobOf(bookId))?.remoteUuid;
    ServerJob job;
    if (uuid == null) {
      job = await server.createJob(bytes: bytes, filename: filename, split: split);
      uuid = job.uuid;
      await _markRemote(bookId, uuid, job);
      yield OcrProgress(done: 0, total: job.pageCount);
    } else {
      job = await server.job(uuid);
    }

    // 이미 받아 둔 쪽 다음부터 달라고 한다. 전체를 매번 받으면 낭비다
    var since = await _highestSavedPage(bookId);

    while (!cancel.isCancelled) {
      final (pages, latest) = await server.pages(uuid, since: since);
      for (final p in pages) {
        if (p.text.isNotEmpty) await _savePage(bookId, p.pageNo, p.text, boxes: p.boxes);
        if (p.pageNo > since) since = p.pageNo;
      }
      job = latest;
      await _markRemote(bookId, uuid, job);
      yield OcrProgress(done: job.donePages, total: job.pageCount);

      if (job.isFinished) break;
      // 5초마다 묻는다. 쪽 하나가 30초 안팎이라 더 자주 물어도 얻을 것이 없다
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    if (cancel.isCancelled) {
      await server.cancel(uuid);
      return;
    }
    if (job.isFailed) throw OcrServerException(job.lastError);

    await (_db.update(_db.books)..where((t) => t.id.equals(bookId)))
        .write(const BooksCompanion(hasTextLayer: Value(true), isIndexed: Value(true)));
  }

  /// 이미 받아 둔 마지막 쪽. 여기까지는 다시 받지 않는다
  Future<int> _highestSavedPage(int bookId) async {
    final rows = await (_db.select(_db.pageTexts)..where((t) => t.bookId.equals(bookId))).get();
    var max = 0;
    for (final r in rows) {
      if (r.pageNo > max) max = r.pageNo;
    }
    return max;
  }

  Future<void> _markRemote(int bookId, String uuid, ServerJob job) async {
    await _db.into(_db.ocrJobs).insertOnConflictUpdate(
          OcrJobsCompanion.insert(
            bookId: Value(bookId),
            done: Value(job.donePages),
            total: Value(job.pageCount),
            status: Value(job.status),
            lastError: Value(job.lastError.isEmpty ? null : job.lastError),
            remoteUuid: Value(uuid),
            updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
  }
}

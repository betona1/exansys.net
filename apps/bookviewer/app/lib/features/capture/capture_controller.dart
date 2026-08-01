import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import '../../data/db/database.dart';
import '../../domain/entities/book.dart';
import 'capture_service.dart';

/// 캡처가 진행 중인지. 오버레이가 새 드래그를 막는 데 쓴다
final captureBusyProvider = StateProvider<bool>((ref) => false);

final captureControllerProvider = Provider<CaptureController>(
  (ref) => CaptureController(ref),
);

/// 화면에서 고른 사각형을 문서 좌표로 옮기고, 잘라 저장하고, 출처를 DB 에 남긴다.
///
/// **캡처는 출처를 절대 잃지 않는다** (techspec §9). 이미지 파일만 남고 어느 책 몇 쪽인지
/// 모르게 되는 것이 사용자 최대 불만이므로, 이미지와 함께 앵커(책·쪽·좌표)를 저장한다.
class CaptureController {
  CaptureController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<Result<CaptureResult>> capture({
    required PdfDocument doc,
    required PdfViewerController controller,
    required RenderBox viewerBox,
    required Rect localRect,
    required Book book,
    bool includeSource = true,
  }) async {
    final busy = _ref.read(captureBusyProvider.notifier);
    busy.state = true;
    try {
      // 화면 좌표 → 문서 좌표
      final topLeft = controller.globalToDocument(viewerBox.localToGlobal(localRect.topLeft));
      final bottomRight = controller.globalToDocument(viewerBox.localToGlobal(localRect.bottomRight));
      if (topLeft == null || bottomRight == null) {
        return const Result.failed('화면 위치를 문서 좌표로 옮기지 못했습니다');
      }
      final docRect = Rect.fromPoints(topLeft, bottomRight);

      // 걸친 쪽 가운데 가장 많이 겹치는 쪽 하나를 고른다.
      // 두 쪽에 걸친 캡처는 아직 범위 밖이다
      final layouts = controller.layout.pageLayouts;
      var bestIndex = -1;
      var bestArea = 0.0;
      for (var i = 0; i < layouts.length; i++) {
        final inter = layouts[i].intersect(docRect);
        final area = (inter.width <= 0 || inter.height <= 0) ? 0.0 : inter.width * inter.height;
        if (area > bestArea) {
          bestArea = area;
          bestIndex = i;
        }
      }
      if (bestIndex < 0) return const Result.failed('쪽 바깥은 잘라 낼 수 없습니다');

      final pageRect = layouts[bestIndex];
      final page = doc.pages[bestIndex];
      final local = docRect.intersect(pageRect).shift(-pageRect.topLeft);

      final result = await CaptureService.capture(
        page: page,
        rect: local,
        bookTitle: book.title,
        sourceLabel: includeSource ? '${book.title} · ${page.pageNumber}쪽' : null,
      );

      await _saveSource(book: book, page: page.pageNumber, rect: local, result: result);
      return Result.ok(result);
    } on CaptureTooSmall {
      return const Result.failed('영역이 너무 작습니다. 조금 더 크게 드래그해 주세요');
    } on Object catch (e) {
      return Result.failed('캡처하지 못했습니다 — $e');
    } finally {
      busy.state = false;
    }
  }

  /// 앵커 + 캡처 기록. 이미지에서 원문 위치로 돌아갈 수 있게 하는 연결이다
  Future<void> _saveSource({
    required Book book,
    required int page,
    required Rect rect,
    required CaptureResult result,
  }) async {
    final db = _ref.read(databaseProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    final anchorId = await db.into(db.anchors).insert(
          AnchorsCompanion.insert(
            uuid: _uuid.v4(),
            bookId: book.id,
            kind: const Value('area'),
            pageNo: page,
            rects: jsonEncode([
              [rect.left, rect.top, rect.right, rect.bottom],
            ]),
            // 파일이 바뀌었는지 판정할 기준. 지금은 등록 당시 값을 그대로 쓴다
            documentChecksum: '',
            createdAt: now,
          ),
        );
    await db.into(db.captures).insert(
          CapturesCompanion.insert(
            uuid: _uuid.v4(),
            bookId: book.id,
            anchorId: anchorId,
            imagePath: Value(result.file.path),
            dpi: Value(CaptureService.dpi),
            createdAt: now,
          ),
        );
  }
}

/// 저장 완료 알림. 공유 버튼으로 갤러리·메신저로 내보낸다
SnackBar captureSavedSnackBar(CaptureResult result, Book book) {
  return SnackBar(
    duration: const Duration(seconds: 6),
    content: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(result.file, width: 40, height: 40, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('${result.pageNumber}쪽을 잘라 저장했습니다')),
      ],
    ),
    action: SnackBarAction(
      label: '공유',
      onPressed: () => SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.file.path)],
          text: '${book.title} · ${result.pageNumber}쪽',
        ),
      ),
    ),
  );
}

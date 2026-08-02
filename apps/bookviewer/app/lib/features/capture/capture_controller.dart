import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
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

  /// 쪽 좌표로 이미 옮겨진 사각형을 잘라 낸다.
  ///
  /// 화면 좌표 → 쪽 좌표 변환은 그리는 쪽(`SliceMapper`)이 안다.
  /// 여기서는 자르고 저장하고 출처를 남기는 일만 한다.
  Future<Result<CaptureResult>> captureRect({
    required PdfPage page,
    required Rect rect,
    required Book book,
    bool includeSource = true,
  }) async {
    final busy = _ref.read(captureBusyProvider.notifier);
    busy.state = true;
    try {
      final result = await CaptureService.capture(
        page: page,
        rect: rect,
        bookTitle: book.title,
        sourceLabel: includeSource ? '${book.title} · ${page.pageNumber}쪽' : null,
      );
      await _saveSource(book: book, page: page.pageNumber, rect: rect, result: result);
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
  );
}

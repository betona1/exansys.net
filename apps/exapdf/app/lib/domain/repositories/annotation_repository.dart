import 'dart:ui';

import '../entities/annotation.dart';

/// 하이라이트·북마크 저장소.
///
/// 원본 PDF 는 절대 건드리지 않는다. 전부 앱 DB 에 오버레이로 쌓는다 (ADR-0002).
/// 나중에 "주석 포함 PDF 내보내기"로 꺼낼 수 있으므로 락인이 아니다.
abstract interface class AnnotationRepository {
  /// 책 한 권의 하이라이트. 쪽 순서
  Stream<List<Highlight>> watchHighlights(int bookId);

  Future<List<Highlight>> highlightsOfPage(int bookId, int pageNo);

  /// [rect] 은 쪽 좌표(PDF 포인트)
  Future<Highlight> addHighlight({
    required int bookId,
    required int pageNo,
    required Rect rect,
    required int colorSlot,
    required String documentChecksum,
  });

  Future<void> updateHighlight(int id, {int? colorSlot, String? note});

  /// 소프트 삭제. 물리 삭제하면 동기화 시 다른 기기에서 되살아난다
  Future<void> deleteHighlight(int id);

  Stream<List<BookmarkEntry>> watchBookmarks(int bookId);

  /// 이미 있으면 지우고, 없으면 넣는다. 결과는 넣었으면 true
  Future<bool> toggleBookmark({required int bookId, required int pageNo});

  Future<bool> isBookmarked(int bookId, int pageNo);

  Future<void> deleteBookmark(int id);
}

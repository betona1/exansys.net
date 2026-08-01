import '../entities/search_hit.dart';

/// 색인 진행 상황 (techspec §12 — "78% 인덱싱 중 · 결과가 늘어날 수 있습니다")
class IndexProgress {
  const IndexProgress({required this.bookId, required this.done, required this.total});

  final int bookId;
  final int done;
  final int total;

  double get ratio => total == 0 ? 0 : done / total;
  bool get isFinished => total > 0 && done >= total;
}

abstract interface class SearchRepository {
  /// 책 한 권을 색인한다. 이미 되어 있으면 [force] 가 아닌 한 건너뛴다.
  ///
  /// 진행 상황을 흘려보내므로 화면이 진척을 보여줄 수 있다.
  Stream<IndexProgress> indexBook(int bookId, {bool force = false});

  /// 라이브러리 전체 검색. [bookId] 를 주면 그 책 안에서만 찾는다.
  Future<List<SearchHitGroup>> search(String query, {int? bookId, int limit = 200});

  /// 색인이 되어 있는 책 수 / 전체 책 수
  Future<(int indexed, int total)> indexedCount();

  /// 색인을 지운다 (설정 — 검색 인덱스 다시 만들기)
  Future<void> clearIndex({int? bookId});
}

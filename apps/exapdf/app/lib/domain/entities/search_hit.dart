/// 검색 결과 한 건.
class SearchHit {
  const SearchHit({
    required this.bookId,
    required this.bookTitle,
    required this.pageNo,
    required this.snippet,
    required this.score,
  });

  final int bookId;
  final String bookTitle;
  final int pageNo;

  /// 앞뒤 문맥이 붙은 한 줄. 찾은 낱말은 [highlightStart]/[highlightEnd] 로 감싼다
  final String snippet;

  /// bm25 점수. 작을수록 잘 맞는다 (SQLite 의 bm25 는 음수로 커진다)
  final double score;

  /// 스니펫 안에서 강조 구간을 나타내는 표식.
  /// FTS5 `snippet()` 에 넘기는 값과 같아야 한다.
  static const highlightStart = '';
  static const highlightEnd = '';
}

/// 책 하나에 묶인 결과 (techspec §12 — 책별로 접어서 보여준다)
class SearchHitGroup {
  const SearchHitGroup({required this.bookId, required this.bookTitle, required this.hits});

  final int bookId;
  final String bookTitle;
  final List<SearchHit> hits;
}

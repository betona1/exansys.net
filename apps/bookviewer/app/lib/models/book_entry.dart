import 'dart:convert';

/// 책장에 남는 한 권.
///
/// 원본 PDF 는 사용자가 고른 자리에 그대로 둔다. 여기에는 그 자리를 가리키는
/// 경로와 어디까지 읽었는지만 담는다 (CLAUDE.md 5절 — 원본을 옮기거나 복사하지 않는다).
class BookEntry {
  const BookEntry({
    required this.path,
    required this.title,
    this.lastPage = 1,
    this.pageCount = 0,
    required this.openedAt,
  });

  /// 원본 PDF 의 절대 경로
  final String path;

  /// 화면에 보일 이름 (기본은 파일 이름에서 확장자를 뗀 것)
  final String title;

  /// 마지막으로 보던 쪽 (1부터)
  final int lastPage;

  /// 전체 쪽 수. 아직 열어보지 않았으면 0
  final int pageCount;

  /// 마지막으로 연 시각 — 책장 정렬 기준
  final DateTime openedAt;

  /// 0.0 ~ 1.0. 쪽 수를 모르면 0
  double get progress => pageCount > 0 ? (lastPage / pageCount).clamp(0.0, 1.0) : 0.0;

  BookEntry copyWith({int? lastPage, int? pageCount, DateTime? openedAt, String? title}) => BookEntry(
    path: path,
    title: title ?? this.title,
    lastPage: lastPage ?? this.lastPage,
    pageCount: pageCount ?? this.pageCount,
    openedAt: openedAt ?? this.openedAt,
  );

  Map<String, dynamic> toJson() => {
    'path': path,
    'title': title,
    'lastPage': lastPage,
    'pageCount': pageCount,
    'openedAt': openedAt.millisecondsSinceEpoch,
  };

  static BookEntry fromJson(Map<String, dynamic> j) => BookEntry(
    path: j['path'] as String,
    title: j['title'] as String? ?? '',
    lastPage: (j['lastPage'] as num?)?.toInt() ?? 1,
    pageCount: (j['pageCount'] as num?)?.toInt() ?? 0,
    openedAt: DateTime.fromMillisecondsSinceEpoch((j['openedAt'] as num?)?.toInt() ?? 0),
  );

  static String encodeList(List<BookEntry> items) => jsonEncode(items.map((e) => e.toJson()).toList());

  static List<BookEntry> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException {
      // 저장된 내용이 깨졌다고 앱이 못 뜨면 안 된다. 책장을 비우고 계속 간다.
      return const [];
    }
  }
}

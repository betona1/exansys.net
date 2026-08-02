/// 서재에 놓인 책 한 권 — 화면이 쓰는 형태.
///
/// Drift 가 만든 행(row) 타입을 화면까지 끌고 가지 않는다. UI 는 DB 를 모른다 (CLAUDE.md §4).
class Book {
  const Book({
    required this.id,
    required this.uuid,
    required this.filePath,
    required this.title,
    required this.pageCount,
    required this.lastPage,
    required this.farthestPage,
    required this.addedAt,
    this.author,
    this.coverPath,
    this.lastReadAt,
    this.hasTextLayer = true,
    this.fileMissing = false,
  });

  final int id;
  final String uuid;
  final String filePath;
  final String title;
  final int pageCount;

  /// 마지막으로 보던 쪽 — 다시 열면 여기로 간다
  final int lastPage;

  /// 가장 멀리 읽은 쪽 — **진도율은 이 값 기준이다.**
  /// 검색·목차로 앞쪽에 갔다 왔다고 진도가 줄어들면 안 된다 (SPEC §2.1)
  final int farthestPage;

  final DateTime addedAt;
  final String? author;
  final String? coverPath;
  final DateTime? lastReadAt;

  /// false 면 스캔본 — 검색이 되지 않는다는 것을 사용자에게 알려야 한다
  final bool hasTextLayer;

  /// 원본 파일을 찾을 수 없다. 책장에서 지우지 않고 배지로 알린다 (techspec §13).
  /// 모바일 SAF·외장 저장소, 데스크톱 네트워크 드라이브에서 흔하다
  final bool fileMissing;

  /// 0.0 ~ 1.0. 쪽 수를 모르면 0
  double get progress => pageCount > 0 ? (farthestPage / pageCount).clamp(0.0, 1.0) : 0.0;

  /// 파일 이름 — 제목과 **함께** 보여준다. 하나만 보이는 것이 실사용 불만이다 (techspec §13)
  String get fileName => filePath.split(RegExp(r'[/\\]')).last;

  bool get isFinished => pageCount > 0 && farthestPage >= pageCount;
}

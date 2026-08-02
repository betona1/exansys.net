import 'dart:ui';

/// 하이라이트 한 개.
///
/// 글자 선택이 없으므로 **영역**으로 잡는다. 스캔본에는 글자 레이어가 없어
/// 텍스트 범위 하이라이트가 애초에 성립하지 않는다 (SPEC §2.4 의 텍스트
/// 하이라이트는 텍스트 PDF 에서 선택 기능이 생기면 그때 얹는다).
class Highlight {
  const Highlight({
    required this.id,
    required this.uuid,
    required this.pageNo,
    required this.rect,
    required this.colorSlot,
    this.note,
  });

  final int id;
  final String uuid;

  /// 1부터
  final int pageNo;

  /// 쪽 좌표(PDF 포인트) 안의 사각형
  final Rect rect;

  /// 1~5. **색상값이 아니라 슬롯을 저장한다** — 테마를 바꿔도 의미가 따라온다
  /// (BRAND.md §3.3)
  final int colorSlot;

  final String? note;

  Highlight copyWith({int? colorSlot, String? note}) => Highlight(
    id: id,
    uuid: uuid,
    pageNo: pageNo,
    rect: rect,
    colorSlot: colorSlot ?? this.colorSlot,
    note: note ?? this.note,
  );
}

/// 북마크 — 쪽 하나를 표시해 둔 것
class BookmarkEntry {
  const BookmarkEntry({
    required this.id,
    required this.uuid,
    required this.pageNo,
    this.label,
  });

  final int id;
  final String uuid;
  final int pageNo;
  final String? label;
}

import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 읽기 화면 상단 바 (techspec §4 compact).
///
/// 뒤로 · 문서명 · 찾기 · 캡처. 검색을 열면 그 아래에 검색 패널이 붙는다.
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.searchOpen,
    required this.canSearch,
    required this.searchDisabledReason,
    required this.canCapture,
    required this.onBack,
    required this.onToggleSearch,
    required this.onCapture,
    required this.splitOn,
    required this.onToggleSplit,
    required this.zoomLocked,
    required this.onToggleZoomLock,
    required this.highlighting,
    required this.onToggleHighlight,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onOpenMarks,
    required this.viewChanged,
    required this.onOpenViewSheet,
    this.searchSheet,
  });

  final String title;
  final bool searchOpen;

  /// 문서가 열리기 전에는 검색기가 없다
  final bool canSearch;

  /// 검색이 막힌 이유. 스캔본이면 "글자를 찾을 수 없습니다".
  /// **버튼을 숨기지 않고 이유를 보여 준다** — 사라지면 기능이 없다고 오해한다 (techspec §6.5)
  final String? searchDisabledReason;
  final bool canCapture;

  final VoidCallback onBack;
  final VoidCallback onToggleSearch;
  final VoidCallback onCapture;




  /// 좌우 나눠 보기가 켜져 있는가.
  /// 시트에 묻어 두면 껐다 켜기가 번거로워 도구막대에 둔다
  final bool splitOn;
  final VoidCallback onToggleSplit;

  /// 배율·좌우 위치를 잠갔는가
  final bool zoomLocked;
  final VoidCallback onToggleZoomLock;

  /// 하이라이트 모드가 켜져 있는가
  final bool highlighting;
  final VoidCallback onToggleHighlight;

  /// 지금 쪽이 북마크되어 있는가
  final bool bookmarked;
  final VoidCallback onToggleBookmark;

  /// 하이라이트·북마크 모아 보기
  final VoidCallback onOpenMarks;

  /// 보기 설정 가운데 하나라도 켜져 있는가 (분할·크롭·다크)
  final bool viewChanged;

  /// null 이면 아직 문서가 준비되지 않은 것
  final VoidCallback? onOpenViewSheet;

  final Widget? searchSheet;

  /// 좁은 화면에서는 아이콘을 줄여 다 들어가게 한다.
  /// 폰 세로에서 아이콘 여섯 개가 기본 크기로 늘어서면 제목이 밀려 사라진다
  static double iconSizeFor(double width) => width < 400 ? 20 : (width < 600 ? 22 : 24);

  /// 아이콘 하나가 실제로 먹는 폭. 뒤로 버튼과 제목 자리도 빼야 한다
  static const _slot = 42.0;
  static const _titleRoom = 120.0;

  /// 한 줄에 다 들어가는가.
  ///
  /// 안 들어가면 조용히 잘려 나가 **아이콘이 아예 없는 것처럼 보인다.**
  /// 그럴 바에는 두 줄로 나눠 전부 보이게 하는 편이 낫다
  static bool fitsOneRow(double width, int iconCount) =>
      width >= _slot * (iconCount + 1) + _titleRoom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final iconSize = iconSizeFor(width);
    final density = width < 600 ? VisualDensity.compact : VisualDensity.standard;

    // 아이콘을 목록으로 만든다. 한 줄에 다 못 들어가면 두 줄로 나눈다 —
    // 예전에는 넘치는 만큼 조용히 잘려서 **아이콘이 없는 것처럼 보였다.**
    final icons = <Widget>[
      IconButton(
        onPressed: canSearch ? onToggleSearch : null,
        icon: Icon(searchOpen ? Icons.search_off : Icons.search),
        tooltip: searchDisabledReason ?? '이 책에서 찾기',
        iconSize: iconSize,
        visualDensity: density,
      ),
      IconButton(
        onPressed: onToggleSplit,
        icon: const Icon(Icons.vertical_split),
        tooltip: splitOn ? '한 장씩 보기' : '좌우 나눠 보기',
        color: splitOn ? AppTokens.amber : null,
        iconSize: iconSize,
        visualDensity: density,
      ),
      IconButton(
        onPressed: onToggleZoomLock,
        icon: Icon(zoomLocked ? Icons.lock : Icons.lock_open),
        tooltip: zoomLocked ? '좌우 고정 풀기' : '좌우·크기 고정',
        color: zoomLocked ? AppTokens.amber : null,
        iconSize: iconSize,
        visualDensity: density,
      ),
      IconButton(
        onPressed: onToggleHighlight,
        icon: const Icon(Icons.brush),
        tooltip: highlighting ? '형광펜 끄기' : '형광펜',
        color: highlighting ? AppTokens.amber : null,
        iconSize: iconSize,
        visualDensity: density,
      ),
      IconButton(
        onPressed: onToggleBookmark,
        icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
        tooltip: bookmarked ? '북마크 빼기' : '이 쪽 북마크',
        color: bookmarked ? AppTokens.amber : null,
        iconSize: iconSize,
        visualDensity: density,
      ),
      IconButton(
        onPressed: onOpenMarks,
        icon: const Icon(Icons.list),
        tooltip: '하이라이트·북마크 목록',
        iconSize: iconSize,
        visualDensity: density,
      ),
      // 보기 관련은 시트 하나로 모은다.
      // 도구막대에 토글이 여섯 개 늘어서면 무엇이 무엇인지 알 수 없다
      IconButton(
        onPressed: onOpenViewSheet,
        icon: const Icon(Icons.tune),
        tooltip: '보기 — 맞춤 · 여백 · 테마',
        iconSize: iconSize,
        visualDensity: density,
        color: viewChanged ? AppTokens.amber : null,
      ),
      IconButton(
        onPressed: canCapture ? onCapture : null,
        icon: const Icon(Icons.crop_free),
        tooltip: '영역 캡처',
        iconSize: iconSize,
        visualDensity: density,
      ),
    ];

    final oneRow = fitsOneRow(width, icons.length);

    final back = IconButton(
      onPressed: onBack,
      icon: const Icon(Icons.chevron_left),
      tooltip: '서재로',
      iconSize: iconSize,
      visualDensity: density,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  back,
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // 한 줄에 들어가면 제목 옆에 그대로 붙인다
                  if (oneRow) ...[...icons, const SizedBox(width: AppTokens.space1)],
                ],
              ),
              // 좁으면 아랫줄에 고르게 펼친다. 잘려 보이는 것보다 낫다
              if (!oneRow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: icons,
                ),
              ?searchSheet,
            ],
          ),
        ),
      ),
    );
  }
}

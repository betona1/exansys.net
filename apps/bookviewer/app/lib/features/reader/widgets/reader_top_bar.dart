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

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '서재로',
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: canSearch ? onToggleSearch : null,
                    icon: Icon(searchOpen ? Icons.search_off : Icons.search),
                    tooltip: searchDisabledReason ?? '이 책에서 찾기',
                  ),
                  IconButton(
                    onPressed: onToggleZoomLock,
                    icon: Icon(zoomLocked ? Icons.lock : Icons.lock_open),
                    tooltip: zoomLocked ? '좌우 고정 풀기' : '좌우·크기 고정',
                    color: zoomLocked ? AppTokens.amber : null,
                  ),
                  IconButton(
                    onPressed: onToggleHighlight,
                    icon: const Icon(Icons.brush),
                    tooltip: highlighting ? '형광펜 끄기' : '형광펜',
                    color: highlighting ? AppTokens.amber : null,
                  ),
                  IconButton(
                    onPressed: onToggleBookmark,
                    icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
                    tooltip: bookmarked ? '북마크 빼기' : '이 쪽 북마크',
                    color: bookmarked ? AppTokens.amber : null,
                  ),
                  IconButton(
                    onPressed: onOpenMarks,
                    icon: const Icon(Icons.list),
                    tooltip: '하이라이트·북마크 목록',
                  ),
                  // 보기 관련은 시트 하나로 모은다.
                  // 도구막대에 토글이 여섯 개 늘어서면 무엇이 무엇인지 알 수 없다
                  IconButton(
                    onPressed: onOpenViewSheet,
                    icon: const Icon(Icons.tune),
                    tooltip: '보기 — 나눠 보기 · 여백 · 테마',
                    color: viewChanged ? AppTokens.amber : null,
                  ),
                  IconButton(
                    onPressed: canCapture ? onCapture : null,
                    icon: const Icon(Icons.crop_free),
                    tooltip: '영역 캡처',
                  ),
                  const SizedBox(width: AppTokens.space1),
                ],
              ),
              ?searchSheet,
            ],
          ),
        ),
      ),
    );
  }
}

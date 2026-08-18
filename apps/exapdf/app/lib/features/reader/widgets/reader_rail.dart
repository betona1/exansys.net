import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 세로 조작 레일 — 가로 화면과 큰 화면에서 위아래 바를 대신한다.
///
/// 가로로 들면 세로가 귀하다. 위아래에 바를 두면 책이 그만큼 납작해진다.
/// 가로는 반대로 좌우가 남으므로 조작을 옆으로 옮긴다.
class ReaderRail extends StatelessWidget {
  const ReaderRail({
    super.key,
    required this.page,
    required this.pageCount,
    required this.sideLabel,
    required this.canSearch,
    required this.searchDisabledReason,
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
    required this.onBack,
    required this.onSearch,
    required this.onViewSheet,
    required this.onCapture,
    required this.showOcr,
    required this.onOcr,
    required this.onPrev,
    required this.onNext,
    required this.canPrev,
    required this.canNext,
    this.onClose,
  });

  final int page;
  final int pageCount;
  final String? sideLabel;

  final bool canSearch;
  final String? searchDisabledReason;



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

  final bool viewChanged;

  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onViewSheet;
  final VoidCallback onCapture;

  /// 스캔본일 때만 보인다
  final bool showOcr;
  final VoidCallback onOcr;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canPrev;
  final bool canNext;

  /// 서랍으로 열렸을 때 닫기 버튼. 상주 레일이면 null
  final VoidCallback? onClose;

  static const width = 72.0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.surface,
      child: SizedBox(
        width: width,
        child: SafeArea(
          child: Column(
            children: [
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left),
                tooltip: '서재로',
              ),
              const Divider(indent: 16, endIndent: 16),
              // **가로모드 폰에서는 세로가 짧아 아이콘이 잘려 나간다.**
              // 화면 높이가 400dp 남짓인데 단추가 열 개 넘게 쌓이기 때문이다.
              // 가운데 구역만 스크롤되게 하고, 쪽 이동은 아래에 붙박아 둔다
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    IconButton(
                      onPressed: canSearch ? onSearch : null,
                      icon: const Icon(Icons.search),
                      tooltip: searchDisabledReason ?? '이 책에서 찾기',
                    ),
                    IconButton(
                      onPressed: onViewSheet,
                      icon: const Icon(Icons.tune),
                      tooltip: '보기 — 맞춤 · 나눠 보기 · 여백 · 테마',
                      color: viewChanged ? AppTokens.vaveBlue : null,
                    ),
                    IconButton(
                      onPressed: onCapture,
                      icon: const Icon(Icons.crop_free),
                      tooltip: '영역 캡처',
                    ),
                    // 스캔본에서만. 돋보기 뒤에 숨겨 두었더니 아무도 못 찾았다
                    if (showOcr)
                      IconButton(
                        onPressed: onOcr,
                        icon: const Icon(Icons.text_fields),
                        tooltip: '글자로 바꾸기 (OCR)',
                        color: AppTokens.vaveBlue,
                      ),
                    IconButton(
                      onPressed: onToggleSplit,
                      icon: const Icon(Icons.vertical_split),
                      tooltip: splitOn ? '한 장씩 보기' : '좌우 나눠 보기',
                      color: splitOn ? AppTokens.vaveBlue : null,
                    ),
                    IconButton(
                      onPressed: onToggleZoomLock,
                      icon: Icon(zoomLocked ? Icons.lock : Icons.lock_open),
                      tooltip: zoomLocked ? '좌우 고정 풀기' : '좌우·크기 고정',
                      color: zoomLocked ? AppTokens.vaveBlue : null,
                    ),
                    IconButton(
                      onPressed: onToggleHighlight,
                      icon: const Icon(Icons.brush),
                      tooltip: highlighting ? '형광펜 끄기' : '형광펜',
                      color: highlighting ? AppTokens.vaveBlue : null,
                    ),
                    IconButton(
                      onPressed: onToggleBookmark,
                      icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
                      tooltip: bookmarked ? '북마크 빼기' : '이 쪽 북마크',
                      color: bookmarked ? AppTokens.vaveBlue : null,
                    ),
                    IconButton(
                      onPressed: onOpenMarks,
                      icon: const Icon(Icons.list),
                      tooltip: '하이라이트·북마크 목록',
                    ),

                    ],
                  ),
                ),
              ),

              // 쪽 번호와 앞뒤 이동. 세로로 쌓아 폭을 아낀다
              IconButton(
                onPressed: canPrev ? onPrev : null,
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: '이전 쪽',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
                child: Column(
                  children: [
                    Text('$page', style: t.textTheme.titleMedium),
                    Text(
                      pageCount > 0 ? '/ $pageCount' : '',
                      style: t.textTheme.labelSmall,
                    ),
                    if (sideLabel != null)
                      Text(sideLabel!, style: t.textTheme.labelSmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: canNext ? onNext : null,
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: '다음 쪽',
              ),
              const SizedBox(height: AppTokens.space2),
            ],
          ),
        ),
      ),
    );
  }
}

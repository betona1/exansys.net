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
              IconButton(
                onPressed: canSearch ? onSearch : null,
                icon: const Icon(Icons.search),
                tooltip: searchDisabledReason ?? '이 책에서 찾기',
              ),
              IconButton(
                onPressed: onViewSheet,
                icon: const Icon(Icons.tune),
                tooltip: '보기 — 맞춤 · 나눠 보기 · 여백 · 테마',
                color: viewChanged ? AppTokens.amber : null,
              ),
              IconButton(
                onPressed: onCapture,
                icon: const Icon(Icons.crop_free),
                tooltip: '영역 캡처',
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

              const Spacer(),

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

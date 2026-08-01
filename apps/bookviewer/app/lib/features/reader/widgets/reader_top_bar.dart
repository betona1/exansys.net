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
    required this.cropOn,
    required this.onCrop,
    required this.themeOn,
    required this.onTheme,
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

  /// 좌우 나눠 보기가 켜져 있는가
  final bool splitOn;

  /// null 이면 아직 문서가 준비되지 않은 것
  final VoidCallback? onToggleSplit;

  /// 여백 크롭이 켜져 있는가
  final bool cropOn;
  final VoidCallback? onCrop;

  /// 다크 리딩이 켜져 있는가
  final bool themeOn;
  final VoidCallback? onTheme;

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
                    onPressed: onToggleSplit,
                    icon: Icon(splitOn ? Icons.menu_book : Icons.vertical_split),
                    tooltip: splitOn ? '한 장씩 보기' : '좌우 나눠 보기',
                    color: splitOn ? AppTokens.amber : null,
                  ),
                  IconButton(
                    onPressed: onTheme,
                    icon: const Icon(Icons.contrast),
                    tooltip: '테마 · 밝기',
                    color: themeOn ? AppTokens.amber : null,
                  ),
                  IconButton(
                    onPressed: onCrop,
                    icon: const Icon(Icons.crop),
                    tooltip: '여백 잘라내기',
                    color: cropOn ? AppTokens.amber : null,
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

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

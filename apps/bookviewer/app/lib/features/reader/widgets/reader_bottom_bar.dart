import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 읽기 화면 하단 바 — 쪽 번호 + 슬라이더 (techspec §6.1 `sld.page`).
///
/// 긴 책에서 길을 잃지 않도록 슬라이더 드래그 중 쪽 번호를 라벨로 띄운다.
/// (썸네일 미리보기는 M2 에서 얹는다)
class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    required this.onPageSettled,
  });

  final int page;
  final int pageCount;

  /// 드래그 중 — 표시만 바꾼다
  final ValueChanged<int> onPageChanged;

  /// 손을 뗐을 때 — 실제로 이동한다
  final ValueChanged<int> onPageSettled;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
            child: Row(
              children: [
                Text(
                  pageCount > 0 ? '$page / $pageCount' : '$page',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: pageCount > 1
                      ? Slider(
                          value: page.toDouble().clamp(1, pageCount.toDouble()),
                          min: 1,
                          max: pageCount.toDouble(),
                          divisions: pageCount - 1,
                          label: '$page쪽',
                          onChanged: (v) => onPageChanged(v.round()),
                          onChangeEnd: (v) => onPageSettled(v.round()),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

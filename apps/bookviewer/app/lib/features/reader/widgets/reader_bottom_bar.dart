import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 읽기 화면 하단 바 — 이전/다음 · 쪽 번호 · 슬라이더 (techspec §6.1).
///
///     ◀ ────●────── 128/540 ▶
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
    required this.onPrev,
    required this.onNext,
    this.sideLabel,
    this.canPrev = true,
    this.canNext = true,
  });

  final int page;
  final int pageCount;

  /// 드래그 중 — 표시만 바꾼다
  final ValueChanged<int> onPageChanged;

  /// 손을 뗐을 때 — 실제로 이동한다
  final ValueChanged<int> onPageSettled;

  /// 한 쪽(분할 모드면 반쪽) 뒤로 / 앞으로
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// 끝에서는 비활성 (techspec §6.1)
  final bool canPrev;
  final bool canNext;

  /// 좌우 나눠 보기일 때 '좌'/'우'. 아니면 null
  final String? sideLabel;

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
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
            child: Row(
              children: [
                IconButton(
                  onPressed: canPrev ? onPrev : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '이전 쪽',
                ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.space1),
                  child: Text(
                    [
                      pageCount > 0 ? '$page / $pageCount' : '$page',
                      if (sideLabel != null) '($sideLabel)',
                    ].join(' '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  onPressed: canNext ? onNext : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 쪽',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

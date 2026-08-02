import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 하이라이트 모드일 때 뜨는 색 고르기 막대 (techspec §6.4 · BRAND.md §3.3).
///
/// **색만으로 의미를 전달하지 않는다** — 슬롯마다 라벨을 함께 보여 준다
/// (techspec §19 접근성).
class HighlightBar extends StatelessWidget {
  const HighlightBar({
    super.key,
    required this.colorSlot,
    required this.onPick,
    required this.onDone,
  });

  final int colorSlot;
  final ValueChanged<int> onPick;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: t.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3,
              vertical: AppTokens.space2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('칠할 곳을 드래그하세요', style: t.textTheme.bodySmall),
                const SizedBox(height: AppTokens.space2),
                Row(
                  children: [
                    for (var slot = 1; slot <= AppTokens.highlights.length; slot++)
                      Expanded(
                        child: _Swatch(
                          slot: slot,
                          selected: slot == colorSlot,
                          onTap: () => onPick(slot),
                        ),
                      ),
                    const SizedBox(width: AppTokens.space2),
                    FilledButton(onPressed: onDone, child: const Text('마침')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.slot, required this.selected, required this.onTap});

  final int slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTokens.highlights[slot - 1];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
        child: Column(
          children: [
            Container(
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTokens.radiusButton * 0.6),
                border: selected
                    ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                    : null,
              ),
              // 색만으로 고른 것을 알리지 않는다
              child: selected ? const Icon(Icons.check, size: 16, color: Colors.black87) : null,
            ),
            const SizedBox(height: 2),
            Text(
              AppTokens.highlightLabels[slot - 1],
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

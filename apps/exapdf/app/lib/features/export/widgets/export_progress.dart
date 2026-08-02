import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 오래 걸리는 내보내기의 진행 상태 (techspec §17).
///
/// 숫자 없이 가림막만 띄우면 멈춘 것처럼 보인다.
/// **취소를 반드시 둔다** — 장시간 작업을 멈출 수 없게 만들지 않는다 (CLAUDE.md §18).
class ExportProgressOverlay extends StatelessWidget {
  const ExportProgressOverlay({
    super.key,
    required this.done,
    required this.total,
    required this.onCancel,
    this.label = '쪽 이미지를 만드는 중',
  });

  final int done;
  final int total;
  final VoidCallback onCancel;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xE60D1117),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: t.textTheme.titleMedium),
                  const SizedBox(height: AppTokens.space4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: ratio, minHeight: 6),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    '$done / $total 쪽 · ${(ratio * 100).round()}%',
                    style: t.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTokens.space5),
                  OutlinedButton(onPressed: onCancel, child: const Text('취소')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

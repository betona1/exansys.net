import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 글자로 바꾸는 동안 아래에 붙는 얇은 띠.
///
/// 내보내기처럼 화면을 덮지 않는다 — **두 시간짜리 일이라 덮으면 책을 못 읽는다.**
/// 진행률과 멈춤만 보여 주고 나머지 화면은 그대로 쓰게 둔다.
class OcrProgressBar extends StatelessWidget {
  const OcrProgressBar({
    super.key,
    required this.done,
    required this.total,
    required this.onStop,
  });

  final int done;
  final int total;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: t.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: ratio, minHeight: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space3,
                  AppTokens.space2,
                  AppTokens.space2,
                  AppTokens.space2,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.text_fields, size: 18),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text(
                        '글자로 바꾸는 중 · $done / $total쪽',
                        style: t.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(onPressed: onStop, child: const Text('멈춤')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

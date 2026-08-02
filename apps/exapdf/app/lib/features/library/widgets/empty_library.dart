import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 서재가 비었을 때 (techspec §16 · BRAND.md §6.3).
///
/// 마스코트는 앱 아이콘과 같은 그림을 쓴다 — 처음 여는 화면에서 아이콘과 이어져 보이게 (BRAND.md §2.5).
class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key, required this.onPick});

  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 배경이 앱 배경과 같은 딥네이비라 그냥 두면 보이지 않는다.
            // 테두리로 경계를 준다
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.borderDark),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/icon/icon.png', width: 104, height: 104),
            ),
            const SizedBox(height: AppTokens.space5),
            Text('아직 책이 없습니다', style: t.textTheme.titleLarge),
            const SizedBox(height: AppTokens.space2),
            Text(
              'PDF 를 가져오면 책처럼 넘겨 읽고, 문장을 찾고,\n중요한 부분은 복사하거나 잘라 둘 수 있습니다.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space5),
            // 큰 버튼 대신 작은 + 하나. 상단 도구막대의 + 와 같은 동작이다
            IconButton.filled(
              onPressed: onPick,
              icon: const Icon(Icons.add),
              tooltip: 'PDF 가져오기',
              iconSize: 26,
            ),
            const SizedBox(height: AppTokens.space2),
            Text('PDF 가져오기', style: t.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

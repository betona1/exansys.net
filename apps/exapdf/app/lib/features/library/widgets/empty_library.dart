import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../ui/vave.dart';

/// 서재가 비었을 때 (techspec §16 · BRAND.md §6.3).
///
/// 아이콘 타일 대신 바브바브 전신을 크게 — 처음 여는 화면이 곧 캐릭터 인사다.
/// 스플래시와 같은 컷아웃이라 시작 화면에서 그대로 이어져 보인다 (BRAND.md §2.5).
class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key, required this.onPick});

  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VaveHero(width: 200),
            const SizedBox(height: AppTokens.space4),
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

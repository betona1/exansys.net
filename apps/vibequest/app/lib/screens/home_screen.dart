import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../theme.dart';

/// 홈 — 오늘 미션 CTA가 스크롤 없이 보인다 (FR-HOME-002)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('VibeQuest')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('안녕하세요! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('오늘도 3분이면 충분해요.', style: TextStyle(color: Colors.black54, fontSize: 15)),
            const SizedBox(height: 20),

            // 큰 CTA (§25: 오늘의 3분 퀘스트)
            FilledButton(
              onPressed: () => context.push('/quiz'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              child: const Text('⚡ 오늘의 3분 퀘스트'),
            ),
            const SizedBox(height: 16),

            stats.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('데이터 준비 중 문제가 생겼어요: $e'),
              data: (s) => Column(
                children: [
                  Row(children: [
                    Expanded(child: _statCard('📚', '전체 용어', '${s.totalTerms}개')),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('⏰', '오늘 복습', '${s.dueReviews}개')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _statCard('🌱', '만난 용어', '${s.learnedTerms}개')),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('💎', '보석', '${s.gems}')),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🧭', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('용어 도감 구경하기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('867개 용어를 검색해 보세요.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/glossary'),
                      icon: const Icon(Icons.arrow_forward_rounded, color: vqGreen),
                      tooltip: '용어 도감 열기',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../theme.dart';
import '../widgets/vq_widgets.dart';

/// 홈 — 디자인 킷 HOME 화면 (FR-HOME-002: 미션 버튼 스크롤 없이 노출)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider);
    final profile = ref.watch(profileStatsProvider);
    final streak = profile.valueOrNull?.streak ?? 0;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          children: [
            // 인사 + 스트릭 칩
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('반가워,',
                          style: TextStyle(
                              color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('오늘도 한 퀘스트?', style: jua(24)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: vqYellowBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('🔥 $streak일',
                      style: const TextStyle(
                          color: vqYellowText, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 오늘의 퀘스트 카드 (퍼플 그라데이션 + 비비)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6E4CFF), vqPurple, vqPurpleDark],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: vqPurpleDark.withValues(alpha: 0.45),
                      blurRadius: 34,
                      offset: const Offset(0, 20)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -4,
                    child: Opacity(opacity: 0.96, child: Bibi(size: 118)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('오늘의 퀘스트',
                            style: TextStyle(
                                color: Color(0xFFD7CCFF),
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 200,
                          child: Text('용어 7문제\n깨러 가기',
                              style: jua(23, color: Colors.white, height: 1.2)),
                        ),
                        const SizedBox(height: 14),
                        stats.when(
                          loading: () => const SizedBox(height: 16),
                          error: (e, _) => const SizedBox(height: 16),
                          data: (s) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  width: 190,
                                  child: LinearProgressIndicator(
                                    value: s.totalTerms == 0
                                        ? 0
                                        : (s.learnedTerms / s.totalTerms).clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                                    color: vqMint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  '전체 ${s.totalTerms}개 중 ${s.learnedTerms}개 만남 · 오늘 복습 ${s.dueReviews}개',
                                  style: const TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 160,
                          child: Vq3dButton(
                            label: '▶ 지금 시작',
                            color: Colors.white,
                            shadowColor: const Color(0xFFC9BEFF),
                            textColor: vqPurple,
                            height: 52,
                            fontSize: 16,
                            onPressed: () => context.push('/quiz'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 스탯 3분할 (Lv / XP / 보석)
            profile.when(
              loading: () => const SizedBox(height: 84),
              error: (e, _) => const SizedBox(),
              data: (p) => Row(
                children: [
                  Expanded(child: _stat('Lv.${p.level}', '레벨', vqPurple)),
                  const SizedBox(width: 11),
                  Expanded(child: _stat('${p.xp}', 'XP', vqMintDark)),
                  const SizedBox(width: 11),
                  Expanded(child: _stat('💎 ${p.gems}', '보석', vqCoral)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('빠른 이동', style: jua(17)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _quick(context, '🎮', '학습 모드', '복습·탐험·오답 수리', '/learn')),
                const SizedBox(width: 12),
                Expanded(
                    child: _quick(context, '📖', '용어 사전', '867개 검색', '/glossary')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: vqCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: vqPurpleDark.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: jua(20, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _quick(BuildContext context, String emoji, String title, String desc, String route) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vqCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: vqPurpleDark.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: vqLavender, borderRadius: BorderRadius.circular(12)),
              child: Text(emoji, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(desc,
                style: const TextStyle(
                    color: vqMutedText, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

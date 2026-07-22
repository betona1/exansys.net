import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../sfx.dart';
import '../theme.dart';

/// 내 기록 (§11.6) — 정답률을 전면에 크게 표시하지 않는다. 학습량·복습 우선.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('내 기록')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 레벨·보석
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: vqLime.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text('Lv${s.level}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: vqGreenDeep)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⭐ ${s.xp} XP',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          Text('다음 레벨까지 ${100 - s.xp % 100} XP',
                              style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('💎 ${s.gems}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: vqGem)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 주간 학습 + 스트릭
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📅 이번 주 학습',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const Spacer(),
                        if (s.streak > 0)
                          Text('🔥 ${s.streak}일 연속',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Column(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: s.weekDots[i]
                                      ? vqGreen
                                      : const Color(0xFFE7EAF0),
                                  shape: BoxShape.circle,
                                ),
                                child: s.weekDots[i]
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(_dayLabel(i),
                                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('하루 쉬어도 괜찮아요. 오늘 다시 이어가요.',
                        style: TextStyle(color: Colors.black45, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 학습량
            Row(
              children: [
                Expanded(child: _tile('🌱 만난 용어', '${s.metTerms}개')),
                const SizedBox(width: 10),
                Expanded(child: _tile('🏅 숙련 용어', '${s.masteredTerms}개')),
              ],
            ),
            const SizedBox(height: 12),

            // 설정 — 소리 (UX-06)
            Card(
              child: SwitchListTile(
                secondary: const Text('🔊', style: TextStyle(fontSize: 24)),
                title: const Text('효과음', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('정답·콤보·완료 소리'),
                value: !ref.watch(soundMutedProvider),
                activeThumbColor: vqGreen,
                onChanged: (on) async {
                  ref.read(soundMutedProvider.notifier).state = !on;
                  Sfx.muted = !on;
                  await ref.read(databaseProvider).setMeta('muted', on ? '0' : '1');
                  if (on) Sfx.correct(); // 켜면 맛보기
                },
              ),
            ),
            const SizedBox(height: 12),

            // 카테고리별 숙련도
            if (s.categoryMastery.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📊 분야별 숙련도',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 12),
                      for (final e in (s.categoryMastery.entries.toList()
                        ..sort((a, b) => b.value.avg.compareTo(a.value.avg))))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(e.key,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  ),
                                  Text('${e.value.count}개 · ${e.value.avg.round()}점',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black45)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: e.value.avg / 100,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE7EAF0),
                                  color: vqGreen,
                                ),
                              ),
                            ],
                          ),
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

  String _dayLabel(int i) {
    final d = DateTime.now().subtract(Duration(days: 6 - i));
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[d.weekday - 1];
  }

  Widget _tile(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

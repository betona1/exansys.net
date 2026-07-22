import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 학습 탭 — 오늘의 미션 가동. 나머지 모드는 V3에서.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학습')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _ModeCard(emoji: '⚡', title: '오늘의 미션', desc: '추천 7문제 · 약 3분', ready: true),
          _ModeCard(emoji: '⏰', title: '빠른 복습', desc: '만기 복습 5문제', ready: false),
          _ModeCard(emoji: '🧭', title: '새 용어 탐험', desc: '새 용어 8개', ready: false),
          _ModeCard(emoji: '🔧', title: '오답 수리', desc: '최근 오답 5개', ready: false),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final bool ready;
  const _ModeCard({required this.emoji, required this.title, required this.desc, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(emoji, style: const TextStyle(fontSize: 30)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        subtitle: Text(ready ? desc : '$desc · 준비 중'),
        trailing: ready ? const Icon(Icons.play_arrow_rounded) : const Icon(Icons.lock_outline, color: Colors.black26),
        onTap: ready
            ? () => context.push('/quiz')
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('곧 열려요! 다음 업데이트에서 만나요.')),
                ),
      ),
    );
  }
}

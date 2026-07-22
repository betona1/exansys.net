import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../db/database.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/vq_widgets.dart';

/// 온보딩 + 언노운 진단 (TECHSPEC §7)
/// 환영 → 하루 목표 → 관심 분야(최대 3) → 진단 12장 → 첫 퀘스트
/// 진단은 점수·스트릭에 영향 없음 (AC-002).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, time, interests, diag, done }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  int _goal = 3;
  final Set<String> _interests = {};
  List<Term> _cards = [];
  int _cardIdx = 0;
  bool _showLearn = false; // '처음 봐요' 학습 카드

  static const _interestOptions = [
    ('🤖', 'AI·에이전트', ['생성형 AI·모델', '에이전트·바이브코딩', '프롬프트·컨텍스트·RAG']),
    ('📱', '앱 만들기', ['모바일·앱 출시']),
    ('🌐', '웹·API', ['웹·프론트엔드', '백엔드·API']),
    ('🗄️', '데이터베이스', ['데이터베이스·데이터']),
    ('🚀', 'Git·배포', ['Git·DevOps·클라우드']),
    ('🎨', 'UX·UI', ['UX·UI·제품·학습게임']),
  ];

  VqDatabase get _db => ref.read(databaseProvider);

  Future<void> _startDiag() async {
    final domains = <String>[
      for (final (_, label, doms) in _interestOptions)
        if (_interests.contains(label)) ...doms,
    ];
    final cards = await _db.onboardingPicks(domains);
    await _db.setMeta('dailyGoal', '$_goal');
    setState(() {
      _cards = cards;
      _cardIdx = 0;
      _step = _Step.diag;
    });
  }

  /// 진단 응답 반영 (§7.2) — 점수·스트릭 영향 없음, 복습 일정만 잡는다
  Future<void> _answerDiag(String kind) async {
    final t = _cards[_cardIdx];
    HapticFeedback.selectionClick();
    if (kind == 'new' && !_showLearn) {
      // 처음 봐요 → 즉시 학습 카드 (15초 컷)
      setState(() => _showLearn = true);
      return;
    }
    final now = DateTime.now();
    final (state, score, next) = switch (kind) {
      'know' => ('LEARNING', 35, const Duration(days: 1)), // 확인 문제는 나중에
      'confused' => ('LEARNING', 15, const Duration(hours: 12)), // 24시간 안에
      _ => ('LEARNING', 0, Duration.zero), // 처음 봐요 → 다음 세션에서 바로
    };
    await _db.upsertState(TermStatesCompanion(
      termId: Value(t.id),
      state: Value(state),
      masteryScore: Value(score),
      lastSeenAt: Value(now),
      nextReviewAt: Value(now.add(next)),
      lastConfidence: Value(kind == 'know' ? 3 : (kind == 'confused' ? 2 : 1)),
    ));
    if (_cardIdx + 1 >= _cards.length) {
      await _db.setMeta('onboardingDone', '1');
      ref.invalidate(homeStatsProvider);
      setState(() => _step = _Step.done);
    } else {
      setState(() {
        _cardIdx++;
        _showLearn = false;
      });
    }
  }

  Future<void> _skipAll() async {
    await _db.setMeta('onboardingDone', '1');
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            _Step.welcome => _welcome(),
            _Step.time => _time(),
            _Step.interests => _interestsStep(),
            _Step.diag => _diag(),
            _Step.done => _done(),
          },
        ),
      ),
    );
  }

  // ── 1. 환영 (디자인 킷 온보딩) ──
  Widget _welcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
      child: Column(
        children: [
          const Spacer(),
          const FloatyBibi(size: 170),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: vqCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: vqPurpleDark.withValues(alpha: 0.25),
                    blurRadius: 26,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Text('안녕! 난 비비야 🐾', style: jua(19)),
                const Text('코딩 용어, 나랑 하루 몇 문제씩 깨보자!',
                    style: TextStyle(
                        color: vqMutedText, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('어려운 개발 용어,\n퀘스트로 클리어', textAlign: TextAlign.center, style: jua(30, height: 1.15)),
          const SizedBox(height: 8),
          const Text('프롬프트부터 배포까지 — 하나씩 내 것으로.',
              style: TextStyle(color: vqMutedText, fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          Vq3dButton(
            label: '퀘스트 시작하기',
            fontSize: 18,
            onPressed: () => setState(() => _step = _Step.time),
          ),
          TextButton(
            onPressed: _skipAll,
            child: const Text('먼저 둘러볼래',
                style: TextStyle(
                    color: vqMutedText, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // ── 2. 하루 몇 분? ──
  Widget _time() {
    return Padding(
      key: const ValueKey('time'),
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('하루에 몇 분\n달릴까? ⏱️', style: jua(28, height: 1.2)),
          const SizedBox(height: 6),
          const Text('부담 없는 게 최고야. 나중에 바꿀 수 있어!',
              style: TextStyle(color: vqMutedText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          for (final (min, emoji, desc) in const [
            (3, '⚡', '가볍게 7문제 · 추천!'),
            (5, '🔥', '탄탄하게 11문제'),
            (10, '💪', '빡세게 18문제'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _selectCard(
                selected: _goal == min,
                onTap: () => setState(() => _goal = min),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Text('$min분', style: jua(20)),
                    const SizedBox(width: 12),
                    Text(desc,
                        style: const TextStyle(
                            color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          Vq3dButton(label: '다음', onPressed: () => setState(() => _step = _Step.interests)),
        ],
      ),
    );
  }

  // ── 3. 관심 분야 (최대 3) ──
  Widget _interestsStep() {
    return Padding(
      key: const ValueKey('interests'),
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('뭐가 제일 궁금해? 👀', style: jua(28)),
          const SizedBox(height: 6),
          const Text('최대 3개! 골라주면 그쪽 용어부터 보여줄게.',
              style: TextStyle(color: vqMutedText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                for (final (emoji, label, _) in _interestOptions)
                  _selectCard(
                    selected: _interests.contains(label),
                    onTap: () => setState(() {
                      if (_interests.contains(label)) {
                        _interests.remove(label);
                      } else if (_interests.length < 3) {
                        _interests.add(label);
                      }
                    }),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Vq3dButton(
            label: _interests.isEmpty ? '건너뛰고 진단하기' : '좋아, 진단 시작! (12장)',
            onPressed: () => _startDiag(),
          ),
        ],
      ),
    );
  }

  // ── 4. 언노운 진단 12장 (§7.2) ──
  Widget _diag() {
    if (_cards.isEmpty) return const Center(child: CircularProgressIndicator());
    final t = _cards[_cardIdx];
    return Padding(
      key: ValueKey('diag$_cardIdx${_showLearn ? 'L' : ''}'),
      padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
      child: Column(
        children: [
          Row(
            children: [
              Text('시험 아니야! 아는 만큼만 골라줘 🐾',
                  style: const TextStyle(
                      color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('${_cardIdx + 1} / ${_cards.length}',
                  style: const TextStyle(
                      color: vqMuted2, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_cardIdx + 1) / _cards.length,
              minHeight: 8,
              backgroundColor: vqBorder,
              valueColor: const AlwaysStoppedAnimation(vqMint),
            ),
          ),
          const Spacer(),
          // 용어 카드 (처음 봐요 → 학습 카드로 뒤집힘)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _showLearn ? vqInk : vqCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: vqBorder, width: 2),
              boxShadow: [
                BoxShadow(
                    color: vqPurpleDark.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 14)),
              ],
            ),
            child: _showLearn
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.termKo, style: jua(24, color: Colors.white)),
                      Text(t.termEn,
                          style: const TextStyle(
                              color: Color(0xFF9A95B8),
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(height: 12),
                      Text(t.def,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.55,
                              fontWeight: FontWeight.w600)),
                      if (t.whyItMatters.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('💡 ${t.whyItMatters}',
                            style: const TextStyle(
                                color: Color(0xFFC9BEFF),
                                fontSize: 13.5,
                                height: 1.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: vqLavender, borderRadius: BorderRadius.circular(999)),
                        child: Text(t.category,
                            style: const TextStyle(
                                color: vqPurple,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                      const SizedBox(height: 14),
                      Text(t.termKo, textAlign: TextAlign.center, style: jua(30)),
                      const SizedBox(height: 4),
                      Text(t.termEn,
                          style: const TextStyle(
                              color: vqMuted2, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('이 용어… 알아?',
                          style: TextStyle(
                              color: vqMutedText,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
          ),
          const Spacer(),
          if (_showLearn)
            Vq3dButton(
              label: '오호, 알겠어! 다음 →',
              color: vqMint,
              shadowColor: vqMintDark,
              onPressed: () => _answerDiag('new'),
            )
          else ...[
            Vq3dButton(
              label: '😎 알아요',
              color: vqMint,
              shadowColor: vqMintDark,
              height: 54,
              onPressed: () => _answerDiag('know'),
            ),
            const SizedBox(height: 10),
            Vq3dButton(
              label: '🤔 헷갈려요',
              color: const Color(0xFFFFC93C),
              shadowColor: const Color(0xFFDBA818),
              textColor: const Color(0xFF7A5600),
              height: 54,
              onPressed: () => _answerDiag('confused'),
            ),
            const SizedBox(height: 10),
            Vq3dButton(
              label: '👀 처음 봐요',
              height: 54,
              onPressed: () => _answerDiag('new'),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5. 완료 ──
  Widget _done() {
    return Padding(
      key: const ValueKey('done'),
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
      child: Column(
        children: [
          const Spacer(),
          const FloatyBibi(size: 160),
          const SizedBox(height: 16),
          Text('준비 끝! 🎉', style: jua(30)),
          const SizedBox(height: 6),
          const Text('네가 고른 만큼만 반영했어.\n이제 첫 퀘스트 깨러 가자!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: vqMutedText, fontWeight: FontWeight.w600, fontSize: 15, height: 1.5)),
          const Spacer(),
          Vq3dButton(
            label: '⚡ 첫 퀘스트 시작!',
            fontSize: 18,
            onPressed: () {
              context.go('/');
              context.push('/quiz');
            },
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('먼저 둘러볼래',
                style: TextStyle(
                    color: vqMutedText, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _selectCard({required bool selected, required VoidCallback onTap, required Widget child}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? vqLavender : vqCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? vqPurple : vqBorder, width: 2),
        ),
        child: child,
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/mastery.dart';
import '../learning/question_gen.dart';
import '../learning/session_controller.dart';
import '../providers.dart';
import '../sfx.dart';
import '../theme.dart';

/// 문제 화면 (§11.3) + 세션 결과 (§11.4)
class QuizScreen extends ConsumerStatefulWidget {
  final SessionMode mode;
  const QuizScreen({super.key, this.mode = SessionMode.dailyMission});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _shortCtrl = TextEditingController();
  List<String> _suggestions = [];
  Timer? _autoNext;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionProvider.notifier).start(mode: widget.mode));
  }

  @override
  void dispose() {
    _autoNext?.cancel();
    _shortCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    _autoNext?.cancel();
    ref.read(sessionProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    // 효과음 + 정답 시 0.5초 자동 진행
    ref.listen(sessionProvider, (prev, next) {
      if (prev?.feedback == null && next.feedback != null) {
        if (next.feedback!.correct) {
          next.combo >= 3 ? Sfx.combo() : Sfx.correct();
          if (next.feedback!.gems > 0) {
            Future.delayed(const Duration(milliseconds: 260), Sfx.gem);
          }
          // 맞으면 0.5초 뒤 자동으로 다음 문제
          _autoNext?.cancel();
          _autoNext = Timer(const Duration(milliseconds: 500), () {
            if (mounted) ref.read(sessionProvider.notifier).next();
          });
        } else {
          Sfx.wrong();
        }
      }
      if (prev?.finished == false && next.finished) Sfx.complete();
    });

    final s = ref.watch(sessionProvider);

    if (s.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (s.empty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('지금은 풀 문제가 없어요!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('복습이나 오답이 쌓이면 다시 열려요.',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.pop(), child: const Text('돌아가기')),
              ],
            ),
          ),
        ),
      );
    }
    if (s.finished) return _ResultView(s: s);

    final q = s.current;
    if (q == null) {
      return const Scaffold(body: Center(child: Text('문제를 준비하지 못했어요.')));
    }
    final answered = s.feedback != null;

    return Scaffold(
      body: SafeArea(
        // 답변 후 좌우 스와이프로 다음 문제
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            if (answered && (d.primaryVelocity?.abs() ?? 0) > 150) _goNext();
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
          children: [
            // 상단: 닫기 / 진행바 / 콤보 (§11.3)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '학습 종료',
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: s.total == 0 ? 0 : (s.index + (answered ? 1 : 0)) / s.total,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE7EAF0),
                        color: vqGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (s.combo >= 2)
                    Text('🔥${s.combo}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('💎${s.gems}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: vqGem)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${s.index + 1} / ${s.total}',
                  style: const TextStyle(color: Colors.black45, fontSize: 13)),
            ),

            // 질문 카드 — 문제 문장 22~26sp (§12.2)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (q.isReview)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: vqLime.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('⏰ 복습',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: vqGreenDeep)),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                switch (q.type) {
                                  QType.ox => '다음 설명이 맞을까요?\n\n${q.prompt}',
                                  QType.shortText => '이 설명에 해당하는 용어는?\n\n${q.prompt}',
                                  _ => q.prompt,
                                },
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700, height: 1.45),
                              ),
                              // 공개된 힌트 (§8.3)
                              for (final h in s.hints)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: vqLime.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('💡 $h',
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 답변 영역
                    switch (q.type) {
                      QType.ox => _oxButtons(answered),
                      QType.shortText => _shortInput(answered),
                      _ => _mcqOptions(q, s, answered),
                    },
                  ],
                ),
              ),
            ),

            // 하단 피드백 시트 — 답변 후에만 (FR-QUIZ-001/002)
            _FeedbackBar(s: s, onNext: _goNext),
          ],
          ),
        ),
      ),
    );
  }

  /// 주관식 입력 — 자동완성 후보 + 힌트 (§8.3)
  Widget _shortInput(bool answered) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_suggestions.isNotEmpty && !answered)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sug in _suggestions)
                  ActionChip(
                    label: Text(sug),
                    backgroundColor: vqCard,
                    onPressed: () {
                      _shortCtrl.text = sug;
                      _submitShort();
                    },
                  ),
              ],
            ),
          ),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: answered ? null : () => ref.read(sessionProvider.notifier).requestHint(),
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: '힌트',
              style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _shortCtrl,
                enabled: !answered,
                onChanged: (v) => setState(
                    () => _suggestions = ref.read(sessionProvider.notifier).suggest(v)),
                onSubmitted: (_) => _submitShort(),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '용어를 입력하세요',
                  filled: true,
                  fillColor: vqCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: answered ? null : _submitShort,
              style: FilledButton.styleFrom(minimumSize: const Size(72, 56)),
              child: const Text('제출'),
            ),
          ],
        ),
      ],
    );
  }

  void _submitShort() {
    if (_shortCtrl.text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(sessionProvider.notifier).answer(shortInput: _shortCtrl.text);
    _shortCtrl.clear();
    setState(() => _suggestions = []);
  }

  Widget _oxButtons(bool answered) {
    return Row(
      children: [
        Expanded(child: _oxButton('O', true, answered)),
        const SizedBox(width: 12),
        Expanded(child: _oxButton('X', false, answered)),
      ],
    );
  }

  /// 차분한 브랜드 톤 — 카드형 버튼 (튀는 원색 금지)
  Widget _oxButton(String label, bool value, bool answered) {
    final isO = value;
    return SizedBox(
      height: 72, // 버튼 높이 56dp 이상 (§8.1)
      child: Material(
        color: answered
            ? const Color(0xFFEDEFF3)
            : (isO ? vqGreen.withValues(alpha: 0.1) : const Color(0xFFF0F1F5)),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: answered
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref.read(sessionProvider.notifier).answer(oxChoice: value);
                },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: answered
                    ? const Color(0xFFE7EAF0)
                    : (isO ? vqGreen.withValues(alpha: 0.45) : const Color(0xFFD5D9E2)),
                width: 1.5,
              ),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: answered ? Colors.black26 : (isO ? vqGreenDeep : vqInk))),
          ),
        ),
      ),
    );
  }

  Widget _mcqOptions(QuizQuestion q, SessionState s, bool answered) {
    return Column(
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _mcqOption(q, i, answered),
          ),
      ],
    );
  }

  Widget _mcqOption(QuizQuestion q, int i, bool answered) {
    final isAnswer = i == q.answerIndex;
    Color border = const Color(0xFFE7EAF0);
    Color bg = vqCard;
    Widget? trail;
    if (answered) {
      if (isAnswer) {
        border = vqCorrect;
        bg = vqCorrect.withValues(alpha: 0.08);
        trail = const Icon(Icons.check_circle_rounded, color: vqCorrect);
      }
    }
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: answered
          ? null
          : () {
              HapticFeedback.selectionClick();
              ref.read(sessionProvider.notifier).answer(mcqIndex: i);
            },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56), // §12.3
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(q.options[i],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, height: 1.35)),
            ),
            ?trail,
          ],
        ),
      ),
    );
  }
}

/// 하단 피드백 (UX-05, FR-QUIZ-002)
/// 정답: 크게 '정답!' + 0.5초 자동 진행 (버튼 없음)
/// 오답: 교정 설명 + 왜 중요한지·예시까지 보여주고 사용자가 넘어감 (버튼/스와이프)
class _FeedbackBar extends ConsumerWidget {
  final SessionState s;
  final VoidCallback onNext;
  const _FeedbackBar({required this.s, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = s.feedback;
    final term = s.current?.term;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, f == null ? 0 : 14, 20, f == null ? 0 : 16),
      decoration: BoxDecoration(
        color: f == null
            ? Colors.transparent
            : (f.correct ? vqCorrect.withValues(alpha: 0.12) : vqWrong.withValues(alpha: 0.09)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: f == null
          ? const SizedBox.shrink()
          : f.correct
              // ── 정답: 짧고 강하게, 0.5초 뒤 자동 진행 ──
              ? Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: vqCorrect, size: 32),
                    const SizedBox(width: 10),
                    const Text('정답!',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900, color: vqCorrect)),
                    const Spacer(),
                    _GemPop(gems: f.gems),
                  ],
                )
              // ── 오답: 명확한 글씨로 '아~' 하게 충분히 설명 ──
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.cancel_rounded, color: vqWrong, size: 30),
                        SizedBox(width: 10),
                        Text('오답',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900, color: vqWrong)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.explanation,
                                style: const TextStyle(
                                    fontSize: 16.5,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: vqInk)),
                            if (term != null && term.whyItMatters.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('💡 ${term.whyItMatters}',
                                  style: const TextStyle(
                                      fontSize: 14.5, height: 1.45, color: Colors.black87)),
                            ],
                            if (term != null && term.example.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('📌 ${term.example}',
                                  style: const TextStyle(
                                      fontSize: 14.5, height: 1.45, color: Colors.black87)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      onPressed: onNext,
                      child: const Text('알겠어요, 다음 →'),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('좌우로 밀어도 넘어가요',
                          style: TextStyle(fontSize: 11.5, color: Colors.black38)),
                    ),
                  ],
                ),
    );
  }
}

/// 보석 획득 팝 — 650ms 이내, 진행을 막지 않음 (UX-04)
class _GemPop extends StatelessWidget {
  final int gems;
  const _GemPop({required this.gems});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutBack,
      builder: (c, v, child) => Transform.scale(
        scale: 0.6 + 0.4 * v,
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Text('+$gems 💎',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: vqGem)),
    );
  }
}

/// 세션 결과 (§11.4) — 정답률보다 '익힌 용어 수' 먼저, 실패 문구 금지
class _ResultView extends ConsumerWidget {
  final SessionState s;
  const _ResultView({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = s.newTermIds.length + s.reviewTermIds.length;
    final perfect = s.answeredCount > 0 && s.correctCount == s.answeredCount;
    ref.invalidate(homeStatsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(perfect ? '🏆' : '🎉', style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                perfect ? '퍼펙트! 완벽했어요' : '오늘 $learned개 용어가 더 익숙해졌어요',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _tile('💎 보석', '+${s.gems}')),
                const SizedBox(width: 10),
                Expanded(child: _tile('⭐ XP', '+${s.xp}')),
                const SizedBox(width: 10),
                Expanded(child: _tile('🔥 최대 콤보', '${s.maxCombo}')),
              ],
            ),
            const SizedBox(height: 16),
            _tile('✅ 정답', '${s.correctCount} / ${s.answeredCount}'),
            if (s.wrongTermIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔧 다시 볼 용어',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('틀린 용어는 복습 일정에 자동으로 들어갔어요. 곧 다른 방식으로 다시 만나요.',
                          style: TextStyle(color: Colors.black54, fontSize: 13.5)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              onPressed: () {
                ref.invalidate(sessionProvider);
                ref.read(sessionProvider.notifier).start();
              },
              child: const Text('⚡ 2분 더'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: () => context.go('/'),
              child: const Text('끝내기'),
            ),
          ],
        ),
      ),
    );
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

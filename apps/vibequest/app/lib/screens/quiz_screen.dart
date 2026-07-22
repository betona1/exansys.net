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
import '../widgets/vq_widgets.dart';

/// 문제 화면 (§11.3) + 세션 결과 (§11.4) — 디자인 킷 QUIZ/RESULT 적용
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
    if (s.empty) return _emptyView(context);
    if (s.finished) return _ResultView(s: s);

    final q = s.current;
    if (q == null) {
      return const Scaffold(body: Center(child: Text('문제를 준비하지 못했어요.')));
    }
    final answered = s.feedback != null;

    return Scaffold(
      body: SafeArea(
        // 스와이프: 답변 전 O/X 문제 = 왼쪽 O·오른쪽 X 입력 / 답변 후 = 다음 문제
        child: SwipeNext(
          enabled: true,
          onSwipe: (dir) {
            if (answered) {
              _goNext();
            } else if (q.type == QType.ox) {
              HapticFeedback.selectionClick();
              ref.read(sessionProvider.notifier).answer(oxChoice: dir < 0);
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단: ✕ / 진행바 / 콤보·보석
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: vqLavender, borderRadius: BorderRadius.circular(11)),
                            child: const Text('✕',
                                style: TextStyle(
                                    color: vqPurple,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: s.total == 0
                                  ? 0
                                  : (s.index + (answered ? 1 : 0)) / s.total,
                              minHeight: 13,
                              backgroundColor: vqBorder,
                              valueColor: const AlwaysStoppedAnimation(vqPurple),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (s.combo >= 2)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text('🔥${s.combo}',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                        Text('💎${s.gems}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15, color: vqPurple)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                      children: [
                        // 카테고리 칩 + 진행
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: vqLavender,
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(q.term.category,
                                  style: const TextStyle(
                                      color: vqPurple,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5)),
                            ),
                            if (q.isReview) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE4FBF3),
                                    borderRadius: BorderRadius.circular(999)),
                                child: const Text('⏰ 복습',
                                    style: TextStyle(
                                        color: vqMintDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ),
                            ],
                            const Spacer(),
                            Text('${s.index + 1} / ${s.total}',
                                style: const TextStyle(
                                    color: vqMuted2,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 질문 리드
                        Text(
                          switch (q.type) {
                            QType.ox => '이 설명, 맞을까?',
                            QType.shortText => '이 설명에 맞는 용어는?',
                            _ => q.prompt.endsWith('?') ? '알맞은 것을 골라봐!' : '이 설명에 맞는 용어는?',
                          },
                          style: jua(16, color: vqPurple),
                        ),
                        const SizedBox(height: 8),

                        // 다크 질문 카드
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                          decoration: BoxDecoration(
                            color: vqInk,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                  color: vqInk.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16)),
                            ],
                          ),
                          child: Text(
                            q.type == QType.mcq4 && q.prompt.contains('설명으로 알맞은')
                                ? q.prompt
                                : '"${q.prompt}"',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                height: 1.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        // 힌트 (주관식)
                        for (final h in s.hints)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                  color: vqYellowBg,
                                  borderRadius: BorderRadius.circular(13)),
                              child: Text('💡 $h',
                                  style: const TextStyle(
                                      color: vqYellowText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // 답변 영역
                        switch (q.type) {
                          QType.ox => _oxButtons(answered),
                          QType.shortText => _shortInput(answered),
                          _ => _mcqOptions(q, s, answered),
                        },
                        const SizedBox(height: 120), // 피드백 시트 공간
                      ],
                    ),
                  ),
                ],
              ),

              // 하단 피드백 시트 (슬라이드 업)
              Align(
                alignment: Alignment.bottomCenter,
                child: _FeedbackSheet(s: s, onNext: _goNext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Bibi(size: 130),
              const SizedBox(height: 14),
              Text('지금은 풀 문제가 없어!', style: jua(22)),
              const SizedBox(height: 6),
              const Text('복습이나 오답이 쌓이면 다시 열려요.',
                  style: TextStyle(color: vqMutedText, fontWeight: FontWeight.w600)),
              const SizedBox(height: 22),
              SizedBox(
                  width: 180,
                  child: Vq3dButton(label: '돌아가기', onPressed: () => context.pop())),
            ],
          ),
        ),
      ),
    );
  }

  // ── O/X: ◯ 참 / ✕ 거짓 화이트 카드 + 스와이프 안내 (디자인 킷) ──
  Widget _oxButtons(bool answered) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _oxButton('← ◯  참', true, answered)),
            const SizedBox(width: 12),
            Expanded(child: _oxButton('✕  거짓 →', false, answered)),
          ],
        ),
        const SizedBox(height: 12),
        if (!answered) const _SwipeHint(text: '왼쪽으로 밀면 ◯ 참 · 오른쪽으로 밀면 ✕ 거짓'),
      ],
    );
  }

  Widget _oxButton(String label, bool value, bool answered) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: vqCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: vqBorder, width: 2),
        boxShadow: answered
            ? null
            : const [BoxShadow(color: vqBorder, offset: Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: answered
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref.read(sessionProvider.notifier).answer(oxChoice: value);
                },
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: answered ? vqMuted2 : vqInk)),
          ),
        ),
      ),
    );
  }

  // ── 4지선다: A/B/C/D 레터 카드 (디자인 킷) ──
  Widget _mcqOptions(QuizQuestion q, SessionState s, bool answered) {
    return Column(
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _mcqOption(q, i, answered),
          ),
      ],
    );
  }

  Widget _mcqOption(QuizQuestion q, int i, bool answered) {
    final isAnswer = i == q.answerIndex;
    Color border = vqBorder;
    Color bg = vqCard;
    Color letterBg = vqLavender;
    Color letterFg = vqPurple;
    Color shadow = vqBorder;
    String mark = '';
    Color markColor = vqMintDark;
    double opacity = 1;
    if (answered) {
      if (isAnswer) {
        border = vqMint;
        bg = const Color(0xFFE9FBF4);
        letterBg = vqMint;
        letterFg = Colors.white;
        shadow = vqMint;
        mark = '✓';
      } else {
        opacity = 0.5;
      }
    }
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: border, width: 2),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: answered
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    ref.read(sessionProvider.notifier).answer(mcqIndex: i);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: letterBg, borderRadius: BorderRadius.circular(9)),
                    child: Text('ABCD'[i],
                        style: TextStyle(
                            color: letterFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(q.options[i],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            color: vqInk)),
                  ),
                  if (mark.isNotEmpty)
                    Text(mark,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900, color: markColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 주관식 입력 ──
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
                    label: Text(sug,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: vqPurple)),
                    backgroundColor: vqLavender,
                    side: BorderSide.none,
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
              onPressed: answered
                  ? null
                  : () => ref.read(sessionProvider.notifier).requestHint(),
              icon: const Icon(Icons.lightbulb_outline, color: vqYellowText),
              tooltip: '힌트',
              style: IconButton.styleFrom(
                  backgroundColor: vqYellowBg, minimumSize: const Size(56, 56)),
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
                  hintText: '용어를 입력해봐',
                  hintStyle: const TextStyle(color: vqMuted2, fontWeight: FontWeight.w700),
                  filled: true,
                  fillColor: vqCard,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: vqBorder, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: vqBorder, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: vqPurple, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: Vq3dButton(
                label: '제출',
                height: 56,
                fontSize: 15,
                onPressed: answered ? null : _submitShort,
              ),
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
}

/// 하단 피드백 시트 — 비비 + 민트/코랄 (디자인 킷)
/// 정답: 0.5초 자동 진행 / 오답: 충분한 설명 + 버튼·스와이프
class _FeedbackSheet extends ConsumerWidget {
  final SessionState s;
  final VoidCallback onNext;
  const _FeedbackSheet({required this.s, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = s.feedback;
    final term = s.current?.term;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: f == null ? const Offset(0, 1.15) : Offset.zero,
      child: f == null
          ? const SizedBox.shrink()
          : SwipeNext(
              // 시트 위에서의 좌우 스와이프도 확실히 잡는다
              enabled: true,
              onSwipe: (_) => onNext(),
              behavior: HitTestBehavior.opaque,
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              decoration: BoxDecoration(
                color: f.correct ? const Color(0xFFE9FBF4) : const Color(0xFFFFEDEF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                      color: vqInk.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, -14)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Bibi(size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f.correct ? '정답이야! 좋았어' : '아깝다! 이렇게 기억해',
                          style: jua(21, color: f.correct ? vqMintDark : vqCoral),
                        ),
                      ),
                      if (f.correct) _GemPop(gems: f.gems),
                    ],
                  ),
                  if (!f.correct) ...[
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.explanation,
                                  style: const TextStyle(
                                      fontSize: 15.5,
                                      height: 1.5,
                                      fontWeight: FontWeight.w800,
                                      color: vqInk)),
                              if (term != null && term.whyItMatters.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('💡 ${term.whyItMatters}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A4470))),
                              ],
                              if (term != null && term.example.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('📌 ${term.example}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A4470))),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Vq3dButton(
                      label: '알겠어, 다음 →',
                      color: vqCoral,
                      shadowColor: const Color(0xFFD9414F),
                      onPressed: onNext,
                    ),
                    const SizedBox(height: 8),
                    const Center(child: _SwipeHint(text: '화면을 좌우로 밀면 다음 문제')),
                  ],
                ],
              ),
              ),
            ),
    );
  }
}

/// 좌우 스와이프 안내 — 화살표가 살랑이는 애니메이션
class _SwipeHint extends StatefulWidget {
  final String text;
  const _SwipeHint({required this.text});

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text('👈 ${widget.text} 👉',
          style: const TextStyle(
              fontSize: 12.5, color: vqMuted2, fontWeight: FontWeight.w700));
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (c, _) {
        final dx = 5 * (_c.value - 0.5);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
                offset: Offset(-dx, 0),
                child: const Text('👈', style: TextStyle(fontSize: 15))),
            const SizedBox(width: 7),
            Flexible(
              child: Text(widget.text,
                  style: const TextStyle(
                      fontSize: 12.5, color: vqMutedText, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 7),
            Transform.translate(
                offset: Offset(dx, 0),
                child: const Text('👉', style: TextStyle(fontSize: 15))),
          ],
        );
      },
    );
  }
}

/// 보석 획득 팝 — 550ms 비차단
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
          style: jua(19, color: vqPurple)),
    );
  }
}

/// 세션 결과 (§11.4) — 비비 팝인 + 3분할 통계 카드 (디자인 킷 RESULT)
class _ResultView extends ConsumerWidget {
  final SessionState s;
  const _ResultView({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = s.newTermIds.length + s.reviewTermIds.length;
    final acc = s.answeredCount == 0 ? 0 : (s.correctCount / s.answeredCount * 100).round();
    final title = acc >= 80 ? '퀘스트 클리어!' : (acc >= 40 ? '좋았어, 한 걸음 더!' : '괜찮아, 다시 도전!');
    final sub = acc >= 80
        ? '오늘도 실력이 쑥 올랐어 🐾'
        : '틀린 용어는 자동으로 복습에 들어갔어. 곧 다시 만나!';
    ref.invalidate(homeStatsProvider);
    ref.invalidate(profileStatsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (c, v, child) => Transform.scale(scale: v, child: child),
                child: const Bibi(size: 140),
              ),
              const SizedBox(height: 14),
              Text(title, style: jua(28)),
              const SizedBox(height: 4),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 22),

              // 3분할 통계 카드
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: vqCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: vqPurpleDark.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 14)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _cell('${s.correctCount}/${s.answeredCount}', '정답', vqPurple)),
                    Container(width: 1, height: 44, color: vqLavender),
                    Expanded(child: _cell('+${s.xp}', 'XP 획득', vqMintDark)),
                    Container(width: 1, height: 44, color: vqLavender),
                    Expanded(child: _cell('💎+${s.gems}', '보석', vqYellowText)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('오늘 $learned개 용어가 더 익숙해졌어요 · 🔥 최대 콤보 ${s.maxCombo}',
                  style: const TextStyle(
                      color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 12.5)),
              const Spacer(),

              Vq3dButton(
                label: '⚡ 한 번 더 풀기',
                onPressed: () {
                  ref.invalidate(sessionProvider);
                  ref.read(sessionProvider.notifier).start();
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('홈으로'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: jua(24, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ],
    );
  }
}

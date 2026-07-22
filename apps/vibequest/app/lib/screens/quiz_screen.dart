import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/mastery.dart';
import '../learning/question_gen.dart';
import '../learning/session_controller.dart';
import '../net/vq_api.dart';
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

                  // 방금 문제 다시보기(크게) + 신고하기 — 상시 노출
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      children: [
                        if (s.history.isNotEmpty)
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openPrevReview(s),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: vqCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: vqBorder, width: 2),
                                ),
                                child: const Text('↩ 방금 문제 다시보기',
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: vqInk)),
                              ),
                            ),
                          ),
                        if (s.history.isNotEmpty) const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openReportSheet(s),
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDEF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: vqCoral.withValues(alpha: 0.4), width: 2),
                              ),
                              child: const Text('🚩 신고하기',
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: vqCoral)),
                            ),
                          ),
                        ),
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
                            QType.wordStrip => '글자를 눌러 용어를 완성해봐!',
                            QType.matchPair => '용어와 설명, 서로 짝을 찾아줘!',
                            _ => q.prompt.endsWith('?') ? '알맞은 것을 골라봐!' : '이 설명에 맞는 용어는?',
                          },
                          style: jua(16, color: vqPurple),
                        ),
                        const SizedBox(height: 8),

                        // 다크 질문 카드 (짝맞추기는 보드가 곧 문제라 생략)
                        if (q.type != QType.matchPair)
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
                          QType.wordStrip => _WordStripBoard(
                              key: ValueKey('strip${s.index}'),
                              q: q,
                              answered: answered,
                              onDone: (m) => ref
                                  .read(sessionProvider.notifier)
                                  .answer(puzzleMistakes: m),
                            ),
                          QType.matchPair => _MatchBoard(
                              key: ValueKey('match${s.index}'),
                              q: q,
                              answered: answered,
                              onDone: (m) => ref
                                  .read(sessionProvider.notifier)
                                  .answer(puzzleMistakes: m),
                            ),
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

  // ── ↩ 방금 푼 문제 다시보기 — 정답·설명 확인 + 신고 ──
  void _openPrevReview(SessionState s) {
    final q = s.history.last;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: vqBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          children: [
            Row(
              children: [
                const Bibi(size: 44),
                const SizedBox(width: 10),
                Expanded(child: Text('방금 푼 문제야! ↩', style: jua(20))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: vqInk,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text('"${q.prompt}"',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vqCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: vqBorder, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('정답: ${q.term.termKo}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16, color: vqMintDark)),
                  const SizedBox(height: 6),
                  Text(q.explanation,
                      style: const TextStyle(fontSize: 14.5, height: 1.5)),
                  if (q.term.whyItMatters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('💡 ${q.term.whyItMatters}',
                        style: const TextStyle(
                            fontSize: 13.5, height: 1.45, color: vqMutedText)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _BeaconReportButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openReasonSheet(q);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('괜찮아, 계속 풀래'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 🚩 문제 신고 — 현재 문제 + 방금 푼 문제(다시보기) ──
  void _openReportSheet(SessionState s) {
    final current = s.current;
    final prev = s.history.isNotEmpty ? s.history.last : null;
    final showPrev = prev != null && prev.term.id != current?.term.id;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: vqBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Bibi(size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이상한 문제 발견? 🚩', style: jua(20)),
                      const Text('비비가 개발자한테 대신 전해줄게! 🐾',
                          style: TextStyle(
                              color: vqMutedText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (current != null)
              _reportTarget(ctx, '지금 이 문제', current),
            if (showPrev) ...[
              const SizedBox(height: 10),
              _reportTarget(ctx, '↩ 방금 푼 문제', prev),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reportTarget(BuildContext sheetCtx, String label, QuizQuestion q) {
    return Container(
      decoration: BoxDecoration(
        color: vqCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vqBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: vqPurple, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${q.term.termKo} — ${q.prompt}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Vq3dButton(
              label: '🚩 이 문제 신고하기',
              height: 46,
              fontSize: 14,
              color: vqCoral,
              shadowColor: const Color(0xFFD9414F),
              onPressed: () {
                Navigator.pop(sheetCtx);
                _openReasonSheet(q);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openReasonSheet(QuizQuestion q) {
    String reason = 'wrong_answer';
    final detailCtrl = TextEditingController();
    bool sending = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: vqBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              22,
              20,
              22,
              24 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('어디가 이상했어? 🤔', style: jua(20)),
              const SizedBox(height: 4),
              Text('「${q.term.termKo}」 문제를 신고할게!',
                  style: const TextStyle(
                      color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (code, label) in const [
                    ('wrong_answer', '😵 정답이 틀린 것 같아'),
                    ('typo', '✏️ 오타가 있어'),
                    ('bad_explanation', '🤔 설명이 이상해'),
                    ('other', '💬 기타'),
                  ])
                    ChoiceChip(
                      selected: reason == code,
                      label: Text(label),
                      selectedColor: vqPurple,
                      backgroundColor: vqCard,
                      labelStyle: TextStyle(
                          color: reason == code ? Colors.white : vqInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5),
                      showCheckmark: false,
                      onSelected: (_) => setSheet(() => reason = code),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailCtrl,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '자세히 알려주면 고치는 데 큰 도움이 돼! (선택)',
                  hintStyle: const TextStyle(
                      color: vqMuted2, fontWeight: FontWeight.w600, fontSize: 13.5),
                  filled: true,
                  fillColor: vqCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: vqBorder, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: vqBorder, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Vq3dButton(
                label: sending ? '알리는 중…' : '📨 관리자에게 알리기',
                onPressed: sending
                    ? null
                    : () async {
                        setSheet(() => sending = true);
                        final okSent = await VqApi.sendReport(
                          termId: q.term.id,
                          termKo: q.term.termKo,
                          questionType: q.type.name,
                          reason: reason,
                          detail: detailCtrl.text.trim().isEmpty
                              ? null
                              : detailCtrl.text.trim(),
                        );
                        if (!ctx.mounted || !mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(okSent
                                ? '고마워! 비비가 잘 전달했어 🐾 확인하고 고쳐줄게!'
                                : '앗, 인터넷이 안 되는 것 같아 😿 나중에 다시 해줘!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
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

/// 워드 스트립 (§8.4) — 글자 칩을 순서대로 탭해 용어 조립, 정답 글자 즉시 고정
class _WordStripBoard extends StatefulWidget {
  final QuizQuestion q;
  final bool answered;
  final void Function(int mistakes) onDone;
  const _WordStripBoard({super.key, required this.q, required this.answered, required this.onDone});

  @override
  State<_WordStripBoard> createState() => _WordStripBoardState();
}

class _WordStripBoardState extends State<_WordStripBoard> {
  int _filled = 0;
  int _mistakes = 0;
  final Set<int> _used = {};
  int? _shakeChip;

  void _tap(int i) {
    if (widget.answered || _used.contains(i)) return;
    final target = widget.q.answerText[_filled];
    if (widget.q.options[i] == target) {
      HapticFeedback.selectionClick();
      setState(() {
        _used.add(i);
        _filled++;
      });
      if (_filled >= widget.q.answerText.length) {
        widget.onDone(_mistakes);
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _mistakes++;
        _shakeChip = i;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _shakeChip = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final answer = widget.q.answerText;
    return Column(
      children: [
        // 채워지는 칸
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < answer.length; i++)
              Container(
                width: 42,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i < _filled ? const Color(0xFFE9FBF4) : vqCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: i < _filled ? vqMint : vqBorder, width: 2),
                ),
                child: Text(i < _filled ? answer[i] : '',
                    style: jua(20, color: vqMintDark)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        // 글자 칩
        Wrap(
          spacing: 9,
          runSpacing: 9,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < widget.q.options.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(
                    _shakeChip == i ? 4 : 0, 0, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _tap(i),
                  child: Container(
                    width: 50,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _used.contains(i) ? vqBorder : vqCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _shakeChip == i ? vqCoral : vqBorder, width: 2),
                      boxShadow: _used.contains(i)
                          ? null
                          : const [BoxShadow(color: vqBorder, offset: Offset(0, 3))],
                    ),
                    child: Text(widget.q.options[i],
                        style: jua(20,
                            color: _used.contains(i) ? vqMuted2 : vqInk)),
                  ),
                ),
              ),
          ],
        ),
        if (_mistakes > 0) ...[
          const SizedBox(height: 10),
          Text('앗! $_mistakes번 헷갈렸어 😅',
              style: const TextStyle(
                  color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ],
    );
  }
}

/// 짝 맞추기 (§8.5.F) — 용어 3개 ↔ 설명 3개 연결
class _MatchBoard extends StatefulWidget {
  final QuizQuestion q;
  final bool answered;
  final void Function(int mistakes) onDone;
  const _MatchBoard({super.key, required this.q, required this.answered, required this.onDone});

  @override
  State<_MatchBoard> createState() => _MatchBoardState();
}

class _MatchBoardState extends State<_MatchBoard> {
  int? _selectedTerm; // 왼쪽에서 고른 인덱스
  final Set<int> _doneTerms = {};
  final Set<int> _doneDefs = {};
  int _mistakes = 0;
  int? _shakeDef;
  late final List<int> _defOrder; // 오른쪽 정의 셔플 순서

  @override
  void initState() {
    super.initState();
    _defOrder = List.generate(widget.q.matchPairs.length, (i) => i)..shuffle();
  }

  void _tapDef(int pos) {
    if (widget.answered || _doneDefs.contains(pos) || _selectedTerm == null) return;
    final defPairIdx = _defOrder[pos];
    if (defPairIdx == _selectedTerm) {
      HapticFeedback.selectionClick();
      setState(() {
        _doneTerms.add(_selectedTerm!);
        _doneDefs.add(pos);
        _selectedTerm = null;
      });
      if (_doneTerms.length >= widget.q.matchPairs.length) {
        widget.onDone(_mistakes);
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _mistakes++;
        _shakeDef = pos;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _shakeDef = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.q.matchPairs;
    return Column(
      children: [
        // 용어 칩 (위)
        Wrap(
          spacing: 9,
          runSpacing: 9,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < pairs.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.answered || _doneTerms.contains(i)
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTerm = i);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _doneTerms.contains(i)
                        ? const Color(0xFFE9FBF4)
                        : (_selectedTerm == i ? vqLavender : vqCard),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _doneTerms.contains(i)
                            ? vqMint
                            : (_selectedTerm == i ? vqPurple : vqBorder),
                        width: 2),
                  ),
                  child: Text(pairs[i].$1,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _doneTerms.contains(i) ? vqMintDark : vqInk)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedTerm == null ? '① 용어를 먼저 골라줘!' : '② 이제 어울리는 설명을 찾아봐!',
          style: const TextStyle(
              color: vqMutedText, fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        // 설명 카드 (아래, 셔플)
        for (var pos = 0; pos < pairs.length; pos++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(_shakeDef == pos ? 4 : 0, 0, 0),
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _tapDef(pos),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _doneDefs.contains(pos) ? const Color(0xFFE9FBF4) : vqCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _doneDefs.contains(pos)
                          ? vqMint
                          : (_shakeDef == pos ? vqCoral : vqBorder),
                      width: 2),
                ),
                child: Row(
                  children: [
                    if (_doneDefs.contains(pos)) ...[
                      Text(pairs[_defOrder[pos]].$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: vqMintDark)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(pairs[_defOrder[pos]].$2,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600)),
                    ),
                    if (_doneDefs.contains(pos))
                      const Text('✓',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: vqMintDark)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 🚨 경광등 신고 버튼 — 붉은 광이 깜빡이며 시선을 끈다 (모션감소 시 정적)
class _BeaconReportButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _BeaconReportButton({required this.onPressed});

  @override
  State<_BeaconReportButton> createState() => _BeaconReportButtonState();
}

class _BeaconReportButtonState extends State<_BeaconReportButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (c, child) {
        final glow = reduce ? 0.5 : _c.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: vqCoral.withValues(alpha: 0.25 + 0.4 * glow),
                blurRadius: 14 + 14 * glow,
                spreadRadius: 1 + 3 * glow,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Vq3dButton(
        label: '🚨 신고하기',
        color: vqCoral,
        shadowColor: const Color(0xFFD9414F),
        height: 56,
        fontSize: 17,
        onPressed: widget.onPressed,
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

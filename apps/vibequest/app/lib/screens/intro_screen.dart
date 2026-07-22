import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../db/content_importer.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/vq_widgets.dart';

// ── 디자인 킷 로딩 화면 팔레트 ──
const _bgTop = Color(0xFF3A2C7A);
const _bgMid = Color(0xFF241C55);
const _bgBottom = Color(0xFF1A143F);
const _term = Color(0xFF131029);
const _termBorder = Color(0xFF2C2560);
const _termLine = Color(0xFF241E4F);
const _txt = Color(0xFFEDEBFF);
const _mutedP = Color(0xFFB9B2E8);
const _lav = Color(0xFFC9BEFF);
const _mint = vqMint;

/// 인트로 (디자인 킷 '로딩 애니메이션') — 콘텐츠 로딩 동안
/// 비비가 claude code 터미널에서 실제 바이브코딩 시연:
/// 프롬프트 타이핑 → API 분석 스트리밍 → 웹페이지가 짠! → 이동.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  Timer? _tick;
  double _t = 0; // 연출 경과 시간(초)
  bool _bootDone = false;
  bool _onboarded = true;
  bool _skipped = false;
  bool _navigated = false;

  // 시나리오 타이밍(초)
  static const _prompt = '환율 계산기 웹앱 만들어줘. 하나은행 API로 1분마다 실시간 갱신!';
  static const _typeEnd = 2.6;
  static const _l1 = 2.9; // ⟳ API 연결
  static const _l2 = 3.9; // ✓ 파싱 완료
  static const _l3 = 4.6; // ⟳ 웹페이지 빌드
  static const _pop = 5.6; // 결과 짠!
  static const _seqEnd = 7.2;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _t += 0.05;
        // 로딩이 길면 연출 반복 (프롬프트는 유지)
        if (_t >= _seqEnd && !_bootDone) _t = _typeEnd;
      });
      _maybeGo();
    });
    _boot();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final db = ref.read(databaseProvider);
    final importer = ContentImporter(db);
    await importer.importIfNeeded();
    bool updated = false;
    try {
      updated = await importer
          .checkRemoteUpdate()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {/* 오프라인 무시 */}
    if (updated) {
      ref.invalidate(glossaryResultsProvider);
      ref.invalidate(homeStatsProvider);
    }
    _onboarded = (await db.getMeta('onboardingDone')) == '1';
    _bootDone = true;
    _maybeGo();
  }

  void _maybeGo() {
    if (_navigated || !_bootDone) return;
    // 스킵했거나 연출이 결과 컷까지 끝났으면 이동
    if (_skipped || _t >= _seqEnd) {
      _navigated = true;
      _tick?.cancel();
      if (mounted) context.go(_onboarded ? '/' : '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    // 장면을 화면 폭에 맞춰 크게 (내부는 310x300 기준 → 통째로 스케일업)
    final sceneW = (MediaQuery.of(context).size.width - 36).clamp(280.0, 420.0);
    final sceneH = sceneW / 310 * 300;
    return Scaffold(
      backgroundColor: _bgBottom, // 그라데이션 밖 픽셀도 다크 (흰 라인 방지)
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.3,
            colors: [_bgTop, _bgMid, _bgBottom],
            stops: [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text('Vibe Quest', style: jua(28, color: Colors.white)),
              const SizedBox(height: 2),
              const Text('오늘의 퀘스트를 준비하고 있어',
                  style: TextStyle(
                      color: _mutedP, fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 10),
              SizedBox(
                width: sceneW,
                height: sceneH,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 310,
                    height: 300,
                    child: _LaptopScene(t: _t, reduce: reduce),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 진행바 (민트→퍼플)
              SizedBox(
                width: sceneW * 0.92,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('데이터 불러오는 중…',
                            style: TextStyle(
                                color: _lav,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                        Text('Claude Code',
                            style: TextStyle(
                                color: Color(0xFF8FE3C6),
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: [
                          Container(height: 10, color: Colors.white.withValues(alpha: 0.14)),
                          FractionallySizedBox(
                            widthFactor:
                                _bootDone ? 1 : (0.08 + 0.86 * ((_t / _seqEnd).clamp(0, 1))),
                            child: Container(
                              height: 10,
                              decoration: const BoxDecoration(
                                gradient:
                                    LinearGradient(colors: [_mint, Color(0xFF7B5CFF)]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Dots(t: _t),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  _skipped = true;
                  _maybeGo();
                },
                child: const Text('바로 시작하기 →',
                    style: TextStyle(
                        color: Color(0xFF8983B8),
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 노트북 + 비비 장면 — 터미널에서 바이브코딩 시연
class _LaptopScene extends StatelessWidget {
  final double t;
  final bool reduce;
  const _LaptopScene({required this.t, required this.reduce});

  @override
  Widget build(BuildContext context) {
    final bob = reduce ? 0.0 : sin(t * 2 * pi / 0.5) * 1.6; // 타이핑 리듬으로 들썩
    final pawL = reduce ? 0.0 : (sin(t * 2 * pi / 0.5) * 3).clamp(-3, 0).toDouble();
    final pawR = reduce ? 0.0 : (sin(t * 2 * pi / 0.5 + pi) * 3).clamp(-3, 0).toDouble();
    return SizedBox(
      width: 310,
      height: 300,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 터미널 화면 (위)
          Positioned(
            top: 0,
            child: Container(
              width: 272,
              height: 158,
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
              decoration: BoxDecoration(
                color: _term,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _termBorder, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF12D8A0)
                          .withValues(alpha: reduce ? 0.1 : 0.10 + 0.08 * sin(t * 2.6)),
                      blurRadius: 26,
                      spreadRadius: 2),
                ],
              ),
              child: _TerminalContent(t: t),
            ),
          ),
          // 키보드 하판
          Positioned(
            top: 162,
            child: Container(
              width: 306,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A3178), Color(0xFF26205C)]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7), bottom: Radius.circular(13)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 22,
                      offset: const Offset(0, 12)),
                ],
              ),
            ),
          ),
          // 타이핑하는 앞발 (키보드 위, 몸 옆으로 보이게)
          Positioned(
            top: 160 + pawL,
            left: 310 / 2 - 72,
            child: _paw(),
          ),
          Positioned(
            top: 160 + pawR,
            left: 310 / 2 + 44,
            child: _paw(),
          ),
          // 화면을 바라보는 비비 뒷모습 (맨 앞)
          Positioned(
            top: 128 + bob,
            child: const BibiBack(size: 168),
          ),
        ],
      ),
    );
  }

  Widget _paw() => Container(
        width: 28,
        height: 15,
        decoration: BoxDecoration(
          color: const Color(0xFFB7C2D6),
          borderRadius: BorderRadius.circular(10),
        ),
      );
}

/// 터미널 내용 — 프롬프트 타이핑 → 분석 스트리밍 → 웹페이지 짠!
class _TerminalContent extends StatelessWidget {
  final double t;
  const _TerminalContent({required this.t});

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.5,
    height: 1.4,
    color: _mutedP,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final typedCount =
        ((t / _IntroScreenState._typeEnd) * _IntroScreenState._prompt.length)
            .clamp(0, _IntroScreenState._prompt.length)
            .toInt();
    final caretOn = (t * 2.5).floor() % 2 == 0;
    final showResult = t >= _IntroScreenState._pop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀 바 (신호등 + claude code)
        Row(
          children: [
            _dot(const Color(0xFFFF5B6E)),
            const SizedBox(width: 6),
            _dot(const Color(0xFFFFC93C)),
            const SizedBox(width: 6),
            _dot(_mint),
            const Spacer(),
            const Text('claude code',
                style: TextStyle(
                    color: Color(0xFF6E67A8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ],
        ),
        Container(
            height: 1, color: _termLine, margin: const EdgeInsets.symmetric(vertical: 7)),
        Expanded(
          child: showResult
              ? _ResultWebPage(t: t)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ❯ 프롬프트 타이핑
                    RichText(
                      maxLines: 2,
                      text: TextSpan(
                        style: _mono.copyWith(color: _txt),
                        children: [
                          const TextSpan(
                              text: '❯ ',
                              style: TextStyle(
                                  color: _mint, fontWeight: FontWeight.w800)),
                          TextSpan(
                              text: _IntroScreenState._prompt
                                  .substring(0, typedCount)),
                          if (caretOn)
                            const TextSpan(
                                text: '▏', style: TextStyle(color: _mint)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (t >= _IntroScreenState._l1)
                      _line(
                        spinner: t < _IntroScreenState._l2,
                        text: '하나은행 환율 API 연결 중…',
                        done: t >= _IntroScreenState._l2,
                      ),
                    if (t >= _IntroScreenState._l2)
                      _line(spinner: false, text: '실시간 데이터 파싱 완료', done: true),
                    if (t >= _IntroScreenState._l3)
                      _line(
                        spinner: t < _IntroScreenState._pop,
                        text: '웹페이지 빌드 중…',
                        done: t >= _IntroScreenState._pop,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _dot(Color c) =>
      Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _line({required bool spinner, required String text, required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (spinner)
            const SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _mint, backgroundColor: Color(0xFF4A3E9E)),
            )
          else
            const Text('✓',
                style: TextStyle(
                    color: _mint, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: _mono, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// 완성된 환율 계산기 웹페이지 — 짠! (popin)
class _ResultWebPage extends StatelessWidget {
  final double t;
  const _ResultWebPage({required this.t});

  @override
  Widget build(BuildContext context) {
    final p = ((t - _IntroScreenState._pop) / 0.45).clamp(0.0, 1.0);
    final scale = Curves.easeOutBack.transform(p);
    return Center(
      child: Transform.scale(
        scale: 0.6 + 0.4 * scale,
        child: Opacity(
          opacity: p,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE7E2FF), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE7E2FF), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('💱 환율 계산기',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800, color: vqInk)),
                    const Spacer(),
                    const Text('LIVE',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: vqCoral)),
                  ],
                ),
                const SizedBox(height: 7),
                const Text('1 USD = 1,383.20원',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900, color: vqInk)),
                const Text('▲ 2.4  ·  1분마다 자동 갱신',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: vqMintDark)),
                const SizedBox(height: 7),
                Row(
                  children: [
                    for (final h in const [14.0, 20.0, 11.0, 24.0, 17.0, 28.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 12,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B5CFF)
                                .withValues(alpha: 0.25 + h / 40),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('✓ 완성! 배포까지 끝났어 🎉',
                    style: TextStyle(
                        fontSize: 9.5, fontWeight: FontWeight.w800, color: vqMintDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 점 3개 페이드
class _Dots extends StatelessWidget {
  final double t;
  const _Dots({required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: 0.35 + 0.65 * ((sin(t * 2 * pi / 1.2 - i * 0.9) + 1) / 2),
              child: Container(
                width: 7,
                height: 7,
                decoration:
                    const BoxDecoration(color: _lav, shape: BoxShape.circle),
              ),
            ),
          ),
      ],
    );
  }
}

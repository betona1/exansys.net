import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../db/content_importer.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/vq_widgets.dart';

/// 인트로 — 콘텐츠 로딩(번들 import + 웹 JSON 업데이트) 동안
/// 비비가 열심히 바이브코딩하는 애니메이션 → 완성 컷 → 홈.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  bool _done = false; // 코딩 끝 → 결과물 컷
  String _status = '비비가 열심히 바이브코딩 중… 🐾';
  Timer? _statusTimer;
  int _statusIdx = 0;

  static const _statuses = [
    '비비가 열심히 바이브코딩 중… 🐾',
    '최신 용어 데이터 받아오는 중… 📡',
    'AI한테 문제 만들어 달라는 중… 🤖',
    '보석 창고 정리하는 중… 💎',
  ];

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (!mounted || _done) return;
      setState(() => _status = _statuses[++_statusIdx % _statuses.length]);
    });
    _boot();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final t0 = DateTime.now();
    final db = ref.read(databaseProvider);
    final importer = ContentImporter(db);
    await importer.importIfNeeded();
    // 웹에서 최신 용어 JSON 확인 (오프라인·느린 망이면 4초 안에 포기하고 진행)
    bool updated = false;
    try {
      updated = await importer
          .checkRemoteUpdate()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {/* 무시 */}
    if (updated) {
      ref.invalidate(glossaryResultsProvider);
      ref.invalidate(homeStatsProvider);
    }
    // 애니메이션이 보이도록 최소 2.2초는 유지
    final elapsed = DateTime.now().difference(t0);
    if (elapsed < const Duration(milliseconds: 2200)) {
      await Future.delayed(const Duration(milliseconds: 2200) - elapsed);
    }
    if (!mounted) return;
    setState(() {
      _done = true;
      _status = updated ? '따끈한 새 용어 도착! ✨' : '완성! 출발하자 🐾';
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0820),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('Vibe Quest', style: jua(34, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('AI 용어, 퀘스트로 클리어!',
                style: TextStyle(
                    color: Color(0xFFC9BEFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const Spacer(),
            _CodingBibi(done: _done),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _status,
                key: ValueKey(_status),
                style: const TextStyle(
                    color: Color(0xFF9A95B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
            const SizedBox(height: 14),
            if (!_done)
              const SizedBox(
                width: 130,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Color(0xFF221B4A),
                  valueColor: AlwaysStoppedAnimation(vqMint),
                ),
              )
            else
              const SizedBox(height: 6),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// 비비가 노트북 앞에서 타닥타닥 → 완성되면 화면에 ✨ 결과물 팝
class _CodingBibi extends StatefulWidget {
  final bool done;
  const _CodingBibi({required this.done});

  @override
  State<_CodingBibi> createState() => _CodingBibiState();
}

class _CodingBibiState extends State<_CodingBibi> with TickerProviderStateMixin {
  late final AnimationController _type = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260))
    ..repeat(reverse: true);
  Timer? _lineTimer;
  int _lines = 0;
  final _rng = Random();
  List<List<(double, Color)>> _code = [];

  static const _tokenColors = [vqMint, Color(0xFFC9BEFF), vqCoral, Color(0xFFFFC93C), Color(0xFF7B9EFF)];

  @override
  void initState() {
    super.initState();
    _code = _genCode();
    _lineTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
      if (!mounted || widget.done) return;
      setState(() {
        _lines++;
        if (_lines > _code.length) {
          // 다 치면 새 파일(?)을 다시 타이핑 — 로딩이 긴 경우 반복
          _lines = 0;
          _code = _genCode();
        }
      });
    });
  }

  List<List<(double, Color)>> _genCode() => List.generate(6, (i) {
        final n = 2 + _rng.nextInt(3);
        return List.generate(
            n, (_) => (18.0 + _rng.nextInt(46), _tokenColors[_rng.nextInt(_tokenColors.length)]));
      });

  @override
  void dispose() {
    _type.dispose();
    _lineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      children: [
        // 노트북 화면 — 코드 타이핑 / 완성 컷
        Container(
          width: 240,
          height: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF16113A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF2B2360), width: 3),
          ),
          child: widget.done ? _resultCut() : _codeScreen(),
        ),
        // 노트북 하판(키보드)
        Container(
          width: 280,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2360),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        // 비비 — 타닥타닥 (빠른 바운스), 완성되면 살랑
        reduce
            ? const Bibi(size: 110)
            : AnimatedBuilder(
                animation: _type,
                builder: (c, child) => Transform.translate(
                  offset: Offset(0, widget.done ? -4 * _type.value : -3 * _type.value),
                  child: Transform.rotate(
                    angle: widget.done ? 0 : (_type.value - 0.5) * 0.05,
                    child: child,
                  ),
                ),
                child: const Bibi(size: 110),
              ),
      ],
    );
  }

  /// 타이핑되는 코드 라인 (색 토큰 바) + 깜빡이는 커서
  Widget _codeScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _lines.clamp(0, _code.length); i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                for (final (w, color) in _code[i])
                  Container(
                    width: w,
                    height: 8,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(3)),
                  ),
              ],
            ),
          ),
        // 커서
        AnimatedBuilder(
          animation: _type,
          builder: (c, _) => Opacity(
            opacity: _type.value > 0.5 ? 1 : 0.15,
            child: Container(width: 8, height: 12, color: vqMint),
          ),
        ),
      ],
    );
  }

  /// 완성 컷 — 만들어진 앱 창이 뿅!
  Widget _resultCut() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (c, v, child) =>
            Transform.scale(scale: v, child: Opacity(opacity: v.clamp(0, 1), child: child)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 2),
              Text('앱 완성!', style: jua(16, color: vqInk)),
              const Text('vibe check ✓',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: vqMintDark)),
            ],
          ),
        ),
      ),
    );
  }
}

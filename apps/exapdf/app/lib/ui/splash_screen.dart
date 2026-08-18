import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/tokens.dart';
import 'vave.dart';

/// 앱 시작 히어로 로딩 페이지 — 바브바브가 맞이하는 약 3초.
///
/// 라우터 위에 겹쳐 그리고 시간이 지나면 서서히 걷어낸다. 뒤에서 서재가
/// 미리 그려지고 있으므로 스플래시가 사라진 순간 바로 쓸 수 있다 —
/// 스플래시 때문에 실제로 기다리는 시간은 없다.
///
/// `MediaQuery.disableAnimations` 면 움직임 없이 정지 화면만 보이고
/// 노출 시간도 절반으로 줄인다 (BRAND.md §2.3 접근성 규칙).
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  /// 히어로를 온전히 보여주는 시간. 페이드까지 합쳐 약 3초가 된다
  static const hold = Duration(milliseconds: 2600);
  static const fade = Duration(milliseconds: 450);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _fading = false; // 걷어내는 중
  bool _gone = false; // 트리에서 제거됨
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 접근성 설정은 context 가 있어야 읽을 수 있어 initState 가 아니라 여기서
    _timer ??= Timer(
      MediaQuery.disableAnimationsOf(context)
          ? SplashGate.hold ~/ 2
          : SplashGate.hold,
      () {
        if (mounted) setState(() => _fading = true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      children: [
        widget.child,
        // 페이드가 시작되면 아래 화면이 바로 만져지게 입력을 통과시킨다.
        // Stack 의 느슨한 제약에서 내용 크기로 줄지 않게 반드시 fill 로 편다
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _fading,
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: SplashGate.fade,
              curve: Curves.easeOut,
              onEnd: () {
                if (_fading && mounted) setState(() => _gone = true);
              },
              child: const _SplashHero(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 히어로 화면 본체 — 아이콘과 같은 네이비 그라디언트 위에 바브바브 전신.
class _SplashHero extends StatefulWidget {
  const _SplashHero();

  @override
  State<_SplashHero> createState() => _SplashHeroState();
}

class _SplashHeroState extends State<_SplashHero>
    with SingleTickerProviderStateMixin {
  /// 떠 있는 듯한 상하 부유 루프
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }

    final width = MediaQuery.sizeOf(context).width;
    final heroWidth = math.min(width * 0.58, 300.0);

    // MaterialApp.builder 는 Navigator 밖이라 Material 조상이 없다 —
    // 없으면 Text 가 노란 밑줄의 기본 스타일로 그려진다
    return Material(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          // 아이콘과 같은 결 — 위는 깊은 남색, 캐릭터가 서는 아래로 갈수록 밝은 블루
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTokens.vaveNavyLo, AppTokens.vaveNavyHi],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // 등장(살짝 커지며 나타남) + 부유. 접근성 모드면 둘 다 없다
              TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, t, child) => Opacity(
                  opacity: t,
                  child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
                ),
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      0,
                      still ? 0 : math.sin(_float.value * 2 * math.pi) * 5,
                    ),
                    child: child,
                  ),
                  child: VaveHero(width: heroWidth),
                ),
              ),
              const SizedBox(height: AppTokens.space5),
              Text(
                'ExaPDF',
                style: TextStyle(
                  color: AppTokens.textPrimaryDark,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                'PDF를, 책처럼.',
                style: TextStyle(
                  color: AppTokens.textSecondaryDark,
                  fontSize: 15,
                ),
              ),
              const Spacer(flex: 4),
              // 하단 모회사 마크 — 시끄럽지 않게 (BRAND.md §1 톤)
              Text(
                'EXANSYS',
                style: TextStyle(
                  color: AppTokens.vaveCyan.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: AppTokens.space5),
            ],
          ),
        ),
      ),
    );
  }
}

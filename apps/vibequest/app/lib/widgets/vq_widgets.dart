import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// 듀오링고식 3D 버튼 — 아래 단색 그림자 (디자인 킷 BUTTONS)
class Vq3dButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final double height;
  final double fontSize;
  const Vq3dButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = vqPurple,
    this.shadowColor = vqPurpleDark,
    this.textColor = Colors.white,
    this.height = 58,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 5))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'GothicA1',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 좌우 스와이프 감지. 속도가 아니라 **이동 거리**(48px) 기준이라
/// 천천히 밀어도 동작하고, 임계 도달 즉시 발동해 반응이 빠르다.
/// onSwipe(dir): dir = -1 왼쪽, +1 오른쪽.
class SwipeNext extends StatefulWidget {
  final bool enabled;
  final void Function(int dir) onSwipe;
  final Widget child;
  final HitTestBehavior behavior;
  const SwipeNext({
    super.key,
    required this.enabled,
    required this.onSwipe,
    required this.child,
    this.behavior = HitTestBehavior.translucent,
  });

  @override
  State<SwipeNext> createState() => _SwipeNextState();
}

class _SwipeNextState extends State<SwipeNext> {
  double _dx = 0;
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onHorizontalDragStart: (_) {
        _dx = 0;
        _fired = false;
      },
      onHorizontalDragUpdate: (d) {
        if (_fired || !widget.enabled) return;
        _dx += d.delta.dx;
        if (_dx.abs() > 48) {
          _fired = true;
          widget.onSwipe(_dx < 0 ? -1 : 1);
        }
      },
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (!_fired && widget.enabled && v.abs() > 60) {
          widget.onSwipe(v < 0 ? -1 : 1);
        }
      },
      child: widget.child,
    );
  }
}

/// 마스코트 '비비' (러시안 블루 · 민트 스카프)
class Bibi extends StatelessWidget {
  final double size;
  const Bibi({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/mascot/bibi.svg',
      width: size,
      height: size * 1.08,
      semanticsLabel: '마스코트 비비',
    );
  }
}

/// 위아래로 살랑이는 비비 (floaty 애니메이션)
class FloatyBibi extends StatefulWidget {
  final double size;
  const FloatyBibi({super.key, this.size = 140});

  @override
  State<FloatyBibi> createState() => _FloatyBibiState();
}

class _FloatyBibiState extends State<FloatyBibi> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 모션 감소 설정 존중 (§18)
    if (MediaQuery.of(context).disableAnimations) return Bibi(size: widget.size);
    return AnimatedBuilder(
      animation: _c,
      builder: (c, child) => Transform.translate(
        offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Bibi(size: widget.size),
    );
  }
}

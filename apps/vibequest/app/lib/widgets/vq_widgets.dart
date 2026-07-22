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

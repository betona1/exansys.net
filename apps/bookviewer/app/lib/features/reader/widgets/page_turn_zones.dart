import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 화면 좌·우 가장자리를 눌러 쪽을 넘기는 영역과, 그것을 알려 주는 표시.
///
/// techspec §5: `페이지 넘김 — 좌우 스와이프 / 화면 가장자리 탭`.
/// 가운데를 누르면 도구막대를 접었다 편다.
///
/// **처음에만 두 번 깜빡여 알리고, 그다음에는 거의 보이지 않게 둔다.**
/// 늘 또렷하면 본문 글자를 읽는 데 방해가 된다. 그렇다고 아예 안 보이면
/// 여기를 누를 수 있다는 것을 아무도 모른다.
class PageTurnZones extends StatefulWidget {
  const PageTurnZones({
    super.key,
    required this.highlighted,
    required this.canPrev,
    required this.canNext,
  });

  /// 넘긴 직후처럼 잠깐 또렷하게 보여 줄 때
  final bool highlighted;
  final bool canPrev;
  final bool canNext;

  /// 좌·우 가장자리로 볼 폭의 비율. 이보다 안쪽은 도구막대 토글이다
  static const edgeFraction = 0.22;

  /// 가장자리 영역의 최대 폭(dp). 태블릿·데스크톱에서 22% 는 지나치게 넓다
  static const maxEdgeWidth = 140.0;

  /// 평상시 화살표 진하기. 글자를 가리지 않을 만큼만
  static const restingOpacity = 0.11;

  /// 탭 위치가 어느 동작인지 (-1 이전, 0 토글, 1 다음)
  static int zoneOf(double dx, double width) {
    if (width <= 0) return 0;
    final edge = edgeWidth(width);
    if (dx < edge) return -1;
    if (dx > width - edge) return 1;
    return 0;
  }

  static double edgeWidth(double width) {
    final byRatio = width * edgeFraction;
    return byRatio > maxEdgeWidth ? maxEdgeWidth : byRatio;
  }

  @override
  State<PageTurnZones> createState() => _PageTurnZonesState();
}

class _PageTurnZonesState extends State<PageTurnZones> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// 처음 한 번: 또렷 → 흐림 → 또렷 → 서서히 사라짐.
  /// 두 번 깜빡여 "여기를 누르면 넘어간다"를 알린 뒤 물러난다
  late final Animation<double> _introOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 22),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.25), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 1), weight: 10),
    TweenSequenceItem(tween: ConstantTween(1), weight: 18),
    // 점점 흐려져 평상시 밝기로 내려앉는다
    TweenSequenceItem(
      tween: Tween(begin: 1, end: PageTurnZones.restingOpacity),
      weight: 40,
    ),
  ]).animate(_intro);

  @override
  void initState() {
    super.initState();
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final edge = PageTurnZones.edgeWidth(c.maxWidth);
          return AnimatedBuilder(
            animation: _introOpacity,
            builder: (context, _) {
              // 처음 안내가 끝나면 평상시 밝기. 넘긴 직후에는 잠깐 또렷하게
              final base = _intro.isAnimating
                  ? _introOpacity.value
                  : (widget.highlighted ? 0.55 : PageTurnZones.restingOpacity);
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: edge,
                    child: _Zone(
                      icon: Icons.chevron_left,
                      label: '이전',
                      enabled: widget.canPrev,
                      opacity: base,
                      showLabel: _intro.isAnimating || widget.highlighted,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: edge,
                    child: _Zone(
                      icon: Icons.chevron_right,
                      label: '다음',
                      enabled: widget.canNext,
                      opacity: base,
                      showLabel: _intro.isAnimating || widget.highlighted,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Zone extends StatelessWidget {
  const _Zone({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.opacity,
    required this.showLabel,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final double opacity;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final o = enabled ? opacity : opacity * 0.35;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        // 글씨는 안내하는 동안만. 평소에 떠 있으면 본문을 가린다
        AnimatedOpacity(
          opacity: showLabel && enabled ? (o * 0.9).clamp(0.0, 1.0) : 0,
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.only(top: AppTokens.space1),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 화면 좌·우 가장자리를 눌러 쪽을 넘기는 영역과, 그것을 알려 주는 표시.
///
/// techspec §5: `페이지 넘김 — 좌우 스와이프 / 화면 가장자리 탭`.
/// 가운데를 누르면 도구막대를 접었다 편다.
///
/// 화살표는 **늘 옅게 보인다.** 영역이 눈에 안 보이면 아무도 쓰지 않고,
/// 처음 한 번만 보여 주면 잊어버린다. 대신 아주 옅게 두어 읽기를 방해하지 않는다.
/// 넘길 때·도구막대를 펼 때는 잠깐 또렷해진다.
class PageTurnZones extends StatelessWidget {
  const PageTurnZones({
    super.key,
    required this.highlighted,
    required this.canPrev,
    required this.canNext,
  });

  /// 잠깐 또렷하게 보여 줄 때
  final bool highlighted;
  final bool canPrev;
  final bool canNext;

  /// 좌·우 가장자리로 볼 폭의 비율. 이보다 안쪽은 도구막대 토글이다
  static const edgeFraction = 0.22;

  /// 가장자리 영역의 최대 폭(dp). 태블릿·데스크톱에서 22% 는 지나치게 넓다
  static const maxEdgeWidth = 140.0;

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
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final edge = edgeWidth(c.maxWidth);
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
                  enabled: canPrev,
                  highlighted: highlighted,
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
                  enabled: canNext,
                  highlighted: highlighted,
                ),
              ),
            ],
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
    required this.highlighted,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // 평소에는 아주 옅게. 넘길 때만 또렷하게
    final iconAlpha = !enabled
        ? 0.12
        : highlighted
        ? 0.92
        : 0.30;
    final backdrop = highlighted && enabled ? 0.26 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: backdrop)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOpacity(
            opacity: iconAlpha,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          // 글자는 또렷할 때만 — 평소에 떠 있으면 읽기를 방해한다
          AnimatedOpacity(
            opacity: highlighted && enabled ? 0.9 : 0,
            duration: const Duration(milliseconds: 200),
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
      ),
    );
  }
}

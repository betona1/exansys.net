import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../reader/widgets/page_turn_zones.dart';

/// 읽기 화면을 처음 열었을 때 한 번 뜨는 안내.
///
/// **실제 자리 위에 겹쳐 보여 준다.** 글로만 "가장자리를 누르세요"라고
/// 적어 두면 어디가 가장자리인지 아무도 모른다. 화면을 세 칸으로 나눠
/// 그 자리에 그대로 표시한다.
///
/// 끄는 길을 같은 화면에 둔다 — 아는 사람에게 두 번 보여 주지 않는다.
class ReaderCoach extends StatelessWidget {
  const ReaderCoach({super.key, required this.onClose, required this.onNeverShow});

  /// 이번만 닫는다 (다음 책에서 또 볼 수 있다)
  final VoidCallback onClose;

  /// 앞으로 안내를 띄우지 않는다
  final VoidCallback onNeverShow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xE60D1117),
        child: LayoutBuilder(
          builder: (context, c) {
            final edge = PageTurnZones.edgeWidth(c.maxWidth);
            final narrow = c.maxWidth < AppTokens.breakpointMedium;
            return Stack(
              children: [
                // 화면을 실제 조작 구역대로 나눠 보여 준다
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: edge,
                  child: const _Zone(icon: Icons.chevron_left, label: '이전 쪽', sub: '눌러서'),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: edge,
                  child: const _Zone(icon: Icons.chevron_right, label: '다음 쪽', sub: '눌러서'),
                ),
                Positioned(
                  left: edge,
                  right: edge,
                  top: 0,
                  bottom: 0,
                  child: const _Zone(
                    icon: Icons.touch_app_outlined,
                    label: '메뉴 보이기·숨기기',
                    sub: '가운데를 눌러서',
                    dashed: true,
                  ),
                ),

                // 나머지 조작은 아래에 목록으로
                Positioned(
                  left: AppTokens.space4,
                  right: AppTokens.space4,
                  bottom: AppTokens.space4,
                  child: Material(
                    color: t.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.space4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('처음이시죠. 이것만 아시면 됩니다', style: t.textTheme.titleMedium),
                          const SizedBox(height: AppTokens.space3),
                          const _Line(
                            icon: Icons.swipe,
                            text: '좌우로 밀어도 쪽이 넘어갑니다',
                          ),
                          const _Line(
                            icon: Icons.zoom_in,
                            text: '두 번 두드리면 확대·원래대로. 손가락 두 개로 벌려도 됩니다',
                          ),
                          const _Line(
                            icon: Icons.pan_tool_outlined,
                            text: '확대한 뒤에는 끌어서 위아래·좌우로 옮깁니다',
                          ),
                          const _Line(
                            icon: Icons.lock_outline,
                            text: '자물쇠를 누르면 지금 크기와 좌우 위치가 고정됩니다',
                          ),
                          const _Line(
                            icon: Icons.vertical_split,
                            text: '한 장에 두 쪽인 책은 반 가르기로 한 쪽씩 봅니다',
                          ),
                          const SizedBox(height: AppTokens.space3),
                          if (narrow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(onPressed: onClose, child: const Text('알겠습니다')),
                                TextButton(
                                  onPressed: onNeverShow,
                                  child: const Text('앞으로 안내 보지 않기'),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                TextButton(
                                  onPressed: onNeverShow,
                                  child: const Text('앞으로 안내 보지 않기'),
                                ),
                                const Spacer(),
                                FilledButton(onPressed: onClose, child: const Text('알겠습니다')),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Zone extends StatelessWidget {
  const _Zone({
    required this.icon,
    required this.label,
    required this.sub,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final String sub;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: dashed ? 0.18 : 0.4),
          width: dashed ? 1 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(height: AppTokens.space2),
          Text(
            sub,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppTokens.space2),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

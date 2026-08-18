import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// 바브바브(비비) 마스코트 위젯 모음 (BRAND.md §2.5).
///
/// 앱 아이콘과 같은 원본에서 따낸 컷아웃을 쓴다 — 아이콘에서 본 캐릭터가
/// 앱 안(스플래시·빈 서재·오류)에서도 그대로 이어져 보이게 하기 위함이다.
/// 자산 생성은 `scripts/gen_mascot.py`.
abstract final class VaveAssets {
  static const full = 'assets/mascot/vave_full.png';
  static const face = 'assets/mascot/vave_face.png';
}

/// 시안 발광을 등에 진 바브바브 전신 — 스플래시·빈 서재의 히어로.
class VaveHero extends StatelessWidget {
  const VaveHero({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 발광이 캐릭터보다 한 뼘 크게 퍼지도록 여백을 준다
      padding: EdgeInsets.all(width * 0.14),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppTokens.vaveCyan.withValues(alpha: 0.20),
            AppTokens.vaveCyan.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Image.asset(
        VaveAssets.full,
        width: width,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// 앱바 구석에 앉는 작은 바브바브 — 미니 아이콘 모양.
///
/// 얼굴 컷아웃의 아래 절단면을 라운드 박스가 가리고, 네이비 그라디언트가
/// 흰 털을 배경에서 띄운다. 서재처럼 목록만 있는 화면에서도 캐릭터가 보인다.
class VaveBadge extends StatelessWidget {
  const VaveBadge({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.vaveNavyLo, AppTokens.vaveNavyHi],
        ),
      ),
      // 눈이 보여야 캐릭터다 — 머리털 위쪽을 잘라내고 눈가로 당겨 확대한다.
      // 절단면·넘친 부분은 라운드 박스가 잘라 낸다
      child: Transform.scale(
        scale: 1.5,
        child: Image.asset(
          VaveAssets.face,
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.55),
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// 오류·안내 화면 — 바브바브가 메시지 카드 위로 빼꼼 내다본다.
///
/// 아이콘(책 너머로 내다보는 구도)과 같은 문법이라 어디서 봐도 한 앱이다.
/// 얼굴 컷아웃의 아래 절단면은 카드가 가린다.
/// 오류는 "무엇이 실패 / 원인 / 다음 행동" 3요소를 갖춘다 (techspec §17).
class VaveErrorView extends StatelessWidget {
  const VaveErrorView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final border = t.brightness == Brightness.dark
        ? AppTokens.borderDark
        : AppTokens.borderLight;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 카드보다 먼저 그려서 카드가 절단면을 덮는다
              Transform.translate(
                offset: const Offset(0, 14),
                child: Image.asset(
                  VaveAssets.face,
                  width: 128,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.space5),
                decoration: BoxDecoration(
                  color: t.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: t.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppTokens.space2),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: t.textTheme.bodySmall,
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: AppTokens.space4),
                      FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// 보기 설정 시트 — 읽기와 상관없는 버튼을 도구막대에서 걷어 내고 한곳에 모은다.
///
/// techspec §1: **읽는 화면이 주인공이다. 모든 기능은 3단계 안에 (툴바 → 시트 → 실행).**
/// 도구막대에 토글이 여섯 개 늘어서 있으면 무엇이 무엇인지 알 수 없다.
class ViewSheet extends StatelessWidget {
  const ViewSheet({
    super.key,
    required this.splitOn,
    required this.cropOn,
    required this.darkOn,
    required this.onToggleSplit,
    required this.onCrop,
    required this.onTheme,
  });

  final bool splitOn;
  final bool cropOn;
  final bool darkOn;

  final VoidCallback onToggleSplit;
  final VoidCallback onCrop;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              AppTokens.space1,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('보기', style: t.textTheme.titleMedium),
            ),
          ),
          SwitchListTile(
            value: splitOn,
            onChanged: (_) {
              Navigator.pop(context);
              onToggleSplit();
            },
            secondary: const Icon(Icons.vertical_split),
            title: const Text('좌우 나눠 보기'),
            subtitle: const Text('한 장에 두 쪽이 들어 있는 스캔본을 반으로 갈라 봅니다'),
          ),
          ListTile(
            leading: Icon(Icons.crop, color: cropOn ? AppTokens.amber : null),
            title: const Text('여백 잘라내기'),
            subtitle: Text(cropOn ? '켜져 있음 · 눌러서 조정' : '가장자리 흰 여백을 걷어 내 글자를 키웁니다'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              onCrop();
            },
          ),
          ListTile(
            leading: Icon(Icons.contrast, color: darkOn ? AppTokens.amber : null),
            title: const Text('테마 · 밝기'),
            subtitle: Text(darkOn ? '다크 리딩 켜짐' : '라이트 / 다크 / 세피아, 밝기와 대비'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              onTheme();
            },
          ),
          const SizedBox(height: AppTokens.space2),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/tokens.dart';
import 'help_settings.dart';

/// 사용 설명서 (docs/MANUAL.md 와 같은 내용).
///
/// 문서를 따로 두면 아무도 읽지 않는다. **앱 안에 넣는다.**
/// 안내를 다시 켜고 끄는 자리도 여기다 — 껐다가 다시 보고 싶어졌을 때
/// 찾아갈 곳이 있어야 한다.
class ManualScreen extends ConsumerStatefulWidget {
  const ManualScreen({super.key});

  @override
  ConsumerState<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends ConsumerState<ManualScreen> {
  HelpSettings _help = const HelpSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await HelpSettings.load(ref.read(databaseProvider));
    if (mounted) setState(() => _help = h);
  }

  Future<void> _setTips(bool on) async {
    // 껐다 켜면 첫 안내도 다시 볼 수 있어야 한다. 안 그러면 켜도 아무 일이 없다
    final next = _help.copyWith(showTips: on, readerIntroSeen: on ? false : _help.readerIntroSeen);
    setState(() => _help = next);
    await next.save(ref.read(databaseProvider));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('사용 설명서')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          SwitchListTile(
            value: _help.showTips,
            onChanged: _setTips,
            title: const Text('안내 표시'),
            subtitle: const Text('처음 여는 화면에서 조작 안내를 보여 줍니다'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: AppTokens.space6),

          _Section(
            title: '책 넘기기',
            items: const [
              ('화면 좌·우 가장자리를 누르기', '가장 빠릅니다. 한 손으로 됩니다'),
              ('좌우로 밀기', '넘기던 느낌 그대로'),
              ('키보드', '스페이스·엔터·→·↓·PageDown 은 다음, ←·↑·PageUp 은 이전'),
              ('Home / End', '첫 쪽 / 마지막 쪽'),
              ('마우스 휠', '쪽 안에서 아래로 내려가다가, 끝에 닿으면 넘어갑니다'),
            ],
          ),

          _Section(
            title: '크게 보기·옮기기',
            items: const [
              ('두 번 두드리기', '확대 ↔ 원래대로'),
              ('손가락 두 개로 벌리기', '원하는 만큼 확대'),
              ('Ctrl + 휠', '컴퓨터에서 확대·축소'),
              ('끌기', '확대했거나 화면 밖으로 넘칠 때 위아래·좌우로 옮깁니다'),
              ('자물쇠 버튼', '지금 크기와 좌우 위치를 고정합니다. 쪽을 넘겨도 그대로'),
            ],
          ),

          _Section(
            title: '보기 맞추기',
            items: const [
              ('폭 맞춤', '좌우를 화면에 꽉. 글자가 가장 큽니다'),
              ('화면 맞춤', '쪽 전체가 한눈에 들어옵니다'),
              ('세로 맞춤', '위아래를 화면에 맞춥니다'),
              ('반 가르기', '한 장에 두 쪽이 스캔된 책을 한 쪽씩 봅니다'),
              ('여백 자르기', '스캔 여백을 잘라 내면 글자가 훨씬 커집니다'),
              ('다크 리딩', '밤에 눈이 덜 부십니다. 사진은 원래 색을 지킵니다'),
            ],
          ),

          _Section(
            title: '표시하고 남기기',
            items: const [
              ('칠하기', '색을 고르고 끌면 그 자리가 칠해집니다'),
              ('칠한 것 지우기', '눌러서 고른 뒤 휴지통. 컴퓨터에서는 Del 키'),
              ('북마크', '지금 쪽을 접어 둡니다'),
              ('내보내기', '칠한 곳과 북마크를 글 파일로 꺼냅니다'),
              ('쪽 이미지', '쪽을 JPG 로. 다섯 장 넘으면 zip 하나로 묶습니다'),
            ],
          ),

          _Section(
            title: '찾기',
            items: const [
              ('돋보기', '이 책 안에서 찾습니다'),
              ('한글 검색', '띄어쓰기가 달라도 찾습니다'),
              ('스캔본', '사진으로 된 책은 글자가 없어 찾을 수 없습니다. '
                  '돋보기를 누르면 글자로 바꾸기를 권해 드립니다'),
            ],
          ),

          _Section(
            title: '스캔본을 글자로 바꾸기 (OCR)',
            items: const [
              ('무엇인가', '사진뿐인 책에서 글자를 읽어 냅니다. 그때부터 찾기가 됩니다'),
              ('어디서 도는가', '서버에서 돕니다. 주소는 직접 넣습니다'),
              ('얼마나 걸리는가', '쪽마다 30초 안팎. 책 한 권이면 한두 시간입니다'),
              ('중간에 멈추면', '한 쪽씩 저장되므로 다음에 남은 쪽부터 이어서 합니다'),
            ],
          ),

          const SizedBox(height: AppTokens.space4),
          Text(
            '만든 곳 EXANSYS · 원본 PDF 는 절대 고치지 않습니다. '
            '칠한 것과 북마크는 앱 안에만 담깁니다.',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space6),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;

  /// (무엇을, 어떻게 되는지)
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: Text(title, style: t.textTheme.titleMedium),
        ),
        for (final (what, how) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: AppTokens.space2),
                  decoration: const BoxDecoration(
                    color: AppTokens.action,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(what, style: t.textTheme.bodyMedium),
                      Text(how, style: t.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppTokens.space4),
      ],
    );
  }
}

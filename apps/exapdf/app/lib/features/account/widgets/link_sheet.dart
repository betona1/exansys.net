import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/tokens.dart';
import '../account.dart';

/// 로그인 화면.
///
/// **버튼 하나**로 끝난다 — 누르면 브라우저가 열리고, 거기서 카카오·구글·
/// 깃허브·네이버·이메일 중 아무거나로 로그인하면 앱이 알아서 잡는다.
/// 사람이 옮겨 적을 것이 없다.
///
/// 앱 안에 소셜 버튼을 두지 않는 이유가 셋이다.
///  1. **앱이 비밀번호를 볼 일이 없다.** 로그인은 늘 진짜 브라우저에서만
///  2. 카카오·구글이 앱 내 웹뷰 로그인을 막는다 (정책 위반으로 차단된다)
///  3. 윈도우·웹에서도 똑같이 된다 — 플랫폼마다 SDK 를 붙이지 않아도 된다
///
/// 브라우저를 못 여는 곳을 위해 코드 방식을 보조로 남긴다.
class LinkSheet extends StatefulWidget {
  const LinkSheet({super.key, required this.service});

  final AccountService service;

  @override
  State<LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<LinkSheet> {
  LinkStart? _link;
  String? _error;
  Timer? _poll;
  int _left = 0;
  bool _opened = false;
  bool _showCode = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// 준비만 해 둔다. 브라우저는 사용자가 버튼을 눌러야 연다 —
  /// 열자마자 딴 앱으로 튀면 무슨 일이 일어난 건지 알 수 없다
  Future<void> _start() async {
    setState(() {
      _error = null;
      _link = null;
      _opened = false;
    });
    try {
      final link = await widget.service.startLink();
      if (!mounted) return;
      setState(() {
        _link = link;
        _left = 600;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _openBrowser() async {
    final link = _link;
    if (link == null) return;
    final url = widget.service.authorizeUrl(link.device);
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      // 브라우저를 못 열면 코드를 보여 준다. 막다른 길로 두지 않는다
      setState(() => _showCode = true);
      return;
    }
    setState(() => _opened = true);
    // 3초마다 확인한다. 더 자주 물으면 서버만 괴롭고 체감은 같다
    _poll = Timer.periodic(const Duration(seconds: 3), (t) => unawaited(_check(t)));
  }

  Future<void> _check(Timer t) async {
    final link = _link;
    if (link == null) return;
    setState(() => _left = (_left - 3).clamp(0, 600));
    if (_left == 0) {
      t.cancel();
      if (mounted) setState(() => _error = '시간이 지났습니다. 다시 눌러 주세요');
      return;
    }
    try {
      final account = await widget.service.pollLink(link.device);
      if (account == null || !mounted) return;
      t.cancel();
      Navigator.pop(context, account);
    } on Object catch (e) {
      t.cancel();
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final link = _link;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('로그인', style: t.textTheme.titleLarge),
            const SizedBox(height: AppTokens.space2),
            Text(
              '카카오 · 구글 · 깃허브 · 네이버 · 이메일 중 아무거나로 들어오실 수 있습니다.\n'
              '로그인은 브라우저에서 합니다 — 앱에는 비밀번호를 넣지 않습니다.',
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space4),

            if (_error != null) ...[
              Text(_error!, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.error)),
              const SizedBox(height: AppTokens.space3),
              FilledButton(onPressed: _start, child: const Text('다시 시도')),
            ] else if (link == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTokens.space5),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!_opened) ...[
              FilledButton.icon(
                onPressed: _openBrowser,
                icon: const Icon(Icons.login),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
                ),
                label: const Text('브라우저에서 로그인'),
              ),
              const SizedBox(height: AppTokens.space2),
              TextButton(
                onPressed: () => setState(() => _showCode = !_showCode),
                child: Text(_showCode ? '코드 숨기기' : '브라우저가 안 열리면'),
              ),
              if (_showCode) _CodeBox(code: link.code, service: widget.service),
            ] else ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppTokens.space3),
              Text('브라우저에서 로그인해 주세요.', style: t.textTheme.bodyMedium),
              Text(
                '끝나면 이 화면이 저절로 넘어갑니다 · 남은 시간 ${_left ~/ 60}분 ${_left % 60}초',
                style: t.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTokens.space2),
              TextButton(onPressed: _openBrowser, child: const Text('브라우저 다시 열기')),
            ],

            const SizedBox(height: AppTokens.space3),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 브라우저를 못 열 때 쓰는 보조 수단
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.service});

  final String code;
  final AccountService service;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '다른 기기의 브라우저에서 ${service.linkUrl(code).host}/exapdf/link 로 가서\n'
            '아래 코드를 넣어 주세요.',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space2),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
            decoration: BoxDecoration(
              color: t.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: Center(
              child: SelectableText(
                code,
                style: t.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: code)));
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(content: Text('코드를 복사했습니다')));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('코드 복사'),
          ),
        ],
      ),
    );
  }
}

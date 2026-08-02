import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/tokens.dart';
import '../account.dart';

/// 앱과 계정을 잇는 화면.
///
/// 코드를 보여 주고, 사용자가 브라우저에서 넣기를 기다린다.
/// **앱 안에 로그인 창을 띄우지 않는다** — 앱이 비밀번호를 볼 일이 없어야 한다.
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

  Future<void> _start() async {
    setState(() {
      _error = null;
      _link = null;
    });
    try {
      final link = await widget.service.startLink();
      if (!mounted) return;
      setState(() {
        _link = link;
        _left = 600;
      });
      // 3초마다 확인한다. 더 자주 물으면 서버만 괴롭고 체감은 같다
      _poll = Timer.periodic(const Duration(seconds: 3), (t) => unawaited(_check(t)));
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _check(Timer t) async {
    final link = _link;
    if (link == null) return;
    setState(() => _left = (_left - 3).clamp(0, 600));
    if (_left == 0) {
      t.cancel();
      if (mounted) setState(() => _error = '코드가 만료됐습니다. 새로 받아 주세요');
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
            Text('계정 연결', style: t.textTheme.titleLarge),
            const SizedBox(height: AppTokens.space2),
            Text(
              '아래 코드를 브라우저에서 넣으면 연결됩니다.\n'
              '앱에는 비밀번호를 넣지 않습니다.',
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space4),

            if (_error != null) ...[
              Text(_error!, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.error)),
              const SizedBox(height: AppTokens.space3),
              FilledButton(onPressed: _start, child: const Text('다시 받기')),
            ] else if (link == null)
              const Center(child: Padding(
                padding: EdgeInsets.all(AppTokens.space5),
                child: CircularProgressIndicator(),
              ))
            else ...[
              // 코드는 크게. 폰을 손에 들고 컴퓨터 화면에 옮겨 적는 상황이다
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                ),
                child: Center(
                  child: SelectableText(
                    link.code,
                    style: t.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.service.linkUrl(link.code).host} 에서 입력\n'
                      '남은 시간 ${_left ~/ 60}분 ${_left % 60}초',
                      style: t.textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      unawaited(Clipboard.setData(
                        ClipboardData(text: widget.service.linkUrl(link.code).toString()),
                      ));
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(const SnackBar(content: Text('주소를 복사했습니다')));
                    },
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('주소 복사'),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space2),
              const LinearProgressIndicator(),
              const SizedBox(height: AppTokens.space2),
              Text('연결을 기다리는 중…', style: t.textTheme.bodySmall),
            ],

            const SizedBox(height: AppTokens.space4),
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

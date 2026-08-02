import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/tokens.dart';
import '../account.dart';
import 'link_sheet.dart';

/// 서재 상단의 계정 단추.
///
/// **로그인은 눈에 보이는 자리에 있어야 한다.** 예전에는 스캔본에서
/// 돋보기를 눌러 유료 안내까지 가야만 로그인이 나왔다 — 거기까지 가는
/// 사람만 로그인할 수 있었다는 뜻이다.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider).valueOrNull;
    return IconButton(
      onPressed: () => unawaited(_open(context, ref, account)),
      tooltip: account == null ? '로그인' : '${account.name} · ${account.isPro ? "Pro" : "무료"}',
      icon: account == null
          ? const Icon(Icons.person_outline)
          : Badge(
              // Pro 면 점을 띄워 한눈에 알게 한다
              isLabelVisible: account.isPro,
              backgroundColor: AppTokens.action,
              child: _Avatar(account: account),
            ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Account? account) async {
    if (account == null) {
      final linked = await showModalBottomSheet<Account>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => LinkSheet(service: ref.read(accountServiceProvider)),
      );
      if (linked != null) ref.invalidate(accountProvider);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _AccountSheet(account: account, ref: ref),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final url = account.avatarUrl;
    if (url != null && url.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          url,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.person),
        ),
      );
    }
    return CircleAvatar(
      radius: 13,
      child: Text(
        account.name.isEmpty ? '?' : account.name.characters.first,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.account, required this.ref});

  final Account account;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: _Avatar(account: account),
            title: Text(account.name),
            subtitle: Text(
              account.isPro
                  ? 'Pro · 스캔본을 글자로 바꿀 수 있습니다'
                  : '무료 · 읽기 기능은 전부 쓸 수 있습니다',
            ),
            trailing: account.isPro
                ? Chip(
                    label: const Text('Pro'),
                    backgroundColor: AppTokens.action,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          if (!account.isPro)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Pro 로 무엇이 되나'),
              subtitle: const Text('스캔본을 글자로 (OCR) · 이미지에서 글자 뽑기'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('요금 안내는 exansys.net 에 있습니다')),
                  );
              },
            ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('상태 새로 고치기'),
            subtitle: const Text('요금제를 바꾼 직후에 눌러 주세요'),
            onTap: () {
              ref.invalidate(accountProvider);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(accountServiceProvider).logout();
              ref.invalidate(accountProvider);
            },
          ),
          const SizedBox(height: AppTokens.space3),
        ],
      ),
    );
  }
}

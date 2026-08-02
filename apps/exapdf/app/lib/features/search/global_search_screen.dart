import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/tokens.dart';
import '../../domain/entities/search_hit.dart';
import 'widgets/snippet_text.dart';

/// 라이브러리 전체 검색 (techspec §12).
///
/// 현재 문서가 아니라 **서재에 있는 모든 책**에서 찾는다. 조사가 붙어도,
/// 두 글자만 넣어도 걸려야 한다 (ADR-0003).
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _input = TextEditingController();
  Timer? _debounce;
  List<SearchHitGroup>? _groups;
  bool _searching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // 한 글자 칠 때마다 훑으면 큰 서재에서 버벅인다
    _debounce = Timer(const Duration(milliseconds: 350), () => unawaited(_run(value)));
    setState(() {});
  }

  Future<void> _run(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _groups = null;
        _lastQuery = '';
      });
      return;
    }
    setState(() => _searching = true);
    final result = await ref.read(searchRepositoryProvider).search(q);
    if (!mounted) return;
    setState(() {
      _groups = result;
      _lastQuery = q;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final indexing = ref.watch(indexProgressProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _input,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '서재 전체에서 찾기',
            border: InputBorder.none,
            suffixIcon: _input.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _input.clear();
                      _onChanged('');
                    },
                  ),
          ),
          onChanged: _onChanged,
          onSubmitted: (v) => unawaited(_run(v)),
        ),
      ),
      body: Column(
        children: [
          // 색인 중이면 결과가 더 늘어날 수 있다는 것을 알린다
          if (indexing != null)
            _IndexingBanner(done: indexing.done, total: indexing.total),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_groups == null) return const _SearchHint();
    if (_groups!.isEmpty) return _NoResult(query: _lastQuery);

    return ListView.builder(
      itemCount: _groups!.length,
      itemBuilder: (context, i) {
        final g = _groups![i];
        return _BookGroup(group: g);
      },
    );
  }
}

class _BookGroup extends StatelessWidget {
  const _BookGroup({required this.group});

  final SearchHitGroup group;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.menu_book, color: AppTokens.amber),
      title: Text(group.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text('${group.hits.length}건', style: Theme.of(context).textTheme.bodySmall),
      children: [
        for (final hit in group.hits)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: AppTokens.space7, right: AppTokens.space4),
            title: SnippetText(snippet: hit.snippet),
            subtitle: Text('p.${hit.pageNo}', style: Theme.of(context).textTheme.labelSmall),
            // 결과를 누르면 그 쪽으로 간다 (techspec §12)
            onTap: () => context.go(AppRoutes.bookPath(hit.bookId, page: hit.pageNo)),
          ),
      ],
    );
  }
}

class _IndexingBanner extends StatelessWidget {
  const _IndexingBanner({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (done / total * 100).round();
    return Container(
      width: double.infinity,
      color: AppTokens.slot,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      child: Text(
        '$percent% 색인 중 — 결과가 더 늘어날 수 있습니다',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Text(
          '서재에 있는 모든 책에서 찾습니다.\n조사가 붙어도, 두 글자만 넣어도 걸립니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('"$query" 을(를) 찾지 못했습니다', style: t.textTheme.titleMedium),
            const SizedBox(height: AppTokens.space2),
            Text(
              '아직 색인되지 않은 책은 검색되지 않습니다.\n책을 한 번 열면 색인이 만들어집니다.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

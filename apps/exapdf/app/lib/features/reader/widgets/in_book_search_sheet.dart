import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/tokens.dart';
import '../../../domain/entities/search_hit.dart';
import '../../search/widgets/snippet_text.dart';

/// 이 책 안에서 찾기 (techspec §11).
///
/// 예전에는 pdfrx 의 `PdfTextSearcher` 를 썼다. 그것은 `PdfViewer` 에 매여 있어
/// 뷰어를 직접 그리는 방식으로 바꾸면서 쓸 수 없게 됐다.
/// 대신 **이미 만들어 둔 색인**에서 찾는다 — 조사가 붙어도, 두 글자만 넣어도
/// 걸리므로 오히려 결과가 낫다 (ADR-0003).
///
/// 대가: 본문 위에 노란 하이라이트를 칠하지 못한다. 결과 목록에서 쪽으로 이동한다.
class InBookSearchSheet extends ConsumerStatefulWidget {
  const InBookSearchSheet({
    super.key,
    required this.bookId,
    required this.onClose,
    required this.onGoToPage,
  });

  final int bookId;
  final VoidCallback onClose;
  final ValueChanged<int> onGoToPage;

  @override
  ConsumerState<InBookSearchSheet> createState() => _InBookSearchSheetState();
}

class _InBookSearchSheetState extends ConsumerState<InBookSearchSheet> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<SearchHit> _hits = const [];
  bool _searching = false;
  String _lastQuery = '';

  /// 지금 몇 번째 결과를 보고 있는가 (0부터). 위·아래 화살표가 이걸 옮긴다
  int _at = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => unawaited(_run(v)));
    setState(() {});
  }

  Future<void> _run(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _hits = const [];
        _lastQuery = '';
      });
      return;
    }
    setState(() => _searching = true);
    final groups = await ref
        .read(searchRepositoryProvider)
        .search(q, bookId: widget.bookId);
    if (!mounted) return;
    final hits = groups.isEmpty ? const <SearchHit>[] : groups.first.hits;
    setState(() {
      _hits = hits;
      _lastQuery = q;
      _searching = false;
      _at = 0;
    });

    // **찾았는지 못 찾았는지를 말로 알려 준다.** 목록만 바뀌면 눈치채기 어렵다
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (hits.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('"\$q" 을(를) 찾지 못했습니다'), duration: const Duration(seconds: 2)),
      );
      return;
    }
    // 하나뿐이면 묻지 않고 바로 간다. 두 번 누르게 할 이유가 없다
    if (hits.length == 1) {
      messenger.showSnackBar(
        SnackBar(content: Text('\${hits.first.pageNo}쪽에서 찾았습니다'), duration: const Duration(seconds: 2)),
      );
      widget.onGoToPage(hits.first.pageNo);
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('\${hits.length}곳에서 찾았습니다 · 첫 곳은 \${hits.first.pageNo}쪽'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '이동',
          onPressed: () => widget.onGoToPage(hits.first.pageNo),
        ),
      ),
    );
  }

  /// 다음·이전 결과로. 끝에 닿으면 처음으로 돌아온다 —
  /// 막다른 길에서 아무 반응이 없으면 고장으로 보인다
  void _step(int delta) {
    if (_hits.isEmpty) return;
    final next = (_at + delta) % _hits.length;
    setState(() => _at = next < 0 ? next + _hits.length : next);
    final hit = _hits[_at];
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('\${_at + 1} / \${_hits.length}번째 · \${hit.pageNo}쪽'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    widget.onGoToPage(hit.pageNo);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space3,
            0,
            AppTokens.space1,
            AppTokens.space1,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '이 책에서 찾기',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _input.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
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
              // 여러 곳에서 찾았으면 위·아래로 옮겨 다닌다
              if (_hits.length > 1) ...[
                IconButton(
                  onPressed: () => _step(-1),
                  icon: const Icon(Icons.keyboard_arrow_up),
                  tooltip: '이전 결과',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: () => _step(1),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: '다음 결과',
                  visualDensity: VisualDensity.compact,
                ),
              ],
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
                tooltip: '닫기',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (_searching) const LinearProgressIndicator(minHeight: 2),
        if (_lastQuery.isNotEmpty && !_searching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _hits.isEmpty ? '찾은 곳이 없습니다' : '${_hits.length}곳',
                style: t.textTheme.labelSmall,
              ),
            ),
          ),
        if (_hits.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.34),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _hits.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final hit = _hits[i];
                return ListTile(
                  dense: true,
                  selected: i == _at,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTokens.slot,
                    child: Text('${hit.pageNo}', style: t.textTheme.labelSmall),
                  ),
                  title: SnippetText(snippet: hit.snippet),
                  onTap: () {
                    setState(() => _at = i);
                    widget.onGoToPage(hit.pageNo);
                  },
                );
              },
            ),
          ),
        const SizedBox(height: AppTokens.space1),
      ],
    );
  }
}

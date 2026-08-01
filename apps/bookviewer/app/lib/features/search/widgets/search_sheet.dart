import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/tokens.dart';

/// 문서 전체 검색 패널.
///
/// pdfrx 의 [PdfTextSearcher] 가 쪽을 훑으며 결과를 채우고, 본문 하이라이트는
/// `pagePaintCallbacks` 로 뷰어가 직접 그린다. 여기서는 목록과 이동만 맡는다.
class SearchSheet extends StatefulWidget {
  const SearchSheet({super.key, required this.searcher, required this.onClose});

  final PdfTextSearcher searcher;
  final VoidCallback onClose;

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.searcher.addListener(_onSearcherChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    widget.searcher.removeListener(_onSearcherChanged);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearcherChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.searcher;
    final matches = s.matches;
    return Material(
      color: AppTokens.slot,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: '이 책에서 찾기',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _input.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _input.clear();
                                  s.resetTextSearch();
                                  setState(() {});
                                },
                              ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        s.startTextSearch(v);
                        setState(() {}); // 지우기 버튼 표시용
                      },
                      onSubmitted: (v) => s.startTextSearch(v, searchImmediately: true),
                    ),
                  ),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close), tooltip: '닫기'),
                ],
              ),
            ),
            _StatusLine(searcher: s, query: _input.text),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.32),
              child: matches.isEmpty
                  ? const SizedBox(height: 8)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final m = matches[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: i == s.currentIndex
                                ? AppTokens.action
                                : AppTokens.borderDark,
                            child: Text(
                              '${m.pageNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                color: i == s.currentIndex ? Colors.black : Colors.white70,
                              ),
                            ),
                          ),
                          title: Text.rich(
                            _snippet(m),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => s.goToMatch(m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 결과 한 줄 — 찾은 낱말 앞뒤를 조금 붙여 어디인지 알아보게 한다.
  TextSpan _snippet(PdfPageTextRange m, {int around = 28}) {
    final text = m.pageText.fullText.replaceAll('\n', ' ');
    final start = m.start.clamp(0, text.length);
    final end = m.end.clamp(start, text.length);
    final from = (start - around).clamp(0, text.length);
    final to = (end + around).clamp(end, text.length);
    return TextSpan(
      children: [
        if (from > 0) const TextSpan(text: '… '),
        TextSpan(text: text.substring(from, start)),
        TextSpan(
          text: text.substring(start, end),
          style: const TextStyle(
            color: AppTokens.action,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: text.substring(end, to)),
        if (to < text.length) const TextSpan(text: ' …'),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.searcher, required this.query});

  final PdfTextSearcher searcher;

  /// 입력칸의 현재 낱말. 비어 있으면 "찾은 곳이 없습니다" 를 띄우지 않는다.
  final String query;

  @override
  Widget build(BuildContext context) {
    final total = searcher.matches.length;
    final idx = searcher.currentIndex;
    final label = searcher.isSearching
        ? '찾는 중…'
        : total == 0
        ? (query.isEmpty ? '' : '찾은 곳이 없습니다')
        : '${idx == null ? 1 : idx + 1} / $total';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
      child: Row(
        children: [
          if (searcher.isSearching)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (searcher.isSearching) const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: total == 0 ? null : searcher.goToPrevMatch,
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: '이전 결과',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: total == 0 ? null : searcher.goToNextMatch,
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: '다음 결과',
          ),
        ],
      ),
    );
  }
}

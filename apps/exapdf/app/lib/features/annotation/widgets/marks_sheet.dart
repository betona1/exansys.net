import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/annotation.dart';

/// 하이라이트·북마크 모아 보기 (techspec §13 책갈피 화면).
///
/// 표시해 둔 것을 다시 찾지 못하면 표시할 이유가 없다.
class MarksSheet extends StatelessWidget {
  const MarksSheet({
    super.key,
    required this.highlights,
    required this.bookmarks,
    required this.onGoToPage,
    required this.onDeleteHighlight,
    required this.onDeleteBookmark,
    required this.onEditNote,
    required this.onExport,
  });

  final List<Highlight> highlights;
  final List<BookmarkEntry> bookmarks;
  final ValueChanged<int> onGoToPage;
  final ValueChanged<Highlight> onDeleteHighlight;
  final ValueChanged<BookmarkEntry> onDeleteBookmark;
  final ValueChanged<Highlight> onEditNote;

  /// 밖으로 꺼내기. 쌓아 두기만 하고 못 꺼내면 락인이다 (ADR-0002)
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space2,
                AppTokens.space2,
                0,
              ),
              child: Row(
                children: [
                  Text('표시해 둔 것', style: t.textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: (highlights.isEmpty && bookmarks.isEmpty) ? null : onExport,
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('내보내기'),
                  ),
                ],
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: '하이라이트 ${highlights.length}'),
                Tab(text: '북마크 ${bookmarks.length}'),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: TabBarView(
                children: [
                  if (highlights.isEmpty)
                    _Empty(
                      text: '아직 칠한 곳이 없습니다.\n도구막대의 형광펜으로 표시해 보세요.',
                    )
                  else
                    ListView.separated(
                      itemCount: highlights.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final h = highlights[i];
                        return ListTile(
                          leading: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTokens.highlights[h.colorSlot - 1],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          title: Text(
                            h.note?.isNotEmpty ?? false
                                ? h.note!
                                : AppTokens.highlightLabels[h.colorSlot - 1],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('p.${h.pageNo}', style: t.textTheme.labelSmall),
                          onTap: () {
                            Navigator.pop(context);
                            onGoToPage(h.pageNo);
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'note') onEditNote(h);
                              if (v == 'delete') onDeleteHighlight(h);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'note', child: Text('메모 편집')),
                              PopupMenuItem(value: 'delete', child: Text('삭제')),
                            ],
                          ),
                        );
                      },
                    ),
                  if (bookmarks.isEmpty)
                    _Empty(text: '아직 북마크가 없습니다.\n도구막대의 책갈피로 이 쪽을 표시해 보세요.')
                  else
                    ListView.separated(
                      itemCount: bookmarks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final b = bookmarks[i];
                        return ListTile(
                          leading: const Icon(Icons.bookmark, color: AppTokens.vaveBlue),
                          title: Text(b.label ?? '${b.pageNo}쪽'),
                          onTap: () {
                            Navigator.pop(context);
                            onGoToPage(b.pageNo);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: '삭제',
                            onPressed: () => onDeleteBookmark(b),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

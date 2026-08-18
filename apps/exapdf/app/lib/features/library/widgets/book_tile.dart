import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/book.dart';

/// 서재의 책 한 줄.
///
/// **제목과 파일명을 함께 보여준다.** 하나만 보이는 것이 실사용 불만이다 (techspec §13).
class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book, required this.onTap, required this.onRemove});

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final percent = (book.progress * 100).round();

    return ListTile(
      leading: _Cover(book: book),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.labelSmall),
          const SizedBox(height: AppTokens.space1),
          Row(
            children: [
              if (book.fileMissing) ...[
                Icon(Icons.warning_amber, size: 14, color: t.colorScheme.error),
                const SizedBox(width: 4),
                Text('파일 없음', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.error)),
              ] else
                Text(
                  book.pageCount > 0 ? '$percent% · ${book.farthestPage}/${book.pageCount}쪽' : '아직 열어보지 않음',
                  style: t.textTheme.bodySmall,
                ),
            ],
          ),
          if (book.progress > 0) ...[
            const SizedBox(height: AppTokens.space1),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: book.progress,
                minHeight: 3,
                backgroundColor: t.dividerColor,
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close),
        tooltip: '서재에서 빼기',
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    // 표지 자동 생성(1페이지 렌더)은 M2. 지금은 자리만 잡아 둔다
    return Container(
      width: 44,
      height: 58,
      decoration: BoxDecoration(
        color: AppTokens.slot,
        borderRadius: BorderRadius.circular(AppTokens.radiusButton * 0.6),
      ),
      alignment: Alignment.center,
      child: Icon(
        book.fileMissing ? Icons.link_off : Icons.menu_book,
        size: 20,
        // 표지 자리의 브랜드 액센트 — 누르는 요소가 아니므로 앰버를 써도 된다 (BRAND.md §3.2)
        color: book.fileMissing ? Theme.of(context).colorScheme.error : AppTokens.vaveBlue,
      ),
    );
  }
}

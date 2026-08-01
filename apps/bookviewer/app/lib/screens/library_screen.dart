import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/book_entry.dart';
import '../services/library_store.dart';
import '../theme.dart';
import 'reader_screen.dart';

/// 책장 — 최근 읽은 책과 "PDF 열기".
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _store = LibraryStore();
  List<BookEntry>? _books; // null = 아직 읽는 중
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await _store.load();
    if (mounted) setState(() => _books = items);
  }

  Future<void> _pickAndOpen() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) return; // 사용자가 취소함 — 조용히 돌아간다
      final entry = await _store.touch(path);
      if (!mounted) return;
      await _open(entry);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _open(BookEntry book) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: book)),
    );
    await _reload(); // 읽던 자리·쪽 수가 바뀌었을 수 있다
  }

  Future<void> _confirmRemove(BookEntry book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('책장에서 빼기'),
        content: Text('"${book.title}" 을(를) 책장에서 뺍니다.\nPDF 파일 자체는 지우지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('빼기')),
        ],
      ),
    );
    if (ok == true) {
      await _store.remove(book.path);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = _books;
    return Scaffold(
      appBar: AppBar(
        title: const Text('북뷰'),
        actions: [
          IconButton(
            onPressed: _picking ? null : _pickAndOpen,
            icon: const Icon(Icons.add),
            tooltip: 'PDF 열기',
          ),
        ],
      ),
      body: books == null
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
          ? _EmptyLibrary(onPick: _picking ? null : _pickAndOpen)
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: books.length,
                separatorBuilder: (_, _) => const Divider(indent: 72),
                itemBuilder: (_, i) => _BookTile(
                  book: books[i],
                  onTap: () => _open(books[i]),
                  onRemove: () => _confirmRemove(books[i]),
                ),
              ),
            ),
      floatingActionButton: books != null && books.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _picking ? null : _pickAndOpen,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF 열기'),
            )
          : null,
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.onTap, required this.onRemove});

  final BookEntry book;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = book.pageCount > 0
        ? '${book.lastPage} / ${book.pageCount}쪽 · ${(book.progress * 100).round()}%'
        : '아직 열어보지 않음';
    return ListTile(
      leading: Container(
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          color: BookViewerColors.line,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.menu_book, color: BookViewerColors.cyan),
      ),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          if (book.progress > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: book.progress,
                minHeight: 3,
                backgroundColor: BookViewerColors.line,
              ),
            ),
          ],
        ],
      ),
      isThreeLine: book.progress > 0,
      onTap: onTap,
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close),
        tooltip: '책장에서 빼기',
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onPick});

  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/icon.png', width: 112, height: 112),
            const SizedBox(height: 20),
            const Text(
              '읽을 책을 골라 주세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF 를 고르면 책처럼 넘겨 읽고, 문장을 찾고,\n중요한 부분은 복사하거나 잘라 둘 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF 열기'),
            ),
          ],
        ),
      ),
    );
  }
}

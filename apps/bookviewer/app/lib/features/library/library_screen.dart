import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/tokens.dart';
import '../../domain/entities/book.dart';
import 'widgets/book_tile.dart';
import 'widgets/empty_library.dart';

/// 서재 (techspec §13).
///
/// 지금은 리스트 한 종류다. 표지 그리드·컬렉션·정렬은 M2 에서 얹는다.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _picking = false;

  Future<void> _pickAndOpen() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) return; // 취소 — 조용히 돌아간다
      final book = await ref.read(libraryRepositoryProvider).addBook(path);
      if (!mounted) return;
      context.go(AppRoutes.bookPath(book.id));
    } on Object catch (e) {
      if (!mounted) return;
      // 조용히 실패하지 않는다 (techspec §17)
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('열지 못했습니다 — $e')));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _confirmRemove(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서재에서 빼기'),
        content: Text('"${book.title}" 을(를) 서재에서 뺍니다.\nPDF 파일 자체는 지우지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('빼기')),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(libraryRepositoryProvider).removeBook(book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 서재'),
        actions: [
          IconButton(
            onPressed: _picking ? null : _pickAndOpen,
            icon: const Icon(Icons.add),
            tooltip: 'PDF 가져오기',
          ),
        ],
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _LoadError(message: '$e'),
        data: (list) => list.isEmpty
            ? EmptyLibrary(onPick: _picking ? null : _pickAndOpen)
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(indent: 76),
                itemBuilder: (_, i) => BookTile(
                  book: list[i],
                  onTap: () => context.go(AppRoutes.bookPath(list[i].id)),
                  onRemove: () => _confirmRemove(list[i]),
                ),
              ),
      ),
      floatingActionButton: books.valueOrNull?.isNotEmpty ?? false
          ? FloatingActionButton.extended(
              onPressed: _picking ? null : _pickAndOpen,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF 가져오기'),
            )
          : null,
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // 오류는 "무엇이 실패 / 원인 / 다음 행동" 3요소를 갖춘다 (techspec §17)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('서재를 읽지 못했습니다', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTokens.space2),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

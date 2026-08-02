import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/help/manual_screen.dart';
import '../features/library/library_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/search/global_search_screen.dart';

/// 라우팅 — `Navigator.push` 대신 go_router 를 쓴다 (CLAUDE.md §5).
///
/// 딥링크 `bookviewer://book/{id}/page/{n}?anno={uuid}` 를 여기서 받는다.
/// Obsidian 으로 내보낸 노트가 원문으로 돌아오는 경로다 (ADR-0002).
abstract final class AppRoutes {
  static const library = '/';
  static const book = '/book/:id';
  static const search = '/search';
  static const manual = '/help';

  static String bookPath(int id, {int? page}) =>
      page == null ? '/book/$id' : '/book/$id?page=$page';
}

/// 개발용 — 서재를 거치지 않고 바로 그 책을 연다.
///   flutter run -d windows --release --dart-define=openBookId=1
const _devOpenBookId = int.fromEnvironment('openBookId');

final appRouter = GoRouter(
  initialLocation: _devOpenBookId > 0 ? '/book/$_devOpenBookId' : AppRoutes.library,
  routes: [
    GoRoute(
      path: AppRoutes.library,
      builder: (_, _) => const LibraryScreen(),
      routes: [
        GoRoute(
          path: 'search',
          builder: (_, _) => const GlobalSearchScreen(),
        ),
        GoRoute(
          path: 'help',
          builder: (_, _) => const ManualScreen(),
        ),
        GoRoute(
          path: 'book/:id',
          builder: (_, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return const _BadLink();
            // 딥링크로 특정 쪽을 지정할 수 있다. 없으면 읽던 자리로 간다
            final page = int.tryParse(state.uri.queryParameters['page'] ?? '');
            return ReaderScreen(bookId: id, jumpToPage: page);
          },
          routes: [
            // 내보낸 노트가 돌아오는 길 — ADR-0002 가 정한 형식
            //   bookviewer://book/{id}/page/{n}?anno={uuid}
            GoRoute(
              path: 'page/:page',
              builder: (_, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                final page = int.tryParse(state.pathParameters['page'] ?? '');
                if (id == null) return const _BadLink();
                return ReaderScreen(bookId: id, jumpToPage: page);
              },
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (_, _) => const _BadLink(),
);

class _BadLink extends StatelessWidget {
  const _BadLink();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('열 수 없는 주소입니다'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AppRoutes.library),
              child: const Text('서재로'),
            ),
          ],
        ),
      ),
    );
  }
}

// BookViewer(북뷰) — PDF 를 "문서"가 아니라 책으로 읽는 앱.
//
// 규칙은 `apps/bookviewer/CLAUDE.md`, 무엇을 만드는지는 `docs/SPEC.md`,
// 화면·버튼은 `docs/techspec.md`, 색·캐릭터는 `BRAND.md` 를 따른다.
// pdfrx 를 다룰 때의 함정은 `docs/engine-verification.md` 에 있다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  runApp(const ProviderScope(child: BookViewerApp()));
}

class BookViewerApp extends StatelessWidget {
  const BookViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '북뷰',
      // 다크 우선 설계다 (BRAND.md §5)
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}

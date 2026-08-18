// ExaPDF(ExaPDF) — PDF 를 "문서"가 아니라 책으로 읽는 앱.
//
// 규칙은 `apps/exapdf/CLAUDE.md`, 무엇을 만드는지는 `docs/SPEC.md`,
// 화면·버튼은 `docs/techspec.md`, 색·캐릭터는 `BRAND.md` 를 따른다.
// pdfrx 를 다룰 때의 함정은 `docs/engine-verification.md` 에 있다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'ui/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  runApp(const ProviderScope(child: ExaPDFApp()));
}

class ExaPDFApp extends StatelessWidget {
  const ExaPDFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ExaPDF',
      // 다크 우선 설계다 (BRAND.md §5)
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      // 시작 시 바브바브 히어로 페이지 약 3초 — 뒤에서 첫 화면이 미리 그려진다
      builder: (_, child) => SplashGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

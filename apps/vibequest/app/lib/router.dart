import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'learning/session_controller.dart';
import 'screens/glossary_screen.dart';
import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/quiz_screen.dart';

SessionMode _modeFrom(String? s) => switch (s) {
      'review' => SessionMode.quickReview,
      'new' => SessionMode.newExplore,
      'wrong' => SessionMode.wrongFix,
      _ => SessionMode.dailyMission,
    };

/// 하단 탭 4개: 홈 / 학습 / 용어도감 / 내 기록 (TECHSPEC §6.1)
final router = GoRouter(
  initialLocation: '/intro',
  routes: [
    // 인트로 — 비비가 바이브코딩하며 콘텐츠 로딩
    GoRoute(path: '/intro', builder: (c, s) => const IntroScreen()),
    // 문제 화면은 전체화면 (하단 탭 없음)
    GoRoute(
      path: '/quiz',
      builder: (c, s) => QuizScreen(mode: _modeFrom(s.uri.queryParameters['mode'])),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/learn', builder: (c, s) => const LearnScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/glossary', builder: (c, s) => const GlossaryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/me', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _Shell({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: '학습'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '용어도감'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '내 기록'),
        ],
      ),
    );
  }
}

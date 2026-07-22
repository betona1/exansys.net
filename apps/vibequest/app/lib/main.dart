import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'sfx.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Sfx.init(); // 효과음 미리 로드
  runApp(const ProviderScope(child: VibeQuestApp()));
}

class VibeQuestApp extends StatelessWidget {
  const VibeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VibeQuest',
      debugShowCheckedModeBanner: false,
      theme: vibeQuestTheme(),
      routerConfig: router,
    );
  }
}

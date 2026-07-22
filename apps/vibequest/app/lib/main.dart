import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

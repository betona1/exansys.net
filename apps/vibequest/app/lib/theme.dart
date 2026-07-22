import 'package:flutter/material.dart';

// EXANSYS 브랜드 (TECHSPEC A-6)
const vqGreen = Color(0xFF0E5741);
const vqGreenDeep = Color(0xFF093C2D);
const vqLime = Color(0xFF9BE15D);
const vqInk = Color(0xFF12141C);
const vqPaper = Color(0xFFF6F7FA);
const vqCard = Colors.white;

// 상태 색 (색+아이콘+텍스트 병행 — UX-05)
const vqCorrect = Color(0xFF1B8A5A);
const vqWrong = Color(0xFFD64545);
const vqGem = Color(0xFF3B82F6);

ThemeData vibeQuestTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: vqGreen,
    primary: vqGreen,
    surface: vqPaper,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: vqPaper,
    fontFamilyFallback: const ['Pretendard', 'Apple SD Gothic Neo', 'Malgun Gothic'],
    appBarTheme: const AppBarTheme(
      backgroundColor: vqPaper,
      foregroundColor: vqInk,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: vqInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: vqCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE7EAF0)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vqGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56), // 터치 영역 §12.3
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: vqCard,
      indicatorColor: vqLime.withValues(alpha: 0.35),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

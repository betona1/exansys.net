import 'package:flutter/material.dart';

/// 북뷰 색 — 사이트 브랜드(딥네이비 + 시안)를 따른다.
class BookViewerColors {
  static const navy = Color(0xFF0D1117);
  static const card = Color(0xFF151B24);
  static const line = Color(0xFF1F2A38);
  static const cyan = Color(0xFF22B8FF);
  static const paper = Color(0xFFF6F8FC);
}

/// 읽기 화면의 배경. 본문(흰 종이)이 도드라지도록 어둡게 둔다.
ThemeData bookViewerTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BookViewerColors.cyan,
    brightness: Brightness.dark,
  ).copyWith(surface: BookViewerColors.navy);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: BookViewerColors.navy,
    appBarTheme: const AppBarTheme(
      backgroundColor: BookViewerColors.card,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: BookViewerColors.card,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(iconColor: BookViewerColors.cyan),
    dividerTheme: const DividerThemeData(color: BookViewerColors.line, space: 1),
  );
}

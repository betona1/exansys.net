import 'package:flutter/material.dart';

import 'tokens.dart';

/// 앱 테마. 값은 전부 [AppTokens] 에서 가져온다.
///
/// 다크 우선 설계다 — 그림자 대신 표면 밝기 차이로 층을 표현한다 (BRAND.md §5).
abstract final class AppTheme {
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    background: AppTokens.ink,
    surface: AppTokens.surfaceDark,
    textPrimary: AppTokens.textPrimaryDark,
    textSecondary: AppTokens.textSecondaryDark,
    border: AppTokens.borderDark,
    danger: AppTokens.dangerDark,
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    background: AppTokens.paper,
    surface: AppTokens.surfaceLight,
    textPrimary: AppTokens.textPrimaryLight,
    textSecondary: AppTokens.textSecondaryLight,
    border: AppTokens.borderLight,
    danger: AppTokens.dangerLight,
  );

  static ThemeData sepia() => _build(
    brightness: Brightness.light,
    background: AppTokens.sepiaSurface,
    surface: const Color(0xFFFBF6EA),
    textPrimary: AppTokens.sepiaText,
    textSecondary: const Color(0xFF6B5A44),
    border: const Color(0xFFE0D4BC),
    danger: AppTokens.dangerLight,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
    required Color danger,
  }) {
    // 누르는 것은 전부 action. 앰버는 브랜드 표현 전용이라 여기 들어오지 않는다
    // (BRAND.md §3.2 — 흰 배경 대비 1.8:1 로 WCAG 미달)
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppTokens.action,
      onPrimary: Colors.white,
      secondary: AppTokens.action,
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        // 포커스 링은 action 2px. 절대 제거하지 않는다 (techspec §19)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          borderSide: const BorderSide(color: AppTokens.action, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        minVerticalPadding: AppTokens.space2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
      ),
    );
  }

  /// 한글 조판 — 행간을 라틴보다 넓게 (BRAND.md §4)
  static TextTheme _textTheme(Color primary, Color secondary) {
    TextStyle body(double size, {FontWeight weight = FontWeight.w400}) =>
        TextStyle(fontSize: size, height: AppTokens.bodyHeight, fontWeight: weight, color: primary);

    return TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.22),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: body(15),
      bodyMedium: body(15),
      bodySmall: TextStyle(fontSize: 13, height: AppTokens.bodyHeight, color: secondary),
      labelSmall: TextStyle(fontSize: 11, color: secondary),
    );
  }
}

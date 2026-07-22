import 'package:flutter/material.dart';

// ─── Vibe Quest 디자인 킷 v1 (design/Vibe Quest.dc.html) ───
// 퍼플 주조 + 민트/코랄 포인트, Jua(제목)·Gothic A1(본문), 듀오링고식 3D 버튼
const vqPurple = Color(0xFF5B3DF5);
const vqPurpleDark = Color(0xFF3A22C9);
const vqPurpleLight = Color(0xFF7B5CFF);
const vqMint = Color(0xFF12D8A0);
const vqMintDark = Color(0xFF0FB88A);
const vqCoral = Color(0xFFFF5B6E);
const vqYellowBg = Color(0xFFFFF6DF);
const vqYellowText = Color(0xFFB98A00);
const vqInk = Color(0xFF1C1740);
const vqBg = Color(0xFFF6F4FF);
const vqCard = Colors.white;
const vqBorder = Color(0xFFE7E2FF);
const vqLavender = Color(0xFFEDE8FF);
const vqMutedText = Color(0xFF6E6A8F);
const vqMuted2 = Color(0xFF9A95B8);

// 하위 호환 별칭 (기존 화면 코드가 사용)
const vqGreen = vqPurple;
const vqGreenDeep = vqPurpleDark;
const vqLime = Color(0xFFC9BEFF);
const vqPaper = vqBg;
const vqCorrect = vqMintDark;
const vqWrong = vqCoral;
const vqGem = vqPurple;

/// 제목·숫자용 Jua 스타일
TextStyle jua(double size, {Color color = vqInk, double? height}) => TextStyle(
      fontFamily: 'Jua',
      fontSize: size,
      color: color,
      height: height,
    );

ThemeData vibeQuestTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: vqPurple,
    primary: vqPurple,
    surface: vqBg,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: vqBg,
    fontFamily: 'GothicA1',
    appBarTheme: AppBarTheme(
      backgroundColor: vqBg,
      foregroundColor: vqInk,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: jua(24),
    ),
    cardTheme: CardThemeData(
      color: vqCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: vqBorder, width: 1.5),
      ),
      shadowColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vqPurple,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
            fontFamily: 'GothicA1', fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: vqPurple,
        backgroundColor: vqLavender,
        side: BorderSide.none,
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
            fontFamily: 'GothicA1', fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: vqCard,
      indicatorColor: vqLavender,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? vqPurple : vqMuted2)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected) ? vqPurple : vqMuted2,
          )),
    ),
  );
}

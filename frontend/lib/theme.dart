import 'package:flutter/material.dart';

/// Navy + gold "legal luxury" palette (see redesign spec).
class AppColors {
  static const navy900 = Color(0xFF042C53); // scaffold background
  static const navy700 = Color(0xFF0C447C); // cards / surfaces
  static const navy500 = Color(0xFF185FA5); // borders / dividers
  static const gold = Color(0xFFEF9F27); // primary accent / CTAs
  static const goldLight = Color(0xFFFAC775); // highlighted fills
  static const goldDark = Color(0xFF412402); // text on gold
  static const goldMid = Color(0xFF854F0B); // secondary text on gold
  static const textLight = Color(0xFFE6F1FB); // primary text on navy
  static const textMuted = Color(0xFFB5D4F4); // secondary text on navy
  static const textFaint = Color(0xFF85B7EB); // hints on navy
  static const reading = Color(0xFFE6F1FB); // light reading surface
  static const success = Color(0xFF5DCAA5);
  static const danger = Color(0xFFF09595);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: AppColors.goldDark,
    secondary: AppColors.goldLight,
    onSecondary: AppColors.goldDark,
    surface: AppColors.navy700,
    onSurface: AppColors.textLight,
    error: AppColors.danger,
    onError: AppColors.navy900,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.navy900,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy900,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.navy700,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldLight,
        side: const BorderSide(color: AppColors.navy500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.navy700,
      hintStyle: const TextStyle(color: AppColors.textFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy500),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.navy700,
      contentTextStyle: TextStyle(color: AppColors.textLight),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.gold),
    dividerColor: AppColors.navy500,
  );
}

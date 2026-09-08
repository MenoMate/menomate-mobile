import 'package:flutter/material.dart';

class MenoMateTheme {
  // --- Sakura Pink (Light Theme) Palette ---
  static const Color sakuraBg = Color(0xFFFFF9FB);
  static const Color sakuraSurface = Color(0xFFFFFFFF);
  static const Color sakuraPrimary = Color(0xFFE88FA8);
  static const Color sakuraPrimaryDark = Color(0xFFC96883);
  static const Color sakuraText = Color(0xFF302A2D);
  static const Color sakuraSecondary = Color(0xFF756B70);
  static const Color sakuraBorder = Color(0xFFF1DDE3);
  static const Color sakuraSoftPink = Color(0xFFFCE8EE);

  // --- Starry Night (Dark Theme) Palette ---
  static const Color starryBg = Color(0xFF080D1F);
  static const Color starrySurface = Color(0xFF10172B);
  static const Color starrySurface2 = Color(0xFF151E36);
  static const Color starryPrimary = Color(0xFFE8A0BB);
  static const Color starryAccent = Color(0xFFAEBBFF);
  static const Color starryText = Color(0xFFF5F4FA);
  static const Color starrySecondary = Color(0xFFA6ABC0);
  static const Color starryBorder = Color(0xFF1D2847);

  // --- Theme Builders ---
  static ThemeData get sakuraTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: sakuraBg,
      colorScheme: ColorScheme.light(
        surface: sakuraSurface,
        primary: sakuraPrimary,
        onPrimary: Colors.white,
        secondary: sakuraSecondary,
        onSecondary: Colors.white,
        onSurface: sakuraText,
        outline: sakuraBorder,
        primaryContainer: sakuraSoftPink,
        onPrimaryContainer: sakuraPrimaryDark,
      ),
      cardTheme: CardThemeData(
        color: sakuraSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: sakuraBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: sakuraText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: sakuraText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sakuraSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sakuraBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sakuraBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sakuraPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: sakuraSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sakuraPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: sakuraPrimaryDark,
          side: const BorderSide(color: sakuraPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get starryNightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: starryBg,
      colorScheme: ColorScheme.dark(
        surface: starrySurface,
        surfaceContainerHighest: starrySurface2,
        primary: starryPrimary,
        onPrimary: Colors.black,
        secondary: starrySecondary,
        onSecondary: Colors.white,
        tertiary: starryAccent,
        onSurface: starryText,
        outline: starryBorder,
        primaryContainer: starrySurface2,
        onPrimaryContainer: starryPrimary,
      ),
      cardTheme: CardThemeData(
        color: starrySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: starryBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: starryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: starryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: starrySurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: starryBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: starryBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: starryPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: starrySecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: starryPrimary,
          foregroundColor: const Color(0xFF080D1F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: starryAccent,
          side: const BorderSide(color: starryAccent),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

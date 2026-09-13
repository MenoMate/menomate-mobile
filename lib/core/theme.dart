import 'package:flutter/material.dart';

class MenoMateTheme {
  // --- Visual-system scale (canonical reference) ---
  // Type: screen title 20 bold · section heading 18 bold · card title
  // 16–18 w600/bold · body 14 · supporting 12–13 · caption/metadata 10–11.
  // Same semantic role always uses the same size/weight in both modes.
  // Spacing rhythm: 4 tight internal · 8–12 normal internal · 20–24
  // section gap · 32 screen bottom. Cards: radius 18, 1px outline,
  // elevation 0, no gloss. Primary buttons carry the rose; secondary
  // (outlined/text) actions use the restrained interaction indigo.
  // Canvas: warm-white neutral in light mode (never pink); deep
  // navy/plum in dark mode. Rose = menstrual only, violet = prediction
  // only, indigo = interaction only.
  // --- Sakura Pink (Light Theme) Palette ---
  // Warm-white neutral canvas + warm-neutral outline: the background
  // itself carries no pink. Rose lives only in semantic accents.
  static const Color sakuraBg = Color(0xFFFDFAF6);
  static const Color sakuraSurface = Color(0xFFFFFFFF);
  static const Color sakuraPrimary = Color(0xFFE88FA8);
  static const Color sakuraPrimaryDark = Color(0xFFC96883);
  static const Color sakuraText = Color(0xFF302A2D);
  static const Color sakuraSecondary = Color(0xFF756B70);
  static const Color sakuraBorder = Color(0xFFEBE2D8);
  static const Color sakuraSoftPink = Color(0xFFFCE8EE);
  // Muted periwinkle for predicted-span surfaces (calendar, legend).
  static const Color sakuraPredicted = Color(0xFF8F9BD8);
  // Dusty amber for the logger pain selector: categorical, calm, and
  // readable with white selected text. (Mood uses interaction indigo,
  // flow uses the menstrual rose pair — see symptom_logger_screen.)
  static const Color sakuraAmber = Color(0xFF9A6F38);

  // --- Semantic: pastel sage for wellness (supportive, non-menstrual) ---
  // Muted pistachio pair for the Today's Wellness tile: a harmonious
  // complementary hue that reduces pink dominance. Never for menstrual,
  // prediction, or interaction meaning.
  static const Color sakuraSage = Color(0xFFDFE9DB);
  static const Color sakuraSageInk = Color(0xFF5F7A5B);
  static const Color starrySage = Color(0xFF26332B);
  static const Color starrySageInk = Color(0xFFA9C4A4);

  // --- Semantic: interaction/selection (restrained indigo) ---
  // Used for navigation selection, focus rings, secondary (outlined/text)
  // actions, and navigation links. Never for menstrual or prediction
  // meaning: rose stays menstrual-only, violet stays prediction-only.
  static const Color sakuraInteraction = Color(0xFF5F6BA6);
  static const Color starryInteraction = Color(0xFF8E98C8);

  // --- Semantic: cycle-ring phase ramp (calm pastel, logo families) ---
  // Menstrual reuses the rose primary pair (sakuraPrimaryDark /
  // starryPrimary) so the ring's most important state shares the exact
  // menstrual token used by calendar logged fills. Other phases step
  // through muted lavender → mauve → dusty blush. All values are chosen
  // to read on their mode background without neon saturation.
  static const Color sakuraRingFollicular = Color(0xFF6E77B2);
  static const Color sakuraRingOvulation = Color(0xFF96689F);
  static const Color sakuraRingLuteal = Color(0xFFA26E86);
  static const Color starryRingFollicular = Color(0xFFA8B1E0);
  static const Color starryRingOvulation = Color(0xFFC79ACB);
  static const Color starryRingLuteal = Color(0xFFD3A3B3);

  /// Ring color for a backend phase string. Unknown phases fall back to
  /// the muted secondary neutral — never a saturated accent.
  static Color ringPhaseColor({required bool isDark, required String phase}) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return isDark ? starryPrimary : sakuraPrimaryDark;
      case 'follicular':
        return isDark ? starryRingFollicular : sakuraRingFollicular;
      case 'ovulation':
        return isDark ? starryRingOvulation : sakuraRingOvulation;
      case 'luteal':
        return isDark ? starryRingLuteal : sakuraRingLuteal;
      default:
        return isDark ? starrySecondary : sakuraSecondary;
    }
  }

  /// Interaction (selection/nav/focus) color for the current brightness.
  static Color interactionColor(bool isDark) =>
      isDark ? starryInteraction : sakuraInteraction;

  // --- Starry Night (Dark Theme) Palette ---
  static const Color starryBg = Color(0xFF080D1F);
  static const Color starrySurface = Color(0xFF10172B);
  static const Color starrySurface2 = Color(0xFF151E36);
  static const Color starryPrimary = Color(0xFFE8A0BB);
  static const Color starryAccent = Color(0xFFAEBBFF);
  static const Color starryText = Color(0xFFF5F4FA);
  static const Color starrySecondary = Color(0xFFA6ABC0);
  static const Color starryBorder = Color(0xFF1D2847);

  // --- Semantic: tinted dark surfaces (depth ladder, all stay dark) ---
  // Deep-navy foundation < surface < these faintly tinted cards <
  // surface2 < pastel accents. Each is the navy surface pulled ~10%
  // toward its semantic hue: rose for menstrual, violet for prediction,
  // sage for wellness. Light mode keeps neutral cards instead.
  static const Color starrySurfaceRose = Color(0xFF262539);
  static const Color starrySurfaceViolet = Color(0xFF1D243C);
  static const Color starrySurfaceSage = Color(0xFF1F2837);

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
        tertiary: sakuraPredicted,
        onTertiary: Colors.white,
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
          borderSide: const BorderSide(color: sakuraInteraction, width: 1.5),
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
          foregroundColor: sakuraInteraction,
          side: const BorderSide(color: sakuraInteraction),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sakuraInteraction,
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
          borderSide: const BorderSide(color: starryInteraction, width: 1.5),
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
          foregroundColor: starryInteraction,
          side: const BorderSide(color: starryInteraction),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: starryInteraction,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

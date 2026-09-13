import 'package:flutter/material.dart';

/// Theme-aware MenoMate brand mark. Selects the supplied logo asset from
/// the active [ThemeData] (light asset on light, dark asset on dark) so
/// callers never duplicate theme-selection logic.
///
/// Both brand marks are circular: the square artwork is clipped to the
/// inscribed oval, which only trims the plain background margins around
/// the centered lotus — the artwork itself is untouched.
class MenoMateLogo extends StatelessWidget {
  static const String lightAsset = 'assets/images/menomate_logo_light.png';
  static const String darkAsset = 'assets/images/menomate_logo_dark.png';

  /// Square edge length in logical pixels (matches the replaced mark).
  final double size;

  const MenoMateLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.asset(
          isDark ? darkAsset : lightAsset,
          fit: BoxFit.cover,
          semanticLabel: 'MenoMate logo',
        ),
      ),
    );
  }
}

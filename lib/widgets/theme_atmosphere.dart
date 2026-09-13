import 'package:flutter/material.dart';
import '../core/theme.dart';

class ThemeAtmosphereBackground extends StatelessWidget {
  final Widget child;

  const ThemeAtmosphereBackground({super.key, required this.child});

  /// Sakura table: seven petals spread across the upper background in
  /// logo tones only (rose / lavender / deep rose / mauve) at
  /// moderate-low opacity — clearly present, never pinking the canvas.
  /// `x` is a width fraction; `y`/`scale` are logical pixels.
  static const List<Map<String, Object>> lightPetals = [
    {'x': 0.10, 'y': 60.0, 'scale': 9.0, 'angle': 0.6, 'color': MenoMateTheme.sakuraPrimary, 'alpha': 0.16},
    {'x': 0.27, 'y': 150.0, 'scale': 7.0, 'angle': 1.2, 'color': MenoMateTheme.sakuraPredicted, 'alpha': 0.18},
    {'x': 0.16, 'y': 230.0, 'scale': 8.0, 'angle': 0.3, 'color': MenoMateTheme.sakuraPrimary, 'alpha': 0.14},
    {'x': 0.44, 'y': 80.0, 'scale': 10.0, 'angle': 0.9, 'color': MenoMateTheme.sakuraPredicted, 'alpha': 0.16},
    {'x': 0.58, 'y': 190.0, 'scale': 7.5, 'angle': 0.4, 'color': MenoMateTheme.sakuraPrimaryDark, 'alpha': 0.16},
    {'x': 0.73, 'y': 55.0, 'scale': 9.0, 'angle': 1.0, 'color': MenoMateTheme.sakuraPrimary, 'alpha': 0.14},
    {'x': 0.88, 'y': 165.0, 'scale': 7.0, 'angle': 0.5, 'color': MenoMateTheme.sakuraRingLuteal, 'alpha': 0.18},
  ];

  /// Star table: ten sparse points across the upper background in soft
  /// lavender and pale-neutral tones — noticeable at a glance, calm,
  /// the dark-mode counterpart to Sakura. No glow, no density.
  static const List<Map<String, Object>> darkStars = [
    {'x': 0.09, 'y': 50.0, 'r': 1.4, 'a': 0.36, 'color': MenoMateTheme.starryAccent},
    {'x': 0.26, 'y': 180.0, 'r': 1.1, 'a': 0.32, 'color': MenoMateTheme.starryAccent},
    {'x': 0.14, 'y': 270.0, 'r': 2.0, 'a': 0.40, 'color': MenoMateTheme.starryText},
    {'x': 0.40, 'y': 85.0, 'r': 1.3, 'a': 0.34, 'color': MenoMateTheme.starryRingOvulation},
    {'x': 0.55, 'y': 210.0, 'r': 1.0, 'a': 0.32, 'color': MenoMateTheme.starryAccent},
    {'x': 0.68, 'y': 40.0, 'r': 1.6, 'a': 0.38, 'color': MenoMateTheme.starryText},
    {'x': 0.62, 'y': 300.0, 'r': 2.2, 'a': 0.44, 'color': MenoMateTheme.starryAccent},
    {'x': 0.82, 'y': 125.0, 'r': 1.2, 'a': 0.34, 'color': MenoMateTheme.starryRingOvulation},
    {'x': 0.93, 'y': 235.0, 'r': 1.5, 'a': 0.40, 'color': MenoMateTheme.starryText},
    {'x': 0.47, 'y': 145.0, 'r': 1.1, 'a': 0.32, 'color': MenoMateTheme.starryAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AtmospherePainter(isDark: isDark),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final bool isDark;

  _AtmospherePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkStars(canvas, size);
    } else {
      _paintLightPetals(canvas, size);
    }
  }

  void _paintLightPetals(Canvas canvas, Size size) {
    for (final p in ThemeAtmosphereBackground.lightPetals) {
      final paint = Paint()
        ..color = (p['color'] as Color)
            .withValues(alpha: p['alpha'] as double)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(
          (p['x'] as double) * size.width, p['y'] as double);
      canvas.rotate(p['angle'] as double);
      final s = p['scale'] as double;

      final path = Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(s * 0.6, -s * 0.5, s * 0.5, s * 0.4)
        ..quadraticBezierTo(0, s * 0.8, -s * 0.5, s * 0.4)
        ..quadraticBezierTo(-s * 0.6, -s * 0.5, 0, -s)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _paintDarkStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in ThemeAtmosphereBackground.darkStars) {
      paint.color = (s['color'] as Color)
          .withValues(alpha: s['a'] as double);
      canvas.drawCircle(
        Offset((s['x'] as double) * size.width, s['y'] as double),
        s['r'] as double,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

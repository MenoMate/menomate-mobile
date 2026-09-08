import 'package:flutter/material.dart';

class ThemeAtmosphereBackground extends StatelessWidget {
  final Widget child;

  const ThemeAtmosphereBackground({super.key, required this.child});

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
    final paint = Paint()
      ..color = const Color(0xFFE88FA8).withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    // 3 subtle, small petals in the upper-right corner
    final petals = [
      {'x': size.width - 35, 'y': 65.0, 'scale': 9.0, 'angle': 0.6},
      {'x': size.width - 70, 'y': 45.0, 'scale': 7.0, 'angle': 1.2},
      {'x': size.width - 55, 'y': 105.0, 'scale': 8.0, 'angle': 0.3},
    ];

    for (final p in petals) {
      canvas.save();
      canvas.translate(p['x'] as double, p['y'] as double);
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

    // 7 tiny, subtle star points across the upper background
    final stars = [
      {'x': size.width * 0.15, 'y': 55.0, 'r': 1.2, 'a': 0.18},
      {'x': size.width * 0.38, 'y': 80.0, 'r': 1.5, 'a': 0.22},
      {'x': size.width * 0.62, 'y': 48.0, 'r': 1.1, 'a': 0.16},
      {'x': size.width * 0.82, 'y': 70.0, 'r': 1.6, 'a': 0.24},
      {'x': size.width * 0.90, 'y': 115.0, 'r': 1.0, 'a': 0.15},
      {'x': size.width * 0.28, 'y': 120.0, 'r': 1.2, 'a': 0.16},
      {'x': size.width * 0.74, 'y': 130.0, 'r': 1.3, 'a': 0.20},
    ];

    for (final s in stars) {
      paint.color = Colors.white.withValues(alpha: s['a'] as double);
      canvas.drawCircle(
        Offset(s['x'] as double, s['y'] as double),
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

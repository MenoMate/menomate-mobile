import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class InteractiveCycleRing extends StatelessWidget {
  final String phase;
  final int currentDay;
  final int cycleLength;

  const InteractiveCycleRing({
    super.key,
    required this.phase,
    required this.currentDay,
    required this.cycleLength,
  });

  @override
  Widget build(BuildContext context) {
    // Calm pastel phase ramp from the shared theme tokens (never neon
    // accents); the track follows the theme outline in both modes.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phaseColor =
        MenoMateTheme.ringPhaseColor(isDark: isDark, phase: phase);

    // Safely calculate progress between 0.0 and 1.0
    final progress = cycleLength > 0 ? (currentDay / cycleLength).clamp(0.0, 1.0) : 0.0;

    return Center(
      child: Container(
        width: 250,
        height: 250,
        padding: const EdgeInsets.all(16.0),
        child: CustomPaint(
          painter: CycleRingPainter(
            progress: progress,
            activeColor: phaseColor,
            // Track carries the same phase hue at a whisper: the ring
            // reads rose → mauve → lavender as a family while every
            // color still means exactly its phase. Geometry untouched.
            backgroundColor: phaseColor.withValues(alpha: 0.14),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Day $currentDay',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phase.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: phaseColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CycleRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;

  CycleRingPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    const strokeWidth = 20.0;

    // Draw background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw active progress arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    // Start from top (-pi / 2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

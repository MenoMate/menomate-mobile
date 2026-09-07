import 'dart:math';
import 'package:flutter/material.dart';

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
    // Map string response to colors
    Color phaseColor;
    switch (phase.toLowerCase()) {
      case 'menstrual':
        phaseColor = Colors.pinkAccent;
        break;
      case 'follicular':
        phaseColor = Colors.purpleAccent;
        break;
      case 'ovulation':
        phaseColor = Colors.orangeAccent;
        break;
      case 'luteal':
        phaseColor = Colors.greenAccent.shade400;
        break;
      default:
        phaseColor = Colors.grey.shade400;
    }

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
            backgroundColor: Colors.grey.shade200,
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

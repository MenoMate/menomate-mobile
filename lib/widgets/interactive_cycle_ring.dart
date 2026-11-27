import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Segmented, interactive cycle ring using MenoMate's semantic phase tokens.
///
/// Phase boundaries mirror the backend's `estimate_phase` count-back display
/// contract (`ovulation_day = max(periodLength + 2, cycleLength - 14)`).
/// Ovulation and phase segments are visual estimates, never measured hormone
/// events. When exploring days other than [currentDay], a clear "Return to
/// Day N" action restores today's authoritative server-provided view.
class InteractiveCycleRing extends StatefulWidget {
  final String phase;
  final int currentDay;
  final int cycleLength;
  final int periodLength;

  /// Optional "about phases" affordance shown beside the phase label.
  /// Null renders the label alone (e.g. in tests or static previews).
  final VoidCallback? onPhaseInfoTap;

  const InteractiveCycleRing({
    super.key,
    required this.phase,
    required this.currentDay,
    required this.cycleLength,
    this.periodLength = 5,
    this.onPhaseInfoTap,
  });

  @override
  State<InteractiveCycleRing> createState() => _InteractiveCycleRingState();
}

class _InteractiveCycleRingState extends State<InteractiveCycleRing> {
  int? _exploredDay;

  @override
  void didUpdateWidget(covariant InteractiveCycleRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDay != widget.currentDay ||
        oldWidget.cycleLength != widget.cycleLength) {
      _exploredDay = null;
    }
  }

  int get _activeDay {
    final maxDay = max(1, widget.cycleLength);
    return (_exploredDay ?? widget.currentDay).clamp(1, maxDay);
  }

  bool get _isExploring =>
      _exploredDay != null && _exploredDay != widget.currentDay.clamp(1, max(1, widget.cycleLength));

  /// Mirrors backend `estimate_phase` count-back boundaries for display-only
  /// day exploration.
  String _estimatedPhaseForDay(int day) {
    if (day == widget.currentDay) return widget.phase;
    final pLen = widget.periodLength.clamp(1, 12);
    if (day <= pLen) return 'menstrual';
    if (widget.cycleLength < 20 || widget.cycleLength > 45) return 'unknown';
    final ovDay = max(pLen + 2, widget.cycleLength - 14);
    if (day < ovDay - 1) return 'follicular';
    if (day <= ovDay + 1) return 'ovulation';
    return 'luteal';
  }

  void _handleRingTouch(Offset localPosition, Size size) {
    if (widget.cycleLength <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final outerR = min(size.width / 2, size.height / 2);
    // Ignore taps inside the central text area.
    if (dist < outerR * 0.45) return;

    // Angle from top (-pi/2) clockwise in [0, 2*pi).
    var angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final day = ((angle / (2 * pi)) * widget.cycleLength).floor() + 1;
    setState(() {
      _exploredDay = day.clamp(1, widget.cycleLength);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final maxDay = max(1, widget.cycleLength);
    final displayDay = _activeDay;
    final displayPhase = _estimatedPhaseForDay(displayDay);
    final phaseColor = MenoMateTheme.ringPhaseColor(
      isDark: isDark,
      phase: displayPhase,
    );

    final progress = widget.cycleLength > 0
        ? (displayDay / widget.cycleLength).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            onTapDown: (d) => _handleRingTouch(d.localPosition, const Size(250, 250)),
            onPanUpdate: (d) => _handleRingTouch(d.localPosition, const Size(250, 250)),
            child: SizedBox(
              width: 250,
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomPaint(
                  painter: CycleRingPainter(
                    progress: progress,
                    activeColor: phaseColor,
                    backgroundColor: phaseColor.withValues(alpha: 0.14),
                    cycleLength: maxDay,
                    periodLength: widget.periodLength,
                    currentDay: widget.currentDay.clamp(1, maxDay),
                    selectedDay: displayDay,
                    isDark: isDark,
                    markerBorderColor: colorScheme.surface,
                    markerFillColor: colorScheme.onSurface,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isExploring)
                            Text(
                              'Exploring',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                            ),
                          Text(
                            'Day $displayDay',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _isExploring && displayPhase == 'ovulation'
                                      ? 'Est. Ovulation'
                                      : formatPhaseLabel(displayPhase),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: phaseColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              if (widget.onPhaseInfoTap != null)
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  iconSize: 18,
                                  tooltip: 'About cycle phases',
                                  color: phaseColor,
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  onPressed: widget.onPhaseInfoTap,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (maxDay > 1) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                tooltip: 'Previous cycle day',
                color: colorScheme.secondary,
                onPressed: displayDay > 1
                    ? () => setState(() => _exploredDay = displayDay - 1)
                    : null,
              ),
              Expanded(
                child: Semantics(
                  label: 'Explore cycle day',
                  value: 'Day $displayDay of $maxDay',
                  child: Slider(
                    value: displayDay.toDouble(),
                    min: 1,
                    max: maxDay.toDouble(),
                    divisions: maxDay - 1,
                    activeColor: phaseColor,
                    onChanged: (v) =>
                        setState(() => _exploredDay = v.round()),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Next cycle day',
                color: colorScheme.secondary,
                onPressed: displayDay < maxDay
                    ? () => setState(() => _exploredDay = displayDay + 1)
                    : null,
              ),
            ],
          ),
          if (_isExploring)
            TextButton.icon(
              onPressed: () => setState(() => _exploredDay = null),
              icon: const Icon(Icons.today, size: 16),
              label: Text('Return to Day ${widget.currentDay}'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (maxDay >= 20 && maxDay <= 45) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final entry in const [
                  ('menstrual', 'Menstrual'),
                  ('follicular', 'Follicular'),
                  ('ovulation', 'Est. Ovulation'),
                  ('luteal', 'Luteal'),
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: MenoMateTheme.ringPhaseColor(
                            isDark: isDark,
                            phase: entry.$1,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.secondary,
                          fontWeight: displayPhase == entry.$1
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class CycleRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final int cycleLength;
  final int periodLength;
  final int currentDay;
  final int selectedDay;
  final bool isDark;
  final Color markerBorderColor;
  final Color markerFillColor;

  CycleRingPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.currentDay = 1,
    this.selectedDay = 1,
    this.isDark = false,
    this.markerBorderColor = Colors.white,
    this.markerFillColor = Colors.black87,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    const strokeWidth = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Base track in the current phase whisper
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Segmented estimated phase bands (subtle background segments when length is known)
    if (cycleLength >= 20 && cycleLength <= 45) {
      final pLen = periodLength.clamp(1, 12);
      final ovDay = max(pLen + 2, cycleLength - 14);
      final segments = <(int start, int end, String phase)>[
        (1, pLen, 'menstrual'),
        (pLen + 1, ovDay - 2, 'follicular'),
        (ovDay - 1, ovDay + 1, 'ovulation'),
        (ovDay + 2, cycleLength, 'luteal'),
      ];
      for (final seg in segments) {
        if (seg.$2 < seg.$1) continue;
        final startAngle = -pi / 2 + 2 * pi * ((seg.$1 - 1) / cycleLength);
        final sweep = 2 * pi * ((seg.$2 - seg.$1 + 1) / cycleLength);
        final segColor = MenoMateTheme.ringPhaseColor(
          isDark: isDark,
          phase: seg.$3,
        );
        final segPaint = Paint()
          ..color = segColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, sweep, false, segPaint);
      }
    }

    // Active progress arc up to selected/current day
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, activePaint);

    // Selected-day outer halo when exploring a different day
    if (cycleLength > 0 && selectedDay != currentDay) {
      final selFrac = (selectedDay / cycleLength).clamp(0.0, 1.0);
      final selAngle = -pi / 2 + 2 * pi * selFrac;
      final selCenter = Offset(
        center.dx + radius * cos(selAngle),
        center.dy + radius * sin(selAngle),
      );
      canvas.drawCircle(
        selCenter,
        10,
        Paint()..color = activeColor.withValues(alpha: 0.28),
      );
      canvas.drawCircle(
        selCenter,
        6,
        Paint()..color = activeColor,
      );
    }

    // Current-day marker dot on the ring
    if (cycleLength > 0) {
      final curFrac = (currentDay / cycleLength).clamp(0.0, 1.0);
      final curAngle = -pi / 2 + 2 * pi * curFrac;
      final markerCenter = Offset(
        center.dx + radius * cos(curAngle),
        center.dy + radius * sin(curAngle),
      );
      canvas.drawCircle(
        markerCenter,
        7,
        Paint()..color = markerBorderColor,
      );
      canvas.drawCircle(
        markerCenter,
        4.5,
        Paint()..color = markerFillColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.cycleLength != cycleLength ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.isDark != isDark;
  }
}

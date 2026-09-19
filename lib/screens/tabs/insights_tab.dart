import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/insight_library.dart';
import '../../core/format.dart';
import '../../data/sync_policy.dart';
import '../../models/daily_log.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/daily_insight_card.dart';
import 'home_tab.dart' show showPhaseInfoSheet;

/// Insights: MenoMate-generated understanding, kept strictly separate
/// from Health Context (information the *user* provides — conditions,
/// medications, context live under Profile & Health, never here).
///
/// V1 sections, all backed by real local data — no placeholders:
/// - "For you today": the deterministic daily pair (same source as Home).
/// - "Understand your cycle": the server-provided phase plus the shared
///   phase explainer. Phase display only; nothing here computes phases.
/// - "Symptom patterns": logged-days-per-symptom from the user's own
///   daily-log rows (local aggregate, never interpreted as conditions).
///
/// Future categories (sexual health, fertility, menopause, hormonal
/// health, nutrition, lifestyle, condition-specific education) slot in as
/// additional sections here once real content sources exist for them.
/// Nothing in this file may invent personalized medical claims.
class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Transparent: the shared ThemeAtmosphereBackground painted by
      // HomeScreen shows through, like every other tab.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Insights',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildSectionHeader('FOR YOU', colorScheme, caption: true),
              _buildSectionHeader('For you today', colorScheme),
              _TodayCard(),
              const SizedBox(height: 20),
              _buildSectionHeader('Understand your cycle', colorScheme),
              const _PhaseCard(),
              const SizedBox(height: 20),
              _buildSectionHeader('Cycle trends', colorScheme),
              const _CycleTrendsCard(),
              const SizedBox(height: 20),
              _buildSectionHeader('Symptom patterns', colorScheme),
              const _SymptomPatternsCard(),
              const SizedBox(height: 20),
              _buildSectionHeader(
                'LEARN / EXPLORE',
                colorScheme,
                caption: true,
              ),
              const _LearnCard(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    ColorScheme colorScheme, {
    bool caption = false,
  }) {
    if (caption) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4, top: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: colorScheme.secondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Today's deterministic pair, rendered as the hero: a soft tint lifts it
/// above the plain section cards. Same provider and same display widgets
/// as the Home card — one system, two surfaces.
class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final insightAsync = ref.watch(dailyInsightProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: insightAsync.when(
        data: (pair) {
          final insight =
              pair?.insight ??
              const InsightPiece(
                body: 'Listen to your body today and take it easy.',
              );
          final action = pair?.action;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InsightPieceBody(piece: insight),
              if (action != null) ...[
                const SizedBox(height: 12),
                const InsightSectionLabel(text: 'Something to try'),
                const SizedBox(height: 4),
                InsightPieceBody(piece: action, quiet: true),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => Text(
          'Could not fetch your daily insight. Please try again later.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// Current server-provided phase plus the shared explainer entry point.
/// Display only — phase strings are never computed or reinterpreted here.
class _PhaseCard extends ConsumerWidget {
  const _PhaseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cycleAsync = ref.watch(currentCycleProvider);
    final phase = cycleAsync.value?.dataOrNull?.phase;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase == null ? 'Phase unknown yet' : formatPhaseLabel(phase),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phase == null ? 'Log periods to see phase-based guidance here.' : 'Estimated from your logged history — phases can vary from cycle to cycle.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => showPhaseInfoSheet(context),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('About cycle phases'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cycle trends from the user's own logged cycles: a count plus a small
/// bar chart of recent period lengths. Observed data only — no estimates,
/// no averages presented as predictions, no chart when there is nothing
/// to chart. A short data-quality note appears while history is thin.
class _CycleTrendsCard extends ConsumerWidget {
  const _CycleTrendsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cyclesAsync = ref.watch(cycleListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: cyclesAsync.when(
        data: (state) {
          final cycles = state.dataOrNull ?? [];
          if (cycles.isEmpty) {
            return Text(
              'Log periods to see your cycle trends here.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            );
          }
          final sorted = cycles.toList()
            ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
          final lengths = [
            for (final c in sorted)
              if (c.periodLengthDays != null) c.periodLengthDays!,
          ].take(6).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\u2019ve logged ${cycles.length} ${cycles.length == 1 ? 'cycle' : 'cycles'}.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (lengths.length >= 2) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrendBarsPainter(
                      values: lengths,
                      barColor: colorScheme.primary,
                      labelColor: colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recent period lengths, in days. Based on your logged periods.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (cycles.length < 3) ...[
                const SizedBox(height: 8),
                Text(
                  'More history can help MenoMate understand your pattern.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => Text(
          'Couldn\u2019t load cycle trends.',
          style: TextStyle(fontSize: 13, color: colorScheme.secondary),
        ),
      ),
    );
  }
}

/// Minimal bar chart: one rounded bar per value, scaled to the max, with
/// the day count under each bar. No gridlines, no smoothing, no trend
/// line — the bars show exactly what was logged and nothing more.
class _TrendBarsPainter extends CustomPainter {
  final List<int> values;
  final Color barColor;
  final Color labelColor;

  _TrendBarsPainter({
    required this.values,
    required this.barColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return;
    const labelReserve = 20.0;
    final chartHeight = size.height - labelReserve;
    final slot = size.width / values.length;
    final barWidth = (slot * 0.5).clamp(12.0, 36.0);
    final barPaint = Paint()..color = barColor.withValues(alpha: 0.85);
    for (var i = 0; i < values.length; i++) {
      final fraction = values[i] / maxValue;
      final barHeight = (chartHeight * fraction).clamp(8.0, chartHeight);
      final centerX = slot * i + slot / 2;
      final rect = RRect.fromLTRBR(
        centerX - barWidth / 2,
        chartHeight - barHeight,
        centerX + barWidth / 2,
        chartHeight,
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${values[i]}',
          style: TextStyle(fontSize: 11, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);
      labelPainter.paint(
        canvas,
        Offset(centerX - labelPainter.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendBarsPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.labelColor != labelColor;
  }
}

/// Most-logged symptoms: logged days per symptom type from the user's own
/// daily-log rows (local aggregate, works offline). Raw counts with
/// canonical labels — ranked, never interpreted, never diagnosed.
/// Uses [symptomFrequencyProvider] on purpose: the history summary is
/// always assembled locally with empty frequencies, so it can never feed
/// this section.
class _SymptomPatternsCard extends ConsumerWidget {
  const _SymptomPatternsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final frequenciesAsync = ref.watch(symptomFrequencyProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: frequenciesAsync.when(
        data: (frequencies) {
          if (frequencies.isEmpty) {
            return Text(
              'Log symptoms to see patterns here.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            );
          }
          final ranked = frequencies.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return Column(
            children: [
              for (final entry in ranked.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _symptomLabel(entry.key),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        entry.value == 1
                            ? 'Logged once'
                            : 'Logged ${entry.value} times',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => Text(
          'Couldn\u2019t load symptom patterns.',
          style: TextStyle(fontSize: 13, color: colorScheme.secondary),
        ),
      ),
    );
  }
}

/// Deterministic educational content (no AI, no diagnoses). Static
/// explainers already present in MenoMate: cycle basics, tracking tips,
/// and when to consider talking to a clinician. Tapping a topic shows a
/// calm bottom sheet — same pattern as cycle phases.
class _LearnCard extends StatelessWidget {
  const _LearnCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const topics = [
      (
        'Cycle basics',
        'Periods, cycle length, and why cycles vary.',
        'A cycle runs from the first day of one period to the day before the next. Lengths vary between people and across time — tracking your own history is the most reliable guide. MenoMate shows only what you log plus server estimates, never invented fertile windows.',
      ),
      (
        'Tracking tips',
        'Small, consistent logs beat perfect logs.',
        'Log period starts promptly, note flow and symptoms in your own words, and edit past entries when you remember more. Future entries stay marked future so today\u2019s view stays honest. Offline logs sync when you\u2019re back online.',
      ),
      (
        'When to seek care',
        'Red flags mean talk to a clinician promptly.',
        'Very heavy bleeding, severe pain that stops daily life, fainting, or bleeding between periods deserves prompt clinical attention. MenoMate Care can help you think through what to share — it never diagnoses.',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          for (final t in topics)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(
                  t.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(t.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.$1,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.$3,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: scheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Got it'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Canonical backend label when known; otherwise a neutral humanization
/// of the id (underscores to spaces, capitalized). Unknown ids are shown
/// as-is in shape — never mapped to a condition or claim.
String _symptomLabel(String id) {
  for (final symptom in kLoggableSymptoms) {
    if (symptom.id == id) return symptom.label;
  }
  final words = id.replaceAll('_', ' ').trim();
  if (words.isEmpty) return id;
  return words[0].toUpperCase() + words.substring(1);
}

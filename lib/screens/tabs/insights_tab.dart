import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/insight_library.dart';
import '../../core/format.dart';
import '../../data/sync_policy.dart';
import '../../models/care.dart';
import '../../models/daily_log.dart' show kLoggableSymptoms;
import '../../providers/cycle_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/offline_mode_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/daily_insight_card.dart';
import 'home_tab.dart' show showPhaseInfoSheet;

final careServerInsightsProvider = FutureProvider<List<CareInsight>>((
  ref,
) async {
  if (ref.watch(isOfflineTrackingProvider)) return const [];
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  try {
    return await ref.watch(apiServiceProvider).fetchCareInsights();
  } catch (_) {
    return const [];
  }
});

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
              _buildSectionHeader('Current cycle phase', colorScheme),
              const _PhaseCard(),
              const SizedBox(height: 20),
              _buildSectionHeader('My patterns', colorScheme),
              const _CycleTrendsCard(),
              const SizedBox(height: 12),
              const _MyPatternsDetailsCard(),
              const _ServerCareInsightsCard(),
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
          final pattern = ref.watch(localPatternSummaryProvider).value;
          final cycleLengths = pattern?.observedCycleLengths ?? const <int>[];
          final periodLengths = [
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
              if (cycleLengths.length >= 2) ...[
                const SizedBox(height: 12),
                Text(
                  'Observed cycle lengths (start-to-start)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 88,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrendBarsPainter(
                      values: cycleLengths,
                      barColor: colorScheme.tertiary,
                      labelColor: colorScheme.secondary,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Log at least 3 period starts to chart start-to-start cycle lengths.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (periodLengths.length >= 2) ...[
                const SizedBox(height: 12),
                Text(
                  'Recorded period durations (days)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 88,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrendBarsPainter(
                      values: periodLengths,
                      barColor: colorScheme.primary,
                      labelColor: colorScheme.secondary,
                    ),
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
    final pattern = ref.watch(localPatternSummaryProvider).value;

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
          final topCount = ranked.first.value;
          final statsById = {
            if (pattern != null)
              for (final s in pattern.symptomStats) s.symptom: s,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most frequently logged symptoms',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in ranked.take(5)) ...[
                Builder(
                  builder: (context) {
                    final stat = statsById[entry.key];
                    final buckets = pattern?.symptomByCycleBucket[entry.key];
                    String? topWindow;
                    if (buckets != null && buckets.isNotEmpty) {
                      final sortedB = buckets.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      topWindow = sortedB.first.key;
                    }
                    final sevText = stat?.avgSeverity != null
                        ? ' · avg ${stat!.avgSeverity!.toStringAsFixed(1)}/5'
                        : '';
                    final windowText =
                        topWindow != null ? ' · most often $topWindow' : '';
                    final ratio =
                        topCount > 0 ? (entry.value / topCount).clamp(0.1, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                    ? '1 day'
                                    : '${entry.value} days',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                          if (sevText.isNotEmpty || windowText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Logged ${entry.value}x$sevText$windowText',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
class _LearnSectionItem {
  final String heading;
  final String body;
  final String? trackNote;
  final String? clinicianNote;

  const _LearnSectionItem({
    required this.heading,
    required this.body,
    this.trackNote,
    this.clinicianNote,
  });
}

class _LearnTopic {
  final IconData icon;
  final String title;
  final String subtitle;
  final String intro;
  final List<_LearnSectionItem> sections;
  final String? sourceNote;

  const _LearnTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.sections,
    this.sourceNote,
  });
}

/// Categorized LEARN / EXPLORE cards — each card opens a calm, medically
/// grounded detail sheet instead of crowding the main scroll view.
class _LearnCard extends StatelessWidget {
  const _LearnCard();

  static const List<_LearnTopic> _topics = [
    _LearnTopic(
      icon: Icons.loop_rounded,
      title: 'Cycle basics',
      subtitle: 'Phases, typical 21–35 day range, and why cycles vary.',
      intro:
          'A menstrual cycle begins on Day 1 of bleeding and ends the day before the next period starts. Across adults, typical cycle lengths commonly span 21–35 days, with periods lasting 2–7 days.',
      sections: [
        _LearnSectionItem(
          heading: 'Menstrual phase (Day 1 onward)',
          body:
              'The uterine lining sheds as estrogen and progesterone are low. Cramping, lower back ache, and fatigue are commonly logged during the first 1–3 days.',
        ),
        _LearnSectionItem(
          heading: 'Follicular phase',
          body:
              'Overlaps menstruation and continues until ovulation. Rising estrogen stimulates follicles in the ovary and rebuilds the uterine lining.',
        ),
        _LearnSectionItem(
          heading: 'Ovulatory phase (estimate only)',
          body:
              'A mid-cycle transition around ~14 days before the next expected period. Calendar estimates are approximations — confirmed ovulation requires lab testing, ultrasound, or validated ovulation/BBT tracking.',
        ),
        _LearnSectionItem(
          heading: 'Luteal phase',
          body:
              'Follows ovulation until the next period. Progesterone rises and then falls if pregnancy does not occur, which can accompany mood shifts, bloating, or breast tenderness.',
        ),
        _LearnSectionItem(
          heading: 'Why timing varies',
          body:
              'Sleep disruption, travel, stress, illness, exercise changes, and life-stage transitions can shift ovulation timing and overall cycle length.',
        ),
      ],
      sourceNote: 'Grounded in ACOG & NHS menstrual cycle guidance. Informational only.',
    ),
    _LearnTopic(
      icon: Icons.edit_calendar_outlined,
      title: 'Tracking tips',
      subtitle: 'Consistent logs make personal patterns clearer.',
      intro:
          'Small, steady entries are far more useful than trying to log everything perfectly.',
      sections: [
        _LearnSectionItem(
          heading: 'Log period starts promptly',
          body:
              'Cycle length is measured from one period start to the next. Marking the start and end dates accurately keeps predictions and trends reliable.',
        ),
        _LearnSectionItem(
          heading: 'Pain 0 vs. unlogged days',
          body:
              'Leaving pain blank means "not recorded" — MenoMate never assumes a missed day was pain-free. Setting pain to 0 records that you explicitly felt no pain.',
        ),
        _LearnSectionItem(
          heading: 'Offline-first & editable',
          body:
              'You can log anytime without internet. Past days can be updated in place from Calendar, and pending entries sync automatically once online.',
        ),
      ],
    ),
    _LearnTopic(
      icon: Icons.track_changes_outlined,
      title: 'Common concerns',
      subtitle: 'What to track for cramps, heavy flow, PMS, and fatigue.',
      intro:
          'Recording concrete details helps you and a clinician see whether symptoms follow a cycle pattern or are changing over time.',
      sections: [
        _LearnSectionItem(
          heading: 'Cramps & pelvic pain',
          body:
              'Primary dysmenorrhea is caused by uterine prostaglandins and usually peaks in the first 1–3 days of bleeding.',
          trackNote: 'Pain score (0–10), cycle day, and heat/rest relief.',
          clinicianNote:
              'Seek evaluation if pain stops daily activities, worsens over cycles, or occurs outside bleeding.',
        ),
        _LearnSectionItem(
          heading: 'Heavy menstrual bleeding',
          body:
              'Consistently heavy bleeding can interfere with daily life and lower iron stores over time.',
          trackNote: 'Flow intensity, number of bleeding days, and clots/fatigue.',
          clinicianNote:
              'Consult a clinician if bleeding regularly lasts >7–8 days or you soak through a pad/tampon hourly for 2+ hours.',
        ),
        _LearnSectionItem(
          heading: 'PMS & mood shifts',
          body:
              'Luteal-phase hormone shifts commonly coincide with irritability, low mood, bloating, or breast tenderness that ease after bleeding starts.',
          trackNote: 'Moods, bloating, sleep/fatigue, and cycle day.',
          clinicianNote:
              'Discuss persistent or severe premenstrual distress (such as PMDD symptoms) with a healthcare provider.',
        ),
        _LearnSectionItem(
          heading: 'Irregular or delayed periods',
          body:
              'Occasional variation is normal, especially during stress or perimenopause, while repeated cycles <21 or >35 days deserve review.',
          trackNote: 'All period start/end dates and flow changes.',
        ),
      ],
      sourceNote: 'Based on ACOG & NHS patient education. Not a medical diagnosis.',
    ),
    _LearnTopic(
      icon: Icons.medical_information_outlined,
      title: 'Health conditions guide',
      subtitle: 'Delayed periods, PCOS, endometriosis, fibroids, thyroid & more.',
      intro:
          'These medically recognized conditions can affect menstrual patterns. MenoMate cannot diagnose conditions — use this guide to understand what observations are helpful to share with a clinician.',
      sections: [
        _LearnSectionItem(
          heading: 'Delayed or missed periods (amenorrhea / oligomenorrhea)',
          body:
              'Cycles >35 days apart or missed periods can stem from stress, sudden weight/exercise changes, PCOS, thyroid disorders, high prolactin, or pregnancy (if applicable).',
          trackNote: 'Start/end dates, stress/illness notes, and accompanying symptoms.',
          clinicianNote:
              'See a clinician if you miss 3+ periods in a row or cycles repeatedly exceed 35 days.',
        ),
        _LearnSectionItem(
          heading: 'PCOS (Polycystic Ovary Syndrome)',
          body:
              'A common endocrine condition involving ovulatory irregularity and elevated androgen levels, often linked with infrequent/prolonged cycles, acne, or excess hair growth.',
          trackNote: 'Cycle intervals, acne, low energy, and mood patterns across 3+ months.',
          clinicianNote:
              'Diagnosis requires clinical criteria, blood tests, and/or pelvic ultrasound.',
        ),
        _LearnSectionItem(
          heading: 'Endometriosis',
          body:
              'Tissue similar to the uterine lining grows outside the uterus, often causing severe menstrual cramps, chronic pelvic pain, lower back pain, fatigue, or painful bowel/bladder symptoms.',
          trackNote: 'Pain scores (0–10) before/during/after bleeding and symptom severity.',
          clinicianNote:
              'Discuss progressive pelvic pain or pain that disrupts work, school, or sleep.',
        ),
        _LearnSectionItem(
          heading: 'Uterine fibroids',
          body:
              'Benign (non-cancerous) muscle growths in the uterus that can cause heavy or prolonged bleeding, pelvic pressure, lower back ache, or frequent urination.',
          trackNote: 'Heavy flow days, bleeding duration, and pelvic/back pain.',
        ),
        _LearnSectionItem(
          heading: 'Thyroid & hormonal shifts',
          body:
              'Both hypothyroidism (underactive) and hyperthyroidism (overactive) can alter cycle frequency and flow volume alongside fatigue, temperature sensitivity, or mood changes.',
          trackNote: 'Cycle length changes, energy/fatigue, and mood.',
        ),
        _LearnSectionItem(
          heading: 'Perimenopause transitions',
          body:
              'In the years before menopause, fluctuating estrogen and fewer ovulatory cycles commonly cause irregular intervals, heavier or lighter flow, hot flashes, and sleep changes.',
          trackNote: 'Cycle-length variability, flow changes, and fatigue across 3–6 months.',
        ),
        _LearnSectionItem(
          heading: 'Iron deficiency & fatigue',
          body:
              'Repeated heavy menstrual bleeding is a leading cause of low iron/anemia, causing persistent tiredness, shortness of breath, or dizziness.',
          trackNote: 'Heavy flow days alongside low energy or lightheadedness.',
        ),
      ],
      sourceNote:
          'Educational summary aligned with ACOG, WHO, and NHS clinical guidance. Always consult a qualified clinician for diagnosis.',
    ),
    _LearnTopic(
      icon: Icons.health_and_safety_outlined,
      title: 'When to seek care',
      subtitle: 'Urgent warning signs that need prompt clinical attention.',
      intro:
          'Do not wait for an app pattern if you experience acute or severe warning signs.',
      sections: [
        _LearnSectionItem(
          heading: 'Seek urgent / emergency care for:',
          body:
              '• Soaking through 1 or more pads/tampons every hour for 2+ consecutive hours\n'
              '• Sudden, severe, or worsening abdominal/pelvic pain\n'
              '• Fainting, severe dizziness, shortness of breath, or chest pain\n'
              '• High fever or foul-smelling discharge with pelvic pain\n'
              '• Bleeding after menopause or unexpected heavy bleeding',
        ),
      ],
      sourceNote: 'ACOG / NHS urgent warning-sign guidance.',
    ),
  ];

  void _openTopicSheet(BuildContext context, _LearnTopic topic) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(topic.icon, color: scheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                topic.intro,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              for (final sec in topic.sections) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sec.heading,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sec.body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: scheme.secondary,
                        ),
                      ),
                      if (sec.trackNote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'What to track: ${sec.trackNote}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                      if (sec.clinicianNote != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'When to see a clinician: ${sec.clinicianNote}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (topic.sourceNote != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                    topic.sourceNote!,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.secondary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _topics.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: scheme.outline.withValues(alpha: 0.6),
              ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _topics[i].icon,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  _topics[i].title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _topics[i].subtitle,
                  style: TextStyle(fontSize: 12, color: scheme.secondary),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.secondary,
                ),
                onTap: () => _openTopicSheet(context, _topics[i]),
              ),
            ),
          ],
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

class _MyPatternsDetailsCard extends ConsumerWidget {
  const _MyPatternsDetailsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final patternAsync = ref.watch(localPatternSummaryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: patternAsync.when(
        data: (p) {
          if (p == null || p.loggedDays == 0) {
            return Text(
              'No daily logs yet. Missing days are never assumed symptom-free — log symptoms, pain, or mood to build your personal patterns.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            );
          }

          final pct = (p.coverageRatio * 100).round();
          final recentPains = p.painSeries.length > 7
              ? p.painSeries.sublist(p.painSeries.length - 7)
              : p.painSeries;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${p.loggedDays}/${p.effectiveWindowDays} active days',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.painLoggedDays}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Pain days (${p.explicitZeroPainDays} at 0)',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Pain severity trend (when >= 2 pain logs exist)
              if (recentPains.length >= 2) ...[
                const SizedBox(height: 14),
                Text(
                  'Recent pain scores (0–10)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 76,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrendBarsPainter(
                      values: [for (final e in recentPains) e.pain],
                      barColor: colorScheme.secondary,
                      labelColor: colorScheme.secondary,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'Log pain on at least 2 days to chart your pain trend.',
                  style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                ),
              ],

              // Current vs previous cycle comparison
              if (p.cycleComparison != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Same-day cycle comparison (through Day ${p.cycleComparison!.currentDay})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.cycleComparison!.currentPainAvg != null &&
                          p.cycleComparison!.previousPainAvg != null
                      ? 'Current cycle avg pain: ${p.cycleComparison!.currentPainAvg}/10 (${p.cycleComparison!.currentLogCount} logs) vs previous cycle: ${p.cycleComparison!.previousPainAvg}/10 (${p.cycleComparison!.previousLogCount} logs).'
                      : 'Need pain logs in both current and previous cycles through Day ${p.cycleComparison!.currentDay} to compare.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.35,
                  ),
                ),
              ],

              // Symptom-by-cycle-day heatmap (when >= 2 symptoms logged with cycle days)
              if (p.symptomByCycleBucket.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Symptoms by cycle day window',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                for (final entry in p.symptomByCycleBucket.entries.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${_symptomLabel(entry.key)}: ${entry.value.entries.map((b) => '${b.key} (${b.value}x)').join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
              ],

              // Mood distribution (when >= 3 mood logs exist)
              if (p.moodCounts.values.fold<int>(0, (a, b) => a + b) >= 3) ...[
                const SizedBox(height: 14),
                Text(
                  'Mood distribution',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in (p.moodCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value))))
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${m.key} (${m.value})',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => Text(
          'Could not compute local pattern summary.',
          style: TextStyle(fontSize: 13, color: colorScheme.secondary),
        ),
      ),
    );
  }
}

class _ServerCareInsightsCard extends ConsumerWidget {
  const _ServerCareInsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(careServerInsightsProvider);
    final insights = async.value;
    if (insights == null || insights.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined,
                    size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Synced Care insights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in insights.take(3)) ...[
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.explanation,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: scheme.secondary,
                ),
              ),
              if (item.caveat != null && item.caveat!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.caveat!,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.secondary.withValues(alpha: 0.75),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

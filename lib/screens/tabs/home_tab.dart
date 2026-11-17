import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/sync_policy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/reproductive_home_block.dart';
import '../../widgets/symptom_logger_card.dart';
import '../../widgets/device_telemetry_card.dart';
import '../../widgets/period_tracker_button.dart';
import '../../widgets/interactive_cycle_ring.dart';
import '../../widgets/daily_insight_card.dart';
import '../../widgets/menomate_logo.dart';
import '../../providers/logo_variant_provider.dart';
import '../../providers/health_providers.dart';
import '../home_screen.dart';
import '../profile_screen.dart';

String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(profileProvider);
    final cycleAsync = ref.watch(currentCycleProvider);

    return Scaffold(
      // Transparent: the shared ThemeAtmosphereBackground painted by
      // HomeScreen shows through; tab content cards stay opaque.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Root tab: never show a back arrow here. Detail screens pushed
        // from Home carry their own (automatic) back affordance.
        automaticallyImplyLeading: false,
        title: profileAsync.when(
          data: (profileState) {
            final profile = profileState.dataOrNull;
            final now = DateTime.now();
            final greeting = _greetingForHour(now.hour);
            final dateStr = DateFormat('EEE, MMM d, yyyy').format(now);
            return Row(
              children: [
                // Home greeting logo is FIXED brand identity (standard
                // circle) and never follows the launcher-icon selector in
                // Settings. See docs/launcher_icon.md.
                const MenoMateLogo(size: 34, variant: AppLogoVariant.standard),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, ${profile?.name ?? "MenoMate User"}',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$dateStr · Welcome to your cycle companion',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Text(
            'MenoMate',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          error: (_, _) => Text(
            'MenoMate',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => refreshAllAppData(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshAllAppData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Cycle Overview Card
              cycleAsync.when(
                data: (cycleState) {
                  if (cycleState is Unavailable) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Center(
                        child: Text(
                          'Couldn\'t load cycle data. Check your connection and pull to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                      ),
                    );
                  }
                  final cycleData = cycleState.dataOrNull;
                  if (cycleData == null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Center(
                        child: Text(
                          'No cycle data available. Log your period to begin.',
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                      ),
                    );
                  }

                  // Predict text — Rule J: display backend results, no client date math.
                  // Rule F: never show negative countdown.
                  // Hierarchy: one compact primary line; confidence is a
                  // subtle secondary suffix, never equal-weight text.
                  // Confidence is server-provided and optional: unknown
                  // sentinels render as no suffix rather than jargon such as
                  // "None confidence".
                  String? confidenceSuffix(String conf) {
                    final c = conf.trim().toLowerCase();
                    if (c.isEmpty ||
                        c == 'none' ||
                        c == 'unknown' ||
                        c == 'insufficient_data') {
                      return null;
                    }
                    return '${conf.trim()} confidence';
                  }

                  String nextPeriodMain = 'Log cycles to calculate prediction';
                  String? nextPeriodSuffix;
                  if (cycleData.predictionSource == 'user_logged' &&
                      cycleData.latestPeriodStart != null) {
                    // Recorded user entry, not a forecast: plain recorded
                    // wording with no confidence suffix.
                    final loggedStr = DateFormat('MMM d')
                        .format(cycleData.latestPeriodStart!);
                    final daysLeft = cycleData.daysUntilNextPeriod;
                    if (daysLeft == null || daysLeft <= 0) {
                      nextPeriodMain = 'Logged period for $loggedStr';
                    } else {
                      nextPeriodMain =
                          'Logged period starting $loggedStr (in ~$daysLeft days)';
                    }
                  } else if (cycleData.predictedNextPeriod != null) {
                    final nextDateStr = DateFormat('MMM d')
                        .format(cycleData.predictedNextPeriod!);
                    final daysLeft = cycleData.daysUntilNextPeriod;
                    final status = cycleData.predictionStatus;
                    final conf = cycleData.predictionConfidence;
                    if (daysLeft == null) {
                      nextPeriodMain = 'Expected around $nextDateStr';
                      nextPeriodSuffix = confidenceSuffix(conf);
                    } else if (status == 'awaiting_next_start') {
                      nextPeriodMain =
                          'Expected around $nextDateStr — Log your next period when it starts';
                    } else if (daysLeft <= 0 || status == 'today') {
                      // Backend clamps passed predictions to 0; treat as today/expected.
                      nextPeriodMain = 'Next period: $nextDateStr (today)';
                      nextPeriodSuffix = confidenceSuffix(conf);
                    } else {
                      nextPeriodMain =
                          'Next period: $nextDateStr (in ~$daysLeft days)';
                      nextPeriodSuffix = confidenceSuffix(conf);
                    }
                  }

                  // Tracked period/bleeding status. Intentionally separate from
                  // the backend cycle-phase classification in the ring above:
                  // this line reports only whether the user's logged period
                  // is ongoing or has ended, from stored start/end facts.
                  // It derives no phase, prediction, or confidence.
                  String? periodStatus;
                  if (cycleData.hasData &&
                      cycleData.latestPeriodStart != null) {
                    if (cycleData.isOngoing) {
                      periodStatus = 'Period in progress';
                    } else if (cycleData.latestPeriodEnd != null) {
                      final start = cycleData.latestPeriodStart!;
                      final end = cycleData.latestPeriodEnd!;
                      final startDay = DateTime(
                        start.year,
                        start.month,
                        start.day,
                      );
                      final endDay = DateTime(end.year, end.month, end.day);
                      final days = endDay.difference(startDay).inDays + 1;
                      periodStatus =
                          'Period ended ${DateFormat('MMM d').format(endDay)} · ${formatDayCount(days, 'day')}';
                    }
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // The cycle card is menstrual home: neutral white in
                      // light mode, faint dusty-rose navy in dark mode.
                      color: theme.brightness == Brightness.dark
                          ? MenoMateTheme.starrySurfaceRose
                          : colorScheme.surface,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        SyncStatusChip(state: cycleState),
                        // Cycle ring: Day N + server phase stay dominant.
                        // No fake 28-day default: the progress arc needs a
                        // real length. A known day still renders its labels;
                        // a fully unknown position renders an unknown state.
                        Builder(
                          builder: (context) {
                            final cycleLength =
                                cycleData.averageCycleLength ??
                                cycleData.predictedCycleLength;
                            final currentDay = cycleData.currentCycleDay;
                            if (currentDay == null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'Not enough data yet — log more periods to see your cycle ring.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.secondary,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }
                            if (cycleLength == null) {
                              final phaseColor = MenoMateTheme.ringPhaseColor(
                                isDark: theme.brightness == Brightness.dark,
                                phase: cycleData.phase,
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Day $currentDay',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatPhaseLabel(cycleData.phase),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: phaseColor,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                InteractiveCycleRing(
                                  phase: cycleData.phase,
                                  currentDay: currentDay,
                                  cycleLength: cycleLength,
                                  onPhaseInfoTap: () =>
                                      showPhaseInfoSheet(context),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Compact prediction line + subtle confidence suffix.
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: nextPeriodMain),
                              if (nextPeriodSuffix != null)
                                TextSpan(
                                  text: ' · $nextPeriodSuffix',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.secondary.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Tracked period status: quieter secondary line,
                        // smaller than Day and phase, no phase-color semantics.
                        if (periodStatus != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            periodStatus,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.secondary.withValues(
                                alpha: 0.85,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Period Start / End Toggle Button
                        Builder(
                          builder: (context) {
                            // Source of truth: current cycle response from backend
                            // IF: current cycle exists AND period_start is set AND period_end is null
                            final bool isPeriodOngoing =
                                cycleData.hasData &&
                                cycleData.latestPeriodStart != null &&
                                cycleData.latestPeriodEnd == null;

                            return PeriodTrackerButton(
                              isOngoing: isPeriodOngoing,
                              // Enables the retrospective end-date correction
                              // only while a period is actually ongoing.
                              ongoingStart: isPeriodOngoing
                                  ? cycleData.latestPeriodStart
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text('Error loading cycle data: $err'),
                ),
              ),

              const SizedBox(height: 8),

              // Quick actions: the four most common next steps, always
              // visible, each a comfortable touch target.
              Text(
                'Quick actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickActionCell(
                    icon: Icons.water_drop_outlined,
                    label: 'Log period',
                    onTap: () => context.push('/logger'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCell(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    onTap: () =>
                        ref.read(homeTabIndexProvider.notifier).setIndex(1),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCell(
                    icon: Icons.note_add_outlined,
                    label: 'Add note',
                    onTap: () => context.push('/logger'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCell(
                    icon: Icons.favorite_outline,
                    label: 'Health context',
                    onTap: () => openHealthContext(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Daily Insight: one glanceable section, matching the
              // sibling section headers below.
              Text(
                'Today\'s Insight',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              const DailyInsightCard(),

              const SizedBox(height: 20),
              const _HealthContextSnippet(),

              const SizedBox(height: 12),

              // Phase 5 reproductive context: renders only when relevant
              // (pregnancy mode on, usable fertility estimate, or recorded
              // aging context). Stays out of the way otherwise.
              const ReproductiveHomeBlock(),

              const SizedBox(height: 24),

              // Section: Daily Wellness
              Text(
                'Today\'s Wellness',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              const SymptomLoggerCard(),

              const SizedBox(height: 24),

              // Section: Wearable Device
              Text(
                'MenoMate Wearable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              const DeviceTelemetryCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// One quick-action cell: icon tile plus label, sharing the card
/// language (radius-18 family, thin outline, soft shadow). Each cell is
/// an independent 48dp+ touch target with an icon *and* a text label, so
/// meaning never rests on icon or color alone.
class _QuickActionCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCell({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: MenoMateTheme.interactionColor(
                      theme.brightness == Brightness.dark,
                    ).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: MenoMateTheme.interactionColor(
                      theme.brightness == Brightness.dark,
                    ),
                    semanticLabel: label,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.25,
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

/// Health-context snippet on Home: shows user-provided context when
/// present (never diagnoses, never alters predictions), with a link to
/// the Health & Context hub. Empty state stays quiet.
class _HealthContextSnippet extends ConsumerWidget {
  const _HealthContextSnippet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final ctxAsync = ref.watch(healthContextProvider);
    return ctxAsync.maybeWhen(
      data: (state) {
        final ctx = state.dataOrNull;
        if (ctx == null ||
            (ctx.contraceptionMethod == null &&
                ctx.pregnancyContext == null &&
                (ctx.healthNotes == null || ctx.healthNotes!.trim().isEmpty))) {
          return const SizedBox.shrink();
        }
        final parts = <String>[];
        if (ctx.contraceptionMethod != null) parts.add('Contraception noted');
        if (ctx.pregnancyContext != null) parts.add('Reproductive context');
        if (ctx.healthNotes != null && ctx.healthNotes!.trim().isNotEmpty) {
          parts.add('Health notes');
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_outline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Health context: ${parts.join(' · ')}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => openHealthContext(context, ref),
                child: const Text('View'),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Calm explainer for the cycle-phase label.
Future<void> showPhaseInfoSheet(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About cycle phases',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your phase is estimated from your logged history. '
              'Phases can vary from cycle to cycle — treat them as '
              'context, not a diagnosis.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If something feels off, consider talking to a clinician you trust.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

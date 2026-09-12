import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/sync_policy.dart';
import '../../core/format.dart';
import '../../providers/profile_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/symptom_logger_card.dart';
import '../../widgets/device_telemetry_card.dart';
import '../../widgets/period_tracker_button.dart';
import '../../widgets/interactive_cycle_ring.dart';
import '../../widgets/daily_insight_card.dart';
import '../home_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(profileProvider);
    final cycleAsync = ref.watch(currentCycleProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: profileAsync.when(
          data: (profileState) {
            final profile = profileState.dataOrNull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${profile?.name ?? "MenoMate User"}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Welcome to your cycle companion',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
          loading: () => Text(
            'MenoMate',
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          error: (_, _) => Text(
            'MenoMate',
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
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
                        borderRadius: BorderRadius.circular(20),
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
                        borderRadius: BorderRadius.circular(20),
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
                  String nextPeriodMain = 'Log cycles to calculate prediction';
                  String? nextPeriodSuffix;
                  if (cycleData.predictedNextPeriod != null) {
                    final nextDateStr = DateFormat('MMM d').format(cycleData.predictedNextPeriod!);
                    final daysLeft = cycleData.daysUntilNextPeriod;
                    final status = cycleData.predictionStatus;
                    final conf = cycleData.predictionConfidence;
                    if (daysLeft == null) {
                      nextPeriodMain = 'Expected around $nextDateStr';
                      nextPeriodSuffix = '$conf confidence';
                    } else if (status == 'awaiting_next_start') {
                      nextPeriodMain =
                          'Expected around $nextDateStr — Log your next period when it starts';
                    } else if (daysLeft <= 0 || status == 'today') {
                      // Backend clamps passed predictions to 0; treat as today/expected.
                      nextPeriodMain = 'Next period: $nextDateStr (today)';
                      nextPeriodSuffix = '$conf confidence';
                    } else {
                      nextPeriodMain =
                          'Next period: $nextDateStr (in ~$daysLeft days)';
                      nextPeriodSuffix = '$conf confidence';
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
                      final startDay =
                          DateTime(start.year, start.month, start.day);
                      final endDay = DateTime(end.year, end.month, end.day);
                      final days = endDay.difference(startDay).inDays + 1;
                      periodStatus =
                          'Period ended ${DateFormat('MMM d').format(endDay)} · ${formatDayCount(days, 'day')}';
                    }
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        SyncStatusChip(state: cycleState),
                        // Cycle ring: Day N + server phase stay dominant.
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveCycleRing(
                              phase: cycleData.phase,
                              currentDay: cycleData.currentCycleDay ?? 1,
                              cycleLength: cycleData.averageCycleLength ??
                                  cycleData.predictedCycleLength ??
                                  28,
                            ),
                          ],
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
                                    color: colorScheme.secondary
                                        .withValues(alpha: 0.75),
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
                              color: colorScheme.secondary
                                  .withValues(alpha: 0.85),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Quiet calendar navigation (replaces the pill button).
                        InkWell(
                          onTap: () {
                            ref.read(homeTabIndexProvider.notifier).setIndex(2);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 15,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Calendar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Period Start / End Toggle Button
                        Builder(
                          builder: (context) {
                            // Source of truth: current cycle response from backend
                            // IF: current cycle exists AND period_start is set AND period_end is null
                            final bool isPeriodOngoing = cycleData.hasData &&
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Error loading cycle data: $err'),
                ),
              ),

              const SizedBox(height: 20),

              // Daily Insight Card
              const DailyInsightCard(),

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

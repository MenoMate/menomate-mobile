import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/profile_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/symptom_logger_card.dart';
import '../../widgets/device_telemetry_card.dart';
import '../../widgets/period_tracker_button.dart';
import '../../widgets/interactive_cycle_ring.dart';
import '../../widgets/daily_insight_card.dart';
import '../../widgets/pulsing_therapy_fab.dart';
import '../home_screen.dart';
import 'assistant_tab.dart';

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
          data: (profile) => Column(
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
          ),
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
                data: (cycleData) {
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

                  // Predict text
                  String nextPeriodInfo = 'Log cycles to calculate prediction';
                  if (cycleData.predictedNextPeriod != null) {
                    final nextDateStr = DateFormat('MMM d').format(cycleData.predictedNextPeriod!);
                    final daysDiff = cycleData.predictedNextPeriod!.difference(DateTime.now()).inDays;
                    final daysText = daysDiff > 0
                        ? 'in ~$daysDiff days'
                        : (daysDiff == 0 ? 'today' : '$daysDiff days ago');
                    final conf = cycleData.predictionConfidence;
                    nextPeriodInfo = 'Next period: $nextDateStr ($daysText) · $conf confidence';
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
                        // Interactive Cycle Ring (tap opens calendar)
                        GestureDetector(
                          onTap: () {
                            ref.read(homeTabIndexProvider.notifier).setIndex(2);
                          },
                          child: Stack(
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
                        ),
                        const SizedBox(height: 12),

                        // Subtitle with next period info
                        Text(
                          nextPeriodInfo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // View Calendar Button
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(homeTabIndexProvider.notifier).setIndex(2);
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: const Text('View Calendar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),

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

              // Section: Quick Care
              Text(
                'Quick Care',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickCareRow(context, ref),

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
      floatingActionButton: const PulsingTherapyFab(),
    );
  }

  Widget _buildQuickCareRow(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildCareChip(
          context,
          icon: Icons.healing_rounded,
          label: 'Pain Help',
          onTap: () {
            ref.read(careInitialPromptProvider.notifier).setPrompt(const CarePromptData(
              'Help with my current pain',
              'pain_help',
            ));
            ref.read(homeTabIndexProvider.notifier).setIndex(1);
          },
          colorScheme: colorScheme,
        ),
        _buildCareChip(
          context,
          icon: Icons.insights_rounded,
          label: 'Cycle Insight',
          onTap: () {
            ref.read(careInitialPromptProvider.notifier).setPrompt(const CarePromptData(
              'What\'s happening today in my cycle?',
              'cycle_insight',
            ));
            ref.read(homeTabIndexProvider.notifier).setIndex(1);
          },
          colorScheme: colorScheme,
        ),
        _buildCareChip(
          context,
          icon: Icons.history_rounded,
          label: 'What Helped Before?',
          onTap: () {
            ref.read(careInitialPromptProvider.notifier).setPrompt(const CarePromptData(
              'What therapy setting usually worked well for me?',
              'therapy_recommendation',
            ));
            ref.read(homeTabIndexProvider.notifier).setIndex(1);
          },
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildCareChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

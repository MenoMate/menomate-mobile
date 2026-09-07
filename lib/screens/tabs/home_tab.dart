import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/cycle_phase_card.dart';
import '../../widgets/symptom_logger_card.dart';
import '../../widgets/device_telemetry_card.dart';
import '../../widgets/period_tracker_button.dart';
import '../../widgets/interactive_cycle_ring.dart';
import '../../widgets/daily_insight_card.dart';
import '../../widgets/pulsing_therapy_fab.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final cycleAsync = ref.watch(currentCycleProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: profileAsync.when(
          data: (profile) => Text(
            'Hello, ${profile?.name ?? "User"}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          loading: () => Text('Loading...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          error: (_, __) => Text('MenoMate', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cycleAsync.when(
              data: (cycleData) => Column(
                children: [
                  if (cycleData != null)
                    InteractiveCycleRing(
                      phase: cycleData.phase,
                      currentDay: cycleData.currentCycleDay ?? 1,
                      cycleLength: cycleData.averageCycleLength ?? cycleData.predictedCycleLength ?? 28,
                    ),
                  if (cycleData != null)
                    const DailyInsightCard(),
                  if (cycleData == null)
                    const Text('No cycle data available'),
                  const SizedBox(height: 24),
                  PeriodTrackerButton(
                    isBleeding: cycleData?.isBleeding ?? false,
                    latestPeriodStart: cycleData?.latestPeriodStart,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading cycle data: $err')),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const SymptomLoggerCard(),
            const SizedBox(height: 16),
            const DeviceTelemetryCard(),
          ],
        ),
      ),
      floatingActionButton: const PulsingTherapyFab(),
    );
  }
}

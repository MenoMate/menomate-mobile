import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/cycle_phase_card.dart';
import '../../widgets/symptom_logger_card.dart';
import '../../widgets/device_telemetry_card.dart';
import '../../widgets/period_tracker_button.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final cycleAsync = ref.watch(currentCycleProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: profileAsync.when(
          data: (profile) => Text(
            'Hello, ${profile?.name ?? "User"}',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          loading: () => const Text('Loading...', style: TextStyle(color: Colors.black87)),
          error: (_, __) => const Text('MenoMate', style: TextStyle(color: Colors.black87)),
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
                  CyclePhaseCard(cycleData: cycleData),
                  const SizedBox(height: 16),
                  PeriodTrackerButton(
                    isBleeding: cycleData?.isBleeding ?? false,
                    latestPeriodStart: cycleData?.latestPeriodStart,
                  ),
                ],
              ),
              loading: () => const CyclePhaseCard(cycleData: null, isLoading: true),
              error: (err, _) => CyclePhaseCard(cycleData: null, error: err.toString()),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const SymptomLoggerCard(),
            const SizedBox(height: 16),
            const DeviceTelemetryCard(),
          ],
        ),
      ),
    );
  }
}

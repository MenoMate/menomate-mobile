import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../data/repositories/reproductive_repository.dart';
import '../data/sync_policy.dart';
import '../models/cycle.dart';
import '../models/daily_log.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/reproductive_providers.dart';

/// Dedicated Day Detail experience.
///
/// Shows ONLY data the backend/local store actually has for [isoDate]:
/// period/log facts, symptoms, mood/flow/discharge/notes, and cycle
/// context (today-only day-index/phase from served values). Empty dates
/// render an honest empty state with logging actions — never invented
/// phase, prediction, or fertile-window content.
class CalendarDayDetailScreen extends ConsumerWidget {
  /// ISO `YYYY-MM-DD`. Empty/invalid renders an error state.
  final String isoDate;

  const CalendarDayDetailScreen({super.key, required this.isoDate});

  DateTime? get _date {
    try {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(isoDate)) return null;
      return DateTime.parse(isoDate);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = _date;
    if (date == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Day detail')),
        body: const Center(child: Text('Invalid date.')),
      );
    }
    final check = DateTime(date.year, date.month, date.day);
    final cyclesAsync = ref.watch(cycleListProvider);
    final currentAsync = ref.watch(currentCycleProvider);
    final cycles = cyclesAsync.value?.dataOrNull;
    final current = currentAsync.value?.dataOrNull;
    // Pregnancy suppression: future menstrual predictions are withheld
    // while pregnancy mode is active. Logged history is unaffected.
    final pregnancyActive =
        ref.watch(pregnancyProvider).value?.dataOrNull?.isActive == true;

    final isPeriod = _isPeriodDay(check, cycles, current);
    final isPredicted = _isPredictedDay(
      check,
      cycles,
      current,
      isPeriod,
      pregnancyActive: pregnancyActive,
    );

    String status = 'Non-bleeding day';
    Color statusColor = colorScheme.secondary;
    IconData statusIcon = Icons.circle_outlined;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (isPeriod) {
      status = check.isAfter(today) ? 'Logged period' : 'Period active';
      statusColor = colorScheme.primary;
      statusIcon = Icons.water_drop_outlined;
    } else if (isPredicted) {
      status = 'Predicted span';
      statusColor = colorScheme.tertiary;
      statusIcon = Icons.auto_awesome_outlined;
    }

    String? cycleContext;
    if (current != null && _isSameDay(now, check)) {
      final phase = formatPhaseLabel(current.phase);
      final day = current.currentCycleDay;
      cycleContext = day == null ? phase : 'Day $day · $phase';
    }

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('MMM d, yyyy').format(check))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(check),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (cycleContext != null) ...[
              const SizedBox(height: 6),
              Text(cycleContext, style: const TextStyle(fontSize: 13)),
            ],
            if (isPredicted && !isPeriod) ...[
              const SizedBox(height: 8),
              Text(
                'Estimated from your history — not a confirmed log.',
                style: TextStyle(fontSize: 12, color: colorScheme.secondary),
              ),
            ],
            const SizedBox(height: 16),
            FutureBuilder<DataState<DailyLogResponse?>>(
              future: () async {
                final userId = ref.read(currentUserIdProvider);
                if (userId == null) {
                  return const Unavailable<DailyLogResponse?>('Signed out.');
                }
                final repo = ref.read(dailyLogRepositoryProvider);
                final offline = ref.read(isOfflineTrackingProvider);
                try {
                  return offline
                      ? await repo.loadLogLocal(userId, isoDate)
                      : await repo.loadLog(userId, isoDate);
                } catch (_) {
                  return const Unavailable<DailyLogResponse?>(
                    'Couldn\'t load this log.',
                  );
                }
              }(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final logState = snapshot.data!;
                if (logState is Unavailable<DailyLogResponse?>) {
                  return Text(
                    'Couldn\u2019t load the wellness log. Check your connection.',
                    style: TextStyle(color: colorScheme.secondary),
                  );
                }
                final log = logState.dataOrNull;
                if (log == null) {
                  return _EmptyLogCard(isoDate: isoDate);
                }
                return _LogCard(
                  pain: log.pain,
                  moods: log.mood ?? const [],
                  flow: log.flow,
                  discharge: log.discharge,
                  notes: log.notes,
                  symptoms: log.symptoms,
                );
              },
            ),
            const SizedBox(height: 16),
            _FertilitySignsCard(isoDate: isoDate),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/logger?date=$isoDate'),
                icon: const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Edit entry'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/logger?date=$isoDate'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add more'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPeriodDay(
    DateTime check,
    List<CycleResponse>? cycles,
    CurrentCycleResponse? current,
  ) {
    if (cycles == null) return false;
    for (final c in cycles) {
      final start = DateTime(
        c.periodStart.year,
        c.periodStart.month,
        c.periodStart.day,
      );
      final end = c.periodEnd != null
          ? DateTime(c.periodEnd!.year, c.periodEnd!.month, c.periodEnd!.day)
          : (current?.isBleeding == true ? DateTime.now() : start);
      final endDay = DateTime(end.year, end.month, end.day);
      if (!check.isBefore(start) && !check.isAfter(endDay)) return true;
    }
    return false;
  }

  bool _isPredictedDay(
    DateTime check,
    List<CycleResponse>? cycles,
    CurrentCycleResponse? current,
    bool alreadyPeriod, {
    bool pregnancyActive = false,
  }) {
    if (pregnancyActive) return false;
    if (alreadyPeriod) return false;
    if (current?.predictedNextPeriod == null) return false;
    final p = current!.predictedNextPeriod!;
    final start = DateTime(p.year, p.month, p.day);
    final avgLen = current.averagePeriodLength;
    if (avgLen == null) return false;
    final end = start.add(Duration(days: avgLen - 1));
    return !check.isBefore(start) && !check.isAfter(end);
  }
}

/// Fertility signs recorded for this day (Phase 2 observations), if any.
/// Observations are user-measured facts shown verbatim; an empty day shows
/// a quiet logging prompt instead of invented content.
class _FertilitySignsCard extends ConsumerWidget {
  final String isoDate;

  const _FertilitySignsCard({required this.isoDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final observationsAsync = ref.watch(observationsProvider);
    final observations = observationsAsync.value?.dataOrNull;
    final forDay = observations == null
        ? null
        : filterObservations(observations, observationDate: isoDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fertility signs',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (forDay == null)
            Text(
              'Couldn\u2019t load fertility signs.',
              style: TextStyle(fontSize: 12, color: scheme.secondary),
            )
          else if (forDay.isEmpty)
            Text(
              'None recorded for this day.',
              style: TextStyle(fontSize: 12, color: scheme.secondary),
            )
          else
            for (final o in forDay)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${o.typeLabel}: ${o.valueLabel}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/fertility-log?date=$isoDate'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Log fertility signs'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLogCard extends StatelessWidget {
  final String isoDate;
  const _EmptyLogCard({required this.isoDate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No wellness log for this day yet.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Logged data appears here. Nothing is estimated.',
            style: TextStyle(fontSize: 12, color: scheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final int? pain;
  final List<String> moods;
  final String? flow;
  final String? discharge;
  final String? notes;
  final List<SymptomItem> symptoms;

  const _LogCard({
    required this.pain,
    required this.moods,
    required this.flow,
    required this.discharge,
    required this.notes,
    required this.symptoms,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logged data',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (flow != null) _row(Icons.water_drop_outlined, 'Flow', flow!),
          if (pain != null) _row(Icons.speed_outlined, 'Pain', '$pain / 10'),
          if (moods.isNotEmpty)
            _row(Icons.mood_outlined, 'Mood', moods.join(', ')),
          if (discharge != null)
            _row(Icons.opacity_outlined, 'Discharge', discharge!),
          if (symptoms.isNotEmpty)
            _row(
              Icons.healing_outlined,
              'Symptoms',
              symptoms.map((s) => s.symptomType).join(', '),
            ),
          if (notes != null && notes!.trim().isNotEmpty)
            _row(Icons.note_outlined, 'Notes', notes!.trim()),
          if (flow == null &&
              pain == null &&
              moods.isEmpty &&
              discharge == null &&
              symptoms.isEmpty &&
              (notes == null || notes!.trim().isEmpty))
            Text(
              'Empty entry.',
              style: TextStyle(fontSize: 12, color: scheme.secondary),
            ),
          const SizedBox(height: 8),
          const SyncStatusChipPlaceholder(),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusChipPlaceholder extends StatelessWidget {
  const SyncStatusChipPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

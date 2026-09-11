import 'package:dio/dio.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/daily_log.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/models/summary.dart';
import 'package:menomate_mobile/services/api_service.dart';

/// In-memory fake of the backend contract for offline/sync tests.
/// Mirrors server idempotency semantics: duplicate period_start is a
/// 400/409-style [Conflict]; daily-log upsert converges by log_date.
class FakeApiService extends ApiService {
  FakeApiService() : super(Dio());

  bool offline = false;
  final List<CycleResponse> serverCycles = [];
  final Map<String, DailyLogResponse> serverLogs = {};
  Profile serverProfile = Profile(
    userId: 'user-a',
    name: 'Test User',
    usualCycleDays: 28,
    usualPeriodDays: 5,
    theme: 'light',
    units: 'metric',
  );

  int createCycleCalls = 0;
  int patchCycleCalls = 0;
  int upsertLogCalls = 0;
  int patchProfileCalls = 0;

  /// Forces [Conflict] from createCycle for these period_start values.
  final Set<String> conflictStarts = {};

  int _nextCycleId = 100;
  int _nextLogId = 200;

  void _guard() {
    if (offline) throw const NetworkUnavailable('offline (fake)');
  }

  @override
  Future<Profile> fetchProfile() async {
    _guard();
    return serverProfile;
  }

  @override
  Future<Profile> patchProfile(Map<String, dynamic> payload) async {
    _guard();
    patchProfileCalls++;
    serverProfile = Profile(
      userId: serverProfile.userId,
      name: payload.containsKey('name')
          ? payload['name'] as String?
          : serverProfile.name,
      usualCycleDays: payload.containsKey('usual_cycle_days')
          ? payload['usual_cycle_days'] as int?
          : serverProfile.usualCycleDays,
      usualPeriodDays: payload.containsKey('usual_period_days')
          ? payload['usual_period_days'] as int?
          : serverProfile.usualPeriodDays,
      theme: payload.containsKey('theme')
          ? payload['theme'] as String?
          : serverProfile.theme,
      units: payload.containsKey('units')
          ? payload['units'] as String?
          : serverProfile.units,
    );
    return serverProfile;
  }

  @override
  Future<List<CycleResponse>> fetchCycles() async {
    _guard();
    return List.of(serverCycles);
  }

  @override
  Future<CycleResponse> createCycle({
    required String periodStart,
    String? periodEnd,
  }) async {
    _guard();
    createCycleCalls++;
    if (conflictStarts.contains(periodStart) ||
        serverCycles.any((c) =>
            _iso(c.periodStart) == periodStart)) {
      throw Conflict('A period starting on $periodStart already exists.');
    }
    final now = DateTime.now();
    final row = CycleResponse(
      id: _nextCycleId++,
      userId: 'user-a',
      periodStart: DateTime.parse(periodStart),
      periodEnd: periodEnd == null ? null : DateTime.parse(periodEnd),
      periodLengthDays: periodEnd == null
          ? null
          : DateTime.parse(periodEnd)
                  .difference(DateTime.parse(periodStart))
                  .inDays +
              1,
      createdAt: now,
      updatedAt: now,
    );
    serverCycles.add(row);
    return row;
  }

  @override
  Future<CycleResponse> patchCycle(
    int serverId, {
    String? periodStart,
    String? periodEnd,
  }) async {
    _guard();
    patchCycleCalls++;
    final i = serverCycles.indexWhere((c) => c.id == serverId);
    if (i < 0) throw const Conflict('Cycle period not found');
    final old = serverCycles[i];
    final now = DateTime.now();
    final row = CycleResponse(
      id: old.id,
      userId: old.userId,
      periodStart:
          periodStart == null ? old.periodStart : DateTime.parse(periodStart),
      periodEnd:
          periodEnd == null ? old.periodEnd : DateTime.parse(periodEnd),
      periodLengthDays: old.periodLengthDays,
      createdAt: old.createdAt,
      updatedAt: now,
    );
    serverCycles[i] = row;
    return row;
  }

  @override
  Future<CycleResponse> endOngoingCycle(String dateString) async {
    _guard();
    final i = serverCycles.lastIndexWhere((c) => c.periodEnd == null);
    if (i < 0) throw const Conflict('No active ongoing period found.');
    final old = serverCycles[i];
    final row = CycleResponse(
      id: old.id,
      userId: old.userId,
      periodStart: old.periodStart,
      periodEnd: DateTime.parse(dateString),
      periodLengthDays: DateTime.parse(dateString)
              .difference(old.periodStart)
              .inDays +
          1,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    serverCycles[i] = row;
    return row;
  }

  @override
  Future<DailyLogResponse?> fetchDailyLog(String date) async {
    _guard();
    return serverLogs[date];
  }

  @override
  Future<DailyLogResponse> upsertDailyLog(DailyLogCreate payload) async {
    _guard();
    upsertLogCalls++;
    final date = payload.logDate ?? '2026-01-01';
    final existing = serverLogs[date];
    final row = DailyLogResponse(
      id: existing?.id ?? _nextLogId++,
      userId: 'user-a',
      logDate: date,
      pain: payload.pain,
      mood: payload.mood,
      discharge: payload.discharge,
      flow: payload.flow,
      notes: payload.notes,
      symptoms: List.of(payload.symptoms),
    );
    serverLogs[date] = row;
    return row;
  }

  @override
  Future<CurrentCycleResponse> fetchCurrentCycle() async {
    _guard();
    if (serverCycles.isEmpty) {
      return CurrentCycleResponse(
        hasData: false,
        phase: 'unknown',
        isBleeding: false,
        predictionConfidence: 'insufficient_data',
      );
    }
    return CurrentCycleResponse(
      hasData: true,
      currentCycleDay: 5,
      phase: 'follicular',
      isBleeding: false,
      predictedCycleLength: 28,
      predictedNextPeriod: DateTime(2026, 10, 1),
      daysUntilNextPeriod: 10,
      predictionStatus: 'upcoming',
      predictionConfidence: 'moderate',
      predictionSource: 'history',
      averageCycleLength: 28,
      averagePeriodLength: 5,
    );
  }

  @override
  Future<HistorySummaryResponse> fetchCycleHistory() async {
    _guard();
    final sorted = List.of(serverCycles)
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
    final entries = <HistoryPeriodEntry>[];
    for (var i = 0; i < sorted.length; i++) {
      final c = sorted[i];
      entries.add(HistoryPeriodEntry(
        id: c.id,
        periodStart: c.periodStart,
        periodEnd: c.periodEnd,
        periodLengthDays: c.periodLengthDays,
        cycleLengthDays: i < sorted.length - 1
            ? sorted[i + 1]
                .periodStart
                .difference(c.periodStart)
                .inDays
            : null,
      ));
    }
    return HistorySummaryResponse(
      totalPeriodsLogged: sorted.length,
      averageCycleLength: 28.0,
      averagePeriodLength: 5.0,
      history: entries.reversed.toList(),
      symptomFrequencies: const {},
    );
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

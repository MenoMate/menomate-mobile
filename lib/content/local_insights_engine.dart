import '../data/app_database.dart' show isoDayDifference, parseIsoDate, toIsoDate;
import '../models/cycle.dart';
import '../models/daily_log.dart';

/// Shared local analytics contract (parity-tested against backend `pattern_engine.py`).
///
/// Strict rules:
/// - Missing logs or null pain values are NEVER imputed as 0 or symptom-free.
/// - Observed cycle lengths = start-to-start intervals between observed starts
///   filtered to 15..90 days (mirrors `calculate_cycle_lengths`).
/// - Period durations = `period_end - period_start + 1` for ended periods only.
/// - Tracking coverage starts from the user's actual earliest tracking date
///   within the 90-day window.
class LocalPatternSummary {
  final List<int> observedCycleLengths;
  final List<int> recordedPeriodLengths;
  final List<({String date, int pain})> painSeries;
  final List<({String symptom, int count, double? avgSeverity})> symptomStats;
  final Map<String, Map<String, int>> symptomByCycleBucket;
  final Map<String, int> moodCounts;
  final ({
    int currentDay,
    double? currentPainAvg,
    double? previousPainAvg,
    int currentLogCount,
    int previousLogCount,
  })? cycleComparison;
  final int loggedDays;
  final int effectiveWindowDays;
  final double coverageRatio;
  final int painLoggedDays;
  final int explicitZeroPainDays;
  final int unratedSymptomCount;

  const LocalPatternSummary({
    required this.observedCycleLengths,
    required this.recordedPeriodLengths,
    required this.painSeries,
    required this.symptomStats,
    required this.symptomByCycleBucket,
    required this.moodCounts,
    required this.cycleComparison,
    required this.loggedDays,
    required this.effectiveWindowDays,
    required this.coverageRatio,
    required this.painLoggedDays,
    required this.explicitZeroPainDays,
    required this.unratedSymptomCount,
  });
}

String cycleDayBucketFor(int cycleDay) {
  if (cycleDay <= 2) return 'Days 1-2';
  if (cycleDay <= 5) return 'Days 3-5';
  if (cycleDay <= 12) return 'Days 6-12';
  if (cycleDay <= 16) return 'Days 13-16';
  return 'Days 17+';
}

LocalPatternSummary computeLocalPatterns({
  required List<CycleResponse> cycles,
  required List<DailyLogResponse> logs,
  required DateTime today,
  int windowDays = 90,
}) {
  final todayIsoStr = toIsoDate(today);
  final observedCycles = cycles
      .where((c) => toIsoDate(c.periodStart).compareTo(todayIsoStr) <= 0)
      .toList()
    ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

  // Start-to-start cycle lengths (15..90 days)
  final cycleLengths = <int>[];
  for (var i = 0; i < observedCycles.length - 1; i++) {
    final delta = isoDayDifference(
      toIsoDate(observedCycles[i].periodStart),
      toIsoDate(observedCycles[i + 1].periodStart),
    );
    if (delta >= 15 && delta <= 90) {
      cycleLengths.add(delta);
    }
  }

  // Recorded period durations (ended periods only)
  final periodLengths = <int>[
    for (final c in observedCycles)
      if (c.periodLengthDays != null) c.periodLengthDays!,
  ];

  final cutoff = DateTime(today.year, today.month, today.day - (windowDays - 1));
  final cutoffIso = toIsoDate(cutoff);
  final windowLogs = logs
      .where(
        (l) =>
            l.logDate.compareTo(cutoffIso) >= 0 &&
            l.logDate.compareTo(todayIsoStr) <= 0,
      )
      .toList()
    ..sort((a, b) => a.logDate.compareTo(b.logDate));

  // Effective tracking window from actual earliest record in [cutoff, today]
  final candidateStarts = <String>[
    for (final c in observedCycles)
      if (toIsoDate(c.periodStart).compareTo(cutoffIso) >= 0)
        toIsoDate(c.periodStart),
    for (final l in windowLogs) l.logDate,
  ];
  var effectiveWindowDays = 0;
  if (candidateStarts.isNotEmpty) {
    candidateStarts.sort();
    final actualStart = candidateStarts.first;
    final span = isoDayDifference(actualStart, todayIsoStr) + 1;
    effectiveWindowDays = span.clamp(1, windowDays);
  }

  final coverageRatio = effectiveWindowDays > 0
      ? double.parse(
          (windowLogs.length / effectiveWindowDays).toStringAsFixed(2),
        )
      : 0.0;

  final painSeries = <({String date, int pain})>[];
  var explicitZeroPainDays = 0;
  var unratedSymptomCount = 0;
  final symCounts = <String, int>{};
  final symSevs = <String, List<int>>{};
  final moodCounts = <String, int>{};
  final heatmap = <String, Map<String, int>>{};

  int? cycleDayForIso(String logIso) {
    if (observedCycles.isEmpty) return null;
    CycleResponse? matched;
    for (final c in observedCycles) {
      if (toIsoDate(c.periodStart).compareTo(logIso) <= 0) {
        matched = c;
      } else {
        break;
      }
    }
    if (matched == null) return null;
    return isoDayDifference(toIsoDate(matched.periodStart), logIso) + 1;
  }

  for (final l in windowLogs) {
    if (l.pain != null) {
      painSeries.add((date: l.logDate, pain: l.pain!));
      if (l.pain == 0) explicitZeroPainDays++;
    }
    for (final m in l.mood ?? const <String>[]) {
      moodCounts[m] = (moodCounts[m] ?? 0) + 1;
    }
    final cDay = cycleDayForIso(l.logDate);
    final bucket = cDay != null ? cycleDayBucketFor(cDay) : null;
    for (final s in l.symptoms) {
      symCounts[s.symptomType] = (symCounts[s.symptomType] ?? 0) + 1;
      if (s.severity > 0) {
        symSevs.putIfAbsent(s.symptomType, () => []).add(s.severity);
      } else {
        unratedSymptomCount++;
      }
      if (bucket != null) {
        heatmap.putIfAbsent(s.symptomType, () => {});
        heatmap[s.symptomType]![bucket] =
            (heatmap[s.symptomType]![bucket] ?? 0) + 1;
      }
    }
  }

  final sortedSyms = symCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final symptomStats = [
    for (final e in sortedSyms)
      (
        symptom: e.key,
        count: e.value,
        avgSeverity: symSevs[e.key] != null && symSevs[e.key]!.isNotEmpty
            ? double.parse(
                (symSevs[e.key]!.reduce((a, b) => a + b) /
                        symSevs[e.key]!.length)
                    .toStringAsFixed(1),
              )
            : null,
      ),
  ];

  // Current vs previous cycle comparison at the same cycle day (1..currentDay)
  ({
    int currentDay,
    double? currentPainAvg,
    double? previousPainAvg,
    int currentLogCount,
    int previousLogCount,
  })? comparison;
  if (observedCycles.length >= 2) {
    final curStart = toIsoDate(observedCycles.last.periodStart);
    final prevStart = toIsoDate(observedCycles[observedCycles.length - 2].periodStart);
    final curDay = isoDayDifference(curStart, todayIsoStr) + 1;
    if (curDay >= 1) {
      final prevCutoffDate = parseIsoDate(prevStart);
      final prevEndIso = toIsoDate(
        DateTime(
          prevCutoffDate.year,
          prevCutoffDate.month,
          prevCutoffDate.day + curDay - 1,
        ),
      );
      final curLogs = logs
          .where(
            (l) =>
                l.logDate.compareTo(curStart) >= 0 &&
                l.logDate.compareTo(todayIsoStr) <= 0,
          )
          .toList();
      final prevLogs = logs
          .where(
            (l) =>
                l.logDate.compareTo(prevStart) >= 0 &&
                l.logDate.compareTo(prevEndIso) <= 0 &&
                l.logDate.compareTo(curStart) < 0,
          )
          .toList();
      final curPains = [for (final l in curLogs) if (l.pain != null) l.pain!];
      final prevPains = [for (final l in prevLogs) if (l.pain != null) l.pain!];
      comparison = (
        currentDay: curDay,
        currentPainAvg: curPains.isNotEmpty
            ? double.parse(
                (curPains.reduce((a, b) => a + b) / curPains.length)
                    .toStringAsFixed(1),
              )
            : null,
        previousPainAvg: prevPains.isNotEmpty
            ? double.parse(
                (prevPains.reduce((a, b) => a + b) / prevPains.length)
                    .toStringAsFixed(1),
              )
            : null,
        currentLogCount: curLogs.length,
        previousLogCount: prevLogs.length,
      );
    }
  }

  return LocalPatternSummary(
    observedCycleLengths: cycleLengths.take(6).toList(),
    recordedPeriodLengths: periodLengths.take(6).toList(),
    painSeries: painSeries,
    symptomStats: symptomStats,
    symptomByCycleBucket: heatmap,
    moodCounts: moodCounts,
    cycleComparison: comparison,
    loggedDays: windowLogs.length,
    effectiveWindowDays: effectiveWindowDays,
    coverageRatio: coverageRatio,
    painLoggedDays: painSeries.length,
    explicitZeroPainDays: explicitZeroPainDays,
    unratedSymptomCount: unratedSymptomCount,
  );
}

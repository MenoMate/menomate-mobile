class HistoryPeriodEntry {
  final int id;
  final DateTime periodStart;
  final DateTime? periodEnd;
  final int? periodLengthDays;
  final int? cycleLengthDays;

  HistoryPeriodEntry({
    required this.id,
    required this.periodStart,
    this.periodEnd,
    this.periodLengthDays,
    this.cycleLengthDays,
  });

  factory HistoryPeriodEntry.fromJson(Map<String, dynamic> json) {
    return HistoryPeriodEntry(
      id: json['id'] as int,
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : null,
      periodLengthDays: json['period_length_days'] as int?,
      cycleLengthDays: json['cycle_length_days'] as int?,
    );
  }
}

class HistorySummaryResponse {
  final int totalPeriodsLogged;
  final double? averageCycleLength;
  final double? averagePeriodLength;
  final double? cycleVariabilityStdDev;
  final List<HistoryPeriodEntry> history;
  final Map<String, int> symptomFrequencies;

  HistorySummaryResponse({
    required this.totalPeriodsLogged,
    this.averageCycleLength,
    this.averagePeriodLength,
    this.cycleVariabilityStdDev,
    required this.history,
    required this.symptomFrequencies,
  });

  factory HistorySummaryResponse.fromJson(Map<String, dynamic> json) {
    return HistorySummaryResponse(
      totalPeriodsLogged: json['total_periods_logged'] as int,
      averageCycleLength: (json['average_cycle_length'] as num?)?.toDouble(),
      averagePeriodLength: (json['average_period_length'] as num?)?.toDouble(),
      cycleVariabilityStdDev: (json['cycle_variability_std_dev'] as num?)?.toDouble(),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryPeriodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      symptomFrequencies: (json['symptom_frequencies'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }
}

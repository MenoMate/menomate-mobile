class CurrentCycleResponse {
  final bool hasData;
  final int? currentCycleDay;
  final String phase;
  final bool isBleeding;
  final bool isOngoing;
  final int? activeCycleId;
  final DateTime? latestPeriodStart;
  final DateTime? latestPeriodEnd;
  final int? predictedCycleLength;
  final DateTime? predictedNextPeriod;
  final int? daysUntilNextPeriod;
  final String? predictionStatus;
  final String predictionConfidence;
  final String? predictionSource;
  final int? averageCycleLength;
  final int? averagePeriodLength;

  CurrentCycleResponse({
    required this.hasData,
    this.currentCycleDay,
    required this.phase,
    required this.isBleeding,
    this.isOngoing = false,
    this.activeCycleId,
    this.latestPeriodStart,
    this.latestPeriodEnd,
    this.predictedCycleLength,
    this.predictedNextPeriod,
    this.daysUntilNextPeriod,
    this.predictionStatus,
    required this.predictionConfidence,
    this.predictionSource,
    this.averageCycleLength,
    this.averagePeriodLength,
  });

  factory CurrentCycleResponse.fromJson(Map<String, dynamic> json) {
    final start = json['latest_period_start'] != null 
        ? DateTime.parse(json['latest_period_start']) 
        : null;
    final end = json['latest_period_end'] != null 
        ? DateTime.parse(json['latest_period_end']) 
        : null;
    final bool ongoing = json['is_ongoing'] as bool? ?? (start != null && end == null);

    return CurrentCycleResponse(
      hasData: json['has_data'] as bool? ?? false,
      currentCycleDay: json['current_cycle_day'] as int?,
      phase: json['phase'] as String? ?? 'Unknown',
      isBleeding: json['is_bleeding'] as bool? ?? false,
      isOngoing: ongoing,
      activeCycleId: json['active_cycle_id'] as int?,
      latestPeriodStart: start,
      latestPeriodEnd: end,
      predictedCycleLength: json['predicted_cycle_length'] as int?,
      predictedNextPeriod: json['predicted_next_period'] != null 
          ? DateTime.parse(json['predicted_next_period']) 
          : null,
      daysUntilNextPeriod: json['days_until_next_period'] as int?,
      predictionStatus: json['prediction_status'] as String?,
      predictionConfidence: json['prediction_confidence'] as String? ?? 'None',
      predictionSource: json['prediction_source'] as String?,
      averageCycleLength: json['average_cycle_length'] as int?,
      averagePeriodLength: json['average_period_length'] as int?,
    );
  }
}

class CycleResponse {
  final int id;
  final String userId;
  final DateTime periodStart;
  final DateTime? periodEnd;
  final int? periodLengthDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  CycleResponse({
    required this.id,
    required this.userId,
    required this.periodStart,
    this.periodEnd,
    this.periodLengthDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CycleResponse.fromJson(Map<String, dynamic> json) {
    return CycleResponse(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : null,
      periodLengthDays: json['period_length_days'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

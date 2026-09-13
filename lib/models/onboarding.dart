class OnboardingRequest {
  final String name;
  final String lastPeriodStart; // ISO 8601 date string 'YYYY-MM-DD'
  final String? lastPeriodEnd;
  final int? usualCycleDays;
  final int? usualPeriodDays;
  /// Device IANA timezone at onboarding time (e.g. "Asia/Kolkata").
  final String? timezone;

  OnboardingRequest({
    required this.name,
    required this.lastPeriodStart,
    this.lastPeriodEnd,
    this.usualCycleDays,
    this.usualPeriodDays,
    this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'last_period_start': lastPeriodStart,
      'last_period_end': lastPeriodEnd,
      'usual_cycle_days': usualCycleDays,
      'usual_period_days': usualPeriodDays,
      'timezone': timezone,
    };
  }
}

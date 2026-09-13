class Profile {
  final String userId;
  final String? name;
  final int? usualCycleDays;
  final int? usualPeriodDays;
  final String? theme;
  final String? units;
  /// Canonical IANA timezone identifier (e.g. "Asia/Kolkata"), null for
  /// legacy users until the device syncs it. See core/device_timezone.dart.
  final String? timezone;

  Profile({
    required this.userId,
    this.name,
    this.usualCycleDays,
    this.usualPeriodDays,
    this.theme,
    this.units,
    this.timezone,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      usualCycleDays: json['usual_cycle_days'] as int?,
      usualPeriodDays: json['usual_period_days'] as int?,
      theme: json['theme'] as String?,
      units: json['units'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'usual_cycle_days': usualCycleDays,
      'usual_period_days': usualPeriodDays,
      'theme': theme,
      'units': units,
      'timezone': timezone,
    };
  }
}

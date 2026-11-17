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

  /// Month/year precision only — the app never asks for or stores a birth
  /// day. Null pair means "not provided"; see validateBirthPair in
  /// models/health_context.dart (mirrors the backend pair contract).
  final int? birthYear;
  final int? birthMonth;

  Profile({
    required this.userId,
    this.name,
    this.usualCycleDays,
    this.usualPeriodDays,
    this.theme,
    this.units,
    this.timezone,
    this.birthYear,
    this.birthMonth,
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
      birthYear: (json['birth_year'] as num?)?.toInt(),
      birthMonth: (json['birth_month'] as num?)?.toInt(),
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
      'birth_year': birthYear,
      'birth_month': birthMonth,
    };
  }
}

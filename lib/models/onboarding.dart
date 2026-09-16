import '../models/profile.dart';

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

/// completeOnboarding response: the persisted profile plus the first-period
/// identity so the client can cache both rows locally (local-first §2.10).
class OnboardingResult {
  final Profile profile;
  final int periodId;
  final String periodStart; // ISO 'YYYY-MM-DD'
  final String? periodEnd; // ISO 'YYYY-MM-DD' or null when ongoing

  OnboardingResult({
    required this.profile,
    required this.periodId,
    required this.periodStart,
    this.periodEnd,
  });

  factory OnboardingResult.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>?;
    if (profileJson == null) {
      throw const FormatException('Onboarding response is missing profile.');
    }
    return OnboardingResult(
      profile: Profile.fromJson(profileJson),
      periodId: (json['period_id'] as num).toInt(),
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String?,
    );
  }
}

/// The user's last-period state (§2.5). "Ongoing" maps to period_end = null;
/// "Ended" requires an explicit end date. Wording describes period state —
/// never symptom/backend terminology.
enum PeriodStatus { ongoing, ended }

/// Tri-state numeric parse (§2.9): blank means intentionally unset
/// ("not sure"), digits in range are valid, anything else is an error.
/// Malformed input must NEVER silently become null.
enum OnboardingNumericState { unset, valid, invalid }

class ParsedUsualDays {
  final OnboardingNumericState state;
  final int? value;

  const ParsedUsualDays.unset()
      : state = OnboardingNumericState.unset,
        value = null;

  const ParsedUsualDays.invalid()
      : state = OnboardingNumericState.invalid,
        value = null;

  const ParsedUsualDays.valid(this.value)
      : state = OnboardingNumericState.valid;

  bool get isUnset => state == OnboardingNumericState.unset;
  bool get isValid => state == OnboardingNumericState.valid;
  bool get isInvalid => state == OnboardingNumericState.invalid;
}

ParsedUsualDays _parseUsual(String raw, int min, int max) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const ParsedUsualDays.unset();
  // Strict whole-number only: "28 days", "28.5", "abc" are all invalid.
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
    return const ParsedUsualDays.invalid();
  }
  final value = int.tryParse(trimmed);
  if (value == null || value < min || value > max) {
    return const ParsedUsualDays.invalid();
  }
  return ParsedUsualDays.valid(value);
}

/// Usual cycle length: whole days 20–45 (backend contract).
ParsedUsualDays parseUsualCycleDays(String raw) => _parseUsual(raw, 20, 45);

/// Usual period length: whole days 1–12 (backend contract).
ParsedUsualDays parseUsualPeriodDays(String raw) => _parseUsual(raw, 1, 12);

/// Maps period status to the stored end value (§2.6): switching
/// Ended → Ongoing clears any previously chosen end date.
String? resolvePeriodEndIso(PeriodStatus status, String? endIso) {
  return status == PeriodStatus.ongoing ? null : endIso;
}

/// Pure client-side validation (§2.8). Prevents obvious invalid requests
/// with immediate local feedback; the backend remains authoritative.
/// Returns field-keyed user-facing messages; empty means submittable.
Map<String, String> validateOnboardingInput({
  required String name,
  required DateTime? periodStart,
  required PeriodStatus status,
  required DateTime? periodEnd,
  required ParsedUsualDays usualCycle,
  required ParsedUsualDays usualPeriod,
  required DateTime today,
}) {
  final errors = <String, String>{};
  final todayDate = DateTime(today.year, today.month, today.day);

  if (name.trim().isEmpty) {
    errors['name'] = 'Please enter your name.';
  }

  if (periodStart == null) {
    errors['start'] = 'Please choose when your last period started.';
  } else {
    final startDate =
        DateTime(periodStart.year, periodStart.month, periodStart.day);
    if (startDate.isAfter(todayDate)) {
      errors['start'] = 'Start date can\u2019t be in the future.';
    }
  }

  if (status == PeriodStatus.ended) {
    if (periodEnd == null) {
      errors['end'] = 'Please choose when it ended, or select Ongoing.';
    } else {
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      if (endDate.isAfter(todayDate)) {
        errors['end'] = 'End date can\u2019t be in the future.';
      } else if (periodStart != null) {
        final startDate =
            DateTime(periodStart.year, periodStart.month, periodStart.day);
        if (endDate.isBefore(startDate)) {
          errors['end'] = 'End date can\u2019t be before the start date.';
        }
      }
    }
  }

  if (usualCycle.isInvalid) {
    errors['cycle'] =
        'Enter a whole number 20\u201345, or leave blank if you\u2019re not sure.';
  }
  if (usualPeriod.isInvalid) {
    errors['period'] =
        'Enter a whole number 1\u201312, or leave blank if you\u2019re not sure.';
  }
  return errors;
}

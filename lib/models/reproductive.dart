/// Phase 5 reproductive-health domain models (Flutter integration only).
///
/// Strongly typed Dart representations of the authoritative Phase 2–4
/// backend contracts in `MenoMate_core` (read-only from this repository):
///
/// - `POST/GET/PATCH/DELETE /api/v1/reproductive/observations`
/// - `GET /api/v1/reproductive/estimates`
/// - `GET/PUT/PATCH/DELETE /api/v1/reproductive/pregnancy`
/// - `GET/PUT /api/v1/reproductive/aging-context`
///
/// Rules enforced here (mirroring the backend, never replacing it):
/// - The backend remains authoritative for validation, dating, and
///   estimates. Client-side checks only prevent obviously invalid input.
/// - Flutter never calculates ovulation, fertile windows, EDDs, or
///   gestational age. These models only carry server-provided values.
/// - `estimated`, `observed`, and `clinically confirmed` provenance is kept
///   distinct (see [EstimateEvidenceSource] and pregnancy
///   `datingConfidence`). They are never collapsed into one status.
/// - No `user_id` is ever accepted from UI input as authority: create
///   payloads carry no user identity; the backend determines ownership
///   from the session.
/// - The legacy `HealthContext.pregnancyContext` selection is a separate
///   concept from Phase 3 pregnancy mode and is never reinterpreted here.
library;

/// Backend observation-type vocabulary (closed enum server-side).
class ObservationTypes {
  static const lhTest = 'lh_test';
  static const bbt = 'bbt';
  static const cervicalMucus = 'cervical_mucus';

  static const List<String> all = [lhTest, bbt, cervicalMucus];
}

/// Human-friendly labels for observation types.
const Map<String, String> kObservationTypeLabels = {
  ObservationTypes.lhTest: 'LH test',
  ObservationTypes.bbt: 'Basal body temperature',
  ObservationTypes.cervicalMucus: 'Cervical mucus',
};

/// Backend LH-result vocabulary.
class LhResults {
  static const positive = 'positive';
  static const negative = 'negative';
  static const invalid = 'invalid';

  static const List<String> all = [positive, negative, invalid];
}

const Map<String, String> kLhResultLabels = {
  LhResults.positive: 'Positive',
  LhResults.negative: 'Negative',
  LhResults.invalid: 'Invalid',
};

/// Backend cervical-mucus vocabulary.
///
/// Dedicated fertility scale, distinct from the generic daily-log
/// `discharge` symptom. The two are never conflated.
class MucusCategories {
  static const dry = 'dry';
  static const sticky = 'sticky';
  static const creamy = 'creamy';
  static const watery = 'watery';
  static const eggWhite = 'egg_white';

  static const List<String> all = [dry, sticky, creamy, watery, eggWhite];
}

const Map<String, String> kMucusCategoryLabels = {
  MucusCategories.dry: 'Dry',
  MucusCategories.sticky: 'Sticky',
  MucusCategories.creamy: 'Creamy',
  MucusCategories.watery: 'Watery',
  MucusCategories.eggWhite: 'Egg white',
};

/// Backend observation-source vocabulary.
class ObservationSources {
  static const manual = 'manual';
  static const imported = 'imported';

  static const List<String> all = [manual, imported];
}

/// Backend BBT range (Celsius). The server enforces this authoritatively;
/// the client mirrors it to prevent obviously invalid numeric input.
const double kBbtMinCelsius = 35.0;
const double kBbtMaxCelsius = 42.0;

/// Maximum length for observation notes (backend `max_length=1000`).
const int kObservationNoteMaxLength = 1000;

/// One user-measured fertility fact (OBSERVED data, never an estimate).
///
/// Exactly one value field matches [observationType]:
/// - `lh_test` → [lhResult] only
/// - `bbt` → [bbtCelsius] only
/// - `cervical_mucus` → [mucusCategory] only
class FertilityObservation {
  final int? id;
  final String? localId;
  final String userId;
  final String observationDate;
  final String observationType;
  final String? lhResult;
  final double? bbtCelsius;
  final String? mucusCategory;
  final String source;
  final String? note;

  const FertilityObservation({
    this.id,
    this.localId,
    required this.userId,
    required this.observationDate,
    required this.observationType,
    this.lhResult,
    this.bbtCelsius,
    this.mucusCategory,
    this.source = ObservationSources.manual,
    this.note,
  });

  /// Short user-facing summary of the recorded value (never a conclusion).
  String get valueLabel {
    switch (observationType) {
      case ObservationTypes.lhTest:
        return kLhResultLabels[lhResult] ?? lhResult ?? '—';
      case ObservationTypes.bbt:
        return bbtCelsius == null
            ? '—'
            : '${bbtCelsius!.toStringAsFixed(2)} °C';
      case ObservationTypes.cervicalMucus:
        return kMucusCategoryLabels[mucusCategory] ?? mucusCategory ?? '—';
      default:
        return '—';
    }
  }

  String get typeLabel =>
      kObservationTypeLabels[observationType] ?? observationType;

  factory FertilityObservation.fromJson(Map<String, dynamic> json) {
    return FertilityObservation(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String? ?? '',
      observationDate: json['observation_date'] as String? ?? '',
      observationType: json['observation_type'] as String? ?? '',
      lhResult: json['lh_result'] as String?,
      bbtCelsius: (json['bbt_celsius'] as num?)?.toDouble(),
      mucusCategory: json['mucus_category'] as String?,
      source: json['source'] as String? ?? ObservationSources.manual,
      note: json['note'] as String?,
    );
  }

  /// Create/upsert payload. Carries no `user_id`: the backend determines
  /// ownership from the authenticated session.
  Map<String, dynamic> toCreateJson() {
    return {
      'observation_date': observationDate,
      'observation_type': observationType,
      if (lhResult != null) 'lh_result': lhResult,
      if (bbtCelsius != null) 'bbt_celsius': bbtCelsius,
      if (mucusCategory != null) 'mucus_category': mucusCategory,
      'source': source,
      if (note != null) 'note': note,
    };
  }

  /// Partial-update payload. Only explicitly provided fields are sent;
  /// an explicit null note clears server-side.
  Map<String, dynamic> toUpdateJson({
    bool includeDate = false,
    bool clearNote = false,
  }) {
    return {
      if (includeDate) 'observation_date': observationDate,
      if (observationType == ObservationTypes.lhTest && lhResult != null)
        'lh_result': lhResult,
      if (observationType == ObservationTypes.bbt && bbtCelsius != null)
        'bbt_celsius': bbtCelsius,
      if (observationType == ObservationTypes.cervicalMucus &&
          mucusCategory != null)
        'mucus_category': mucusCategory,
      if (clearNote) 'note': null else if (note != null) 'note': note,
    };
  }
}

/// Mirrors the backend exactly-one-value contract plus basic input hygiene.
/// Returns a user-facing message, or null when valid. The backend remains
/// authoritative; this only prevents obviously invalid submissions.
String? validateObservationInput({
  required String observationType,
  String? lhResult,
  double? bbtCelsius,
  String? mucusCategory,
  String? note,
  String? observationDate,
}) {
  if (!ObservationTypes.all.contains(observationType)) {
    return 'Please choose what you are recording.';
  }
  if (observationDate != null &&
      !_isValidIsoDate(observationDate, allowFuture: false)) {
    return 'Observation dates can\u2019t be in the future.';
  }
  switch (observationType) {
    case ObservationTypes.lhTest:
      if (lhResult == null || !LhResults.all.contains(lhResult)) {
        return 'Please choose the LH test result.';
      }
      if (bbtCelsius != null || mucusCategory != null) {
        return 'An LH entry records only the test result.';
      }
    case ObservationTypes.bbt:
      if (bbtCelsius == null || !bbtCelsius.isFinite) {
        return 'Please enter the measured temperature in °C.';
      }
      if (bbtCelsius < kBbtMinCelsius || bbtCelsius > kBbtMaxCelsius) {
        return 'Please enter a temperature between 35.00 and 42.00 °C.';
      }
      if (lhResult != null || mucusCategory != null) {
        return 'A temperature entry records only the temperature.';
      }
    case ObservationTypes.cervicalMucus:
      if (mucusCategory == null ||
          !MucusCategories.all.contains(mucusCategory)) {
        return 'Please choose the observed mucus category.';
      }
      if (lhResult != null || bbtCelsius != null) {
        return 'A mucus entry records only the observed category.';
      }
  }
  if (note != null && note.length > kObservationNoteMaxLength) {
    return 'Please keep notes under 1000 characters.';
  }
  return null;
}

bool _isValidIsoDate(String iso, {required bool allowFuture}) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso)) return false;
  try {
    final parsed = DateTime.parse(iso);
    if (!allowFuture) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final check = DateTime(parsed.year, parsed.month, parsed.day);
      if (check.isAfter(today)) return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Server-computed fertility estimate states (closed vocabulary).
///
/// - `AVAILABLE`: estimate shown with standard estimate wording.
/// - `LOW_CONFIDENCE`: estimate withheld (null dates); cautious wording.
/// - `INSUFFICIENT_DATA`: no estimate; logging guidance.
/// - `SUPPRESSED`: no estimate; neutral copy (e.g. pregnancy mode active).
enum FertilityEstimateStatus {
  available,
  lowConfidence,
  insufficientData,
  suppressed,
}

FertilityEstimateStatus parseEstimateStatus(String? raw) {
  switch (raw) {
    case 'AVAILABLE':
      return FertilityEstimateStatus.available;
    case 'LOW_CONFIDENCE':
      return FertilityEstimateStatus.lowConfidence;
    case 'SUPPRESSED':
      return FertilityEstimateStatus.suppressed;
    case 'INSUFFICIENT_DATA':
    default:
      return FertilityEstimateStatus.insufficientData;
  }
}

/// Dominant provenance of a fertility estimate. Kept distinct: an
/// OBSERVED-anchored estimate is never presented with the authority of a
/// clinically confirmed value, and vice versa.
enum EstimateEvidenceSource { observed, estimated, clinicallyConfirmed }

EstimateEvidenceSource parseEvidenceSource(String? raw) {
  switch (raw) {
    case 'OBSERVED':
      return EstimateEvidenceSource.observed;
    case 'CLINICALLY_CONFIRMED':
      return EstimateEvidenceSource.clinicallyConfirmed;
    case 'ESTIMATED':
    default:
      return EstimateEvidenceSource.estimated;
  }
}

/// Fixed safety wording. The backend ships this disclaimer on every
/// estimate response; the client renders it (or links it) on every
/// fertile-window/ovulation surface.
const String kFertilityEstimateDisclaimer =
    'These are estimates based on the cycles and signs you\u2019ve logged. '
    'They can\u2019t confirm ovulation or guarantee fertile or infertile days. '
    'For contraception or conception planning, talk to your clinician.';

/// Server-computed, client read-only fertility estimate.
///
/// Dated fields are non-null ONLY when [status] is
/// [FertilityEstimateStatus.available]. The client never fabricates dates
/// for other states and never computes these values itself.
class FertilityEstimate {
  final String estimateDate;
  final FertilityEstimateStatus status;
  final String? estimatedOvulationDate;
  final String? fertileWindowStart;
  final String? fertileWindowEnd;
  final EstimateEvidenceSource evidenceSource;
  final Map<String, dynamic> evidence;
  final String method;
  final String methodVersion;
  final String? calculatedAt;
  final String? timezoneName;
  final String disclaimer;

  const FertilityEstimate({
    required this.estimateDate,
    required this.status,
    this.estimatedOvulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    required this.evidenceSource,
    this.evidence = const {},
    required this.method,
    required this.methodVersion,
    this.calculatedAt,
    this.timezoneName,
    this.disclaimer = kFertilityEstimateDisclaimer,
  });

  /// True only when the server provided dated estimates for display.
  /// Guards every fertile-date surface: non-AVAILABLE states never render
  /// dates, even if a payload unexpectedly carried them.
  bool get hasDates =>
      status == FertilityEstimateStatus.available &&
      estimatedOvulationDate != null &&
      fertileWindowStart != null &&
      fertileWindowEnd != null;

  factory FertilityEstimate.fromJson(Map<String, dynamic> json) {
    return FertilityEstimate(
      estimateDate: json['estimate_date'] as String? ?? '',
      status: parseEstimateStatus(json['status'] as String?),
      estimatedOvulationDate: json['estimated_ovulation_date'] as String?,
      fertileWindowStart: json['fertile_window_start'] as String?,
      fertileWindowEnd: json['fertile_window_end'] as String?,
      evidenceSource: parseEvidenceSource(json['evidence_source'] as String?),
      evidence:
          (json['evidence'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          const {},
      method: json['method'] as String? ?? '',
      methodVersion: json['method_version'] as String? ?? '',
      calculatedAt: json['calculated_at'] as String?,
      timezoneName: json['timezone_name'] as String?,
      disclaimer: json['disclaimer'] as String? ?? kFertilityEstimateDisclaimer,
    );
  }
}

/// Backend pregnancy dating-source vocabulary (closed enum server-side).
class DatingSources {
  static const lmp = 'lmp';
  static const ultrasound = 'ultrasound';
  static const clinician = 'clinician';
  static const unknown = 'unknown';

  static const List<String> all = [lmp, ultrasound, clinician, unknown];
}

/// User-friendly labels for dating sources. Technical provenance values
/// are never shown raw (e.g. `CLINICALLY_CONFIRMED` never appears in UI).
const Map<String, String> kDatingSourceLabels = {
  DatingSources.lmp: 'Last menstrual period',
  DatingSources.ultrasound: 'Ultrasound',
  DatingSources.clinician: 'Clinician-provided',
  DatingSources.unknown: 'Unknown / not specified',
};

/// Server `edd_label` values mapped to user-friendly due-date wording.
const Map<String, String> kEddLabelText = {
  'clinician_established_due_date': 'Clinician-established due date',
  'estimated_due_date': 'Estimated due date',
};

/// Maximum length for pregnancy dating notes (backend `max_length=1000`).
const int kPregnancyNoteMaxLength = 1000;

/// Explicit user-controlled pregnancy mode + server-derived dating display.
///
/// Stored dating fields are verbatim user/clinician input. Derived fields
/// (`eddStatus`, gestational age, `daysUntilDue`) are server-computed from
/// the stored basis and the user's local as-of date — Flutter renders them
/// and never calculates them.
class PregnancyContext {
  final String userId;
  final bool isActive;
  final String? datingSource;
  final String? estimatedDueDate;
  final String? lmpDate;
  final String? confirmationDate;
  final String? datingNote;
  final String eddStatus;
  final String? eddLabel;
  final String? datingConfidence;
  final int? gestationalAgeTotalDays;
  final int? gestationalAgeWeeks;
  final int? gestationalAgeDays;
  final int? daysUntilDue;
  final String? asOfDate;
  final String? timezoneName;
  final String? disclaimer;

  const PregnancyContext({
    required this.userId,
    required this.isActive,
    this.datingSource,
    this.estimatedDueDate,
    this.lmpDate,
    this.confirmationDate,
    this.datingNote,
    this.eddStatus = 'unavailable',
    this.eddLabel,
    this.datingConfidence,
    this.gestationalAgeTotalDays,
    this.gestationalAgeWeeks,
    this.gestationalAgeDays,
    this.daysUntilDue,
    this.asOfDate,
    this.timezoneName,
    this.disclaimer,
  });

  /// True when the record was never given dating info (explicit unknown
  /// state, never an invented EDD).
  bool get hasDating =>
      estimatedDueDate != null || lmpDate != null || datingSource != null;

  /// Gestational age is displayable only when the backend derived it.
  bool get hasGestationalAge =>
      gestationalAgeWeeks != null && gestationalAgeDays != null;

  String get datingSourceLabel =>
      kDatingSourceLabels[datingSource] ?? 'Not specified';

  String get eddLabelText => kEddLabelText[eddLabel] ?? 'Estimated due date';

  /// User-friendly provenance tier. `CLINICALLY_CONFIRMED` is converted to
  /// calm wording while preserving the underlying semantics.
  String get provenanceLabel {
    switch (datingConfidence) {
      case 'CLINICALLY_CONFIRMED':
        return 'Clinically confirmed';
      case 'ESTIMATED':
        return 'Estimated';
      case 'UNKNOWN':
      default:
        return 'Unknown';
    }
  }

  factory PregnancyContext.fromJson(String userId, Map<String, dynamic> json) {
    return PregnancyContext(
      userId: userId,
      isActive: json['is_active'] as bool? ?? false,
      datingSource: json['dating_source'] as String?,
      estimatedDueDate: json['estimated_due_date'] as String?,
      lmpDate: json['lmp_date'] as String?,
      confirmationDate: json['confirmation_date'] as String?,
      datingNote: json['dating_note'] as String?,
      eddStatus: json['edd_status'] as String? ?? 'unavailable',
      eddLabel: json['edd_label'] as String?,
      datingConfidence: json['dating_confidence'] as String?,
      gestationalAgeTotalDays: (json['gestational_age_total_days'] as num?)
          ?.toInt(),
      gestationalAgeWeeks: (json['gestational_age_weeks'] as num?)?.toInt(),
      gestationalAgeDays: (json['gestational_age_days'] as num?)?.toInt(),
      daysUntilDue: (json['days_until_due'] as num?)?.toInt(),
      asOfDate: json['as_of_date'] as String?,
      timezoneName: json['timezone_name'] as String?,
      disclaimer: json['disclaimer'] as String?,
    );
  }

  /// Full-replacement PUT payload: every dating field present (nulls
  /// included); `is_active` defaults to true when activating.
  Map<String, dynamic> toPutJson({bool isActive = true}) {
    return {
      'is_active': isActive,
      'dating_source': datingSource,
      'estimated_due_date': estimatedDueDate,
      'lmp_date': lmpDate,
      'confirmation_date': confirmationDate,
      'dating_note': datingNote,
    };
  }
}

/// Mirrors the backend joint/ordering dating rules for input hygiene.
/// Returns a user-facing message, or null when valid. The backend remains
/// authoritative (including the 409 provenance-precedence rule, which only
/// the server can evaluate against stored state).
String? validatePregnancyInput({
  String? datingSource,
  String? estimatedDueDate,
  String? lmpDate,
  String? confirmationDate,
  String? datingNote,
}) {
  if (datingSource != null && !DatingSources.all.contains(datingSource)) {
    return 'Please choose a dating source from the list.';
  }
  const knownSources = [
    DatingSources.lmp,
    DatingSources.ultrasound,
    DatingSources.clinician,
  ];
  if (estimatedDueDate != null && !knownSources.contains(datingSource)) {
    return 'A due date needs a known source: last menstrual period, ultrasound, or clinician.';
  }
  if (lmpDate != null && datingSource != DatingSources.lmp) {
    return 'A last-period date is only used with last-period dating.';
  }
  if (lmpDate != null && !_isValidIsoDate(lmpDate, allowFuture: false)) {
    return 'The last-period date can\u2019t be in the future.';
  }
  if (confirmationDate != null &&
      !_isValidIsoDate(confirmationDate, allowFuture: false)) {
    return 'The confirmation date can\u2019t be in the future.';
  }
  if (lmpDate != null &&
      estimatedDueDate != null &&
      lmpDate.compareTo(estimatedDueDate) > 0) {
    return 'The last-period date can\u2019t be after the due date.';
  }
  if (confirmationDate != null &&
      estimatedDueDate != null &&
      confirmationDate.compareTo(estimatedDueDate) > 0) {
    return 'The confirmation date can\u2019t be after the due date.';
  }
  if (datingNote != null && datingNote.length > kPregnancyNoteMaxLength) {
    return 'Please keep dating notes under 1000 characters.';
  }
  return null;
}

/// Fixed provenance label for reproductive-aging context. The only possible
/// source of the row is the owning user's explicit input — in particular,
/// `CLINICALLY_CONFIRMED` is never emitted for user-typed context.
const String kAgingProvenanceUserDeclared = 'user_declared';

/// Maximum length for aging notes (backend `max_length=2000`).
const int kAgingNoteMaxLength = 2000;

/// Explicit user-declared reproductive-aging context (free-text only).
///
/// Deliberately vocabulary-free: there is no staging enum, no diagnosis
/// column, and no detection state. The contract defines no state
/// vocabulary (no "perimenopause"/"menopause" stages), so none is invented.
class AgingContext {
  final String userId;
  final bool hasContext;
  final String? notes;
  final String provenance;
  final String? disclaimer;

  const AgingContext({
    required this.userId,
    required this.hasContext,
    this.notes,
    this.provenance = kAgingProvenanceUserDeclared,
    this.disclaimer,
  });

  factory AgingContext.fromJson(String userId, Map<String, dynamic> json) {
    final notes = json['notes'] as String?;
    return AgingContext(
      userId: userId,
      hasContext: json['has_context'] as bool? ?? notes != null,
      notes: notes,
      provenance: json['provenance'] as String? ?? kAgingProvenanceUserDeclared,
      disclaimer: json['disclaimer'] as String?,
    );
  }

  /// Full-replacement PUT payload: omitted/null notes clear the context.
  Map<String, dynamic> toPutJson() {
    return {'notes': notes};
  }
}

/// Mirrors the backend notes-length rule. Returns a user-facing message,
/// or null when valid.
String? validateAgingNotes(String? notes) {
  if (notes != null && notes.length > kAgingNoteMaxLength) {
    return 'Please keep this context under 2000 characters.';
  }
  return null;
}

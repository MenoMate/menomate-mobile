/// V1 Health Context foundation models.
///
/// Everything here is explicitly user-provided context: conditions the user
/// tells MenoMate about, medications they record, contraception and
/// pregnancy selections, and free text. Nothing is diagnosed, inferred, or
/// allowed to alter predictions — the repository and UI layers enforce that
/// boundary; these models only carry values.
///
/// Wire values match the backend contract verbatim (`ContraceptionMethodEnum`,
/// `PregnancyContextEnum`, `SUPPORTED_CONDITION_CODES`); human labels live
/// only in the maps below for display.
library;

/// Curated condition codes (backend allowlist). `other` always pairs with a
/// user-provided [HealthCondition.customLabel].
class HealthConditionCodes {
  static const pcos = 'pcos';
  static const endometriosis = 'endometriosis';
  static const uterineFibroids = 'uterine_fibroids';
  static const thyroidDisorder = 'thyroid_disorder';
  static const anemia = 'anemia';
  static const diabetes = 'diabetes';
  static const hypertension = 'hypertension';
  static const migraine = 'migraine';
  static const anxiety = 'anxiety';
  static const depression = 'depression';
  static const asthma = 'asthma';
  static const other = 'other';

  /// Display order for the curated picker.
  static const List<String> curated = [
    pcos,
    endometriosis,
    uterineFibroids,
    thyroidDisorder,
    anemia,
    diabetes,
    hypertension,
    migraine,
    anxiety,
    depression,
    asthma,
    other,
  ];
}

/// Human-friendly labels for condition codes. `other` renders with the
/// user's own custom label instead (see [conditionDisplayLabel]).
const Map<String, String> kConditionLabels = {
  HealthConditionCodes.pcos: 'PCOS',
  HealthConditionCodes.endometriosis: 'Endometriosis',
  HealthConditionCodes.uterineFibroids: 'Uterine fibroids',
  HealthConditionCodes.thyroidDisorder: 'Thyroid disorder',
  HealthConditionCodes.anemia: 'Anemia',
  HealthConditionCodes.diabetes: 'Diabetes',
  HealthConditionCodes.hypertension: 'Hypertension',
  HealthConditionCodes.migraine: 'Migraine',
  HealthConditionCodes.anxiety: 'Anxiety',
  HealthConditionCodes.depression: 'Depression',
  HealthConditionCodes.asthma: 'Asthma',
  HealthConditionCodes.other: 'Other',
};

/// Display label for a condition: the curated label, or the user's custom
/// label for `other`. Never implies detection or diagnosis.
String conditionDisplayLabel(String code, String? customLabel) {
  if (code == HealthConditionCodes.other &&
      customLabel != null &&
      customLabel.trim().isNotEmpty) {
    return customLabel.trim();
  }
  return kConditionLabels[code] ?? code;
}

/// Human-friendly labels for backend contraception method values.
const Map<String, String> kContraceptionLabels = {
  'none': 'None',
  'combined_pill': 'Combined pill',
  'progestin_only_pill': 'Progestin-only pill',
  'patch': 'Patch',
  'ring': 'Vaginal ring',
  'injection': 'Injection',
  'implant': 'Implant',
  'hormonal_iud': 'Hormonal IUD',
  'copper_iud': 'Copper IUD',
  'condoms': 'Condoms',
  'sterilization': 'Sterilization',
  'fertility_awareness': 'Fertility awareness',
  'withdrawal': 'Withdrawal',
  'other': 'Other',
  'prefer_not_to_say': 'Prefer not to say',
};

/// Human-friendly labels for backend pregnancy context values.
const Map<String, String> kPregnancyContextLabels = {
  'trying_to_conceive': 'Trying to conceive',
  'avoiding_pregnancy': 'Avoiding pregnancy',
  'pregnant': 'Pregnant',
  'postpartum': 'Postpartum',
  'not_applicable': 'Not applicable',
  'prefer_not_to_say': 'Prefer not to say',
};

/// Singleton health context: contraception / pregnancy selections plus
/// free-text notes. All fields optional; null means "not provided".
class HealthContext {
  final String userId;
  final String? contraceptionMethod;
  final String? contraceptionNote;
  final String? pregnancyContext;
  final String? healthNotes;

  const HealthContext({
    required this.userId,
    this.contraceptionMethod,
    this.contraceptionNote,
    this.pregnancyContext,
    this.healthNotes,
  });

  /// Blank context for a user with nothing stored yet.
  factory HealthContext.empty(String userId) => HealthContext(userId: userId);

  /// True when every optional field is unset (nothing to sync or adopt).
  bool get isEmpty =>
      contraceptionMethod == null &&
      contraceptionNote == null &&
      pregnancyContext == null &&
      healthNotes == null;

  factory HealthContext.fromJson(String userId, Map<String, dynamic> json) {
    return HealthContext(
      userId: userId,
      contraceptionMethod: json['contraception_method'] as String?,
      contraceptionNote: json['contraception_note'] as String?,
      pregnancyContext: json['pregnancy_context'] as String?,
      healthNotes: json['health_notes'] as String?,
    );
  }

  /// Full-replacement payload (PUT): every key present, nulls included, so
  /// omitted fields clear server-side exactly like the local row.
  Map<String, dynamic> toJson() {
    return {
      'contraception_method': contraceptionMethod,
      'contraception_note': contraceptionNote,
      'pregnancy_context': pregnancyContext,
      'health_notes': healthNotes,
    };
  }
}

/// A user-reported health condition. Presence in the list is the user's own
/// statement — never a detection or diagnosis by MenoMate.
class HealthCondition {
  final int? id;
  final String? localId;
  final String userId;
  final String code;
  final String? customLabel;
  final String? note;
  final bool isActive;

  const HealthCondition({
    this.id,
    this.localId,
    required this.userId,
    required this.code,
    this.customLabel,
    this.note,
    this.isActive = true,
  });

  String get displayLabel => conditionDisplayLabel(code, customLabel);

  factory HealthCondition.fromJson(Map<String, dynamic> json) {
    return HealthCondition(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String? ?? '',
      code: json['condition_code'] as String? ?? '',
      customLabel: json['custom_label'] as String?,
      note: json['note'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Create payload. `customLabel` must be non-null only for `other`
  /// (see [validateConditionInput]); callers omit it otherwise so the
  /// backend label contract holds.
  Map<String, dynamic> toCreateJson() {
    return {
      'condition_code': code,
      if (customLabel != null) 'custom_label': customLabel,
      if (note != null) 'note': note,
      'is_active': isActive,
    };
  }
}

/// A user-recorded medication or treatment. Names are free text and
/// duplicates are allowed by backend design; nothing is inferred from them.
class Medication {
  final int? id;
  final String? localId;
  final String userId;
  final String name;
  final String? note;
  final bool isActive;

  const Medication({
    this.id,
    this.localId,
    required this.userId,
    required this.name,
    this.note,
    this.isActive = true,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      note: json['note'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (note != null) 'note': note,
      'is_active': isActive,
    };
  }
}

/// Mirrors the backend birth-pair contract: month/year precision only, both
/// parts together or both cleared, plausible range. Returns a user-facing
/// message, or null when valid. Never computes an age.
String? validateBirthPair(int? year, int? month) {
  if (year == null && month == null) return null;
  if (year == null || month == null) {
    return 'Please provide both birth month and year, or leave both blank.';
  }
  final currentYear = DateTime.now().year;
  if (year < 1900 || year > currentYear) {
    return 'Please enter a birth year between 1900 and $currentYear.';
  }
  if (month < 1 || month > 12) {
    return 'Please enter a birth month between 1 and 12.';
  }
  return null;
}

/// Mirrors the backend other-label contract: a custom label is required
/// exactly for `other` and must be absent otherwise. Returns a user-facing
/// message, or null when valid.
String? validateConditionInput(String code, String? customLabel) {
  if (!HealthConditionCodes.curated.contains(code)) {
    return 'Please choose a condition from the list.';
  }
  final label = customLabel?.trim() ?? '';
  if (code == HealthConditionCodes.other) {
    if (label.isEmpty) {
      return 'Please add your own label for “Other”.';
    }
    if (label.length > 128) {
      return 'Please keep the custom label under 128 characters.';
    }
    return null;
  }
  if (label.isNotEmpty) {
    return 'A custom label is only needed for “Other”.';
  }
  return null;
}

/// Medication names must be non-blank (backend rejects whitespace-only).
/// Returns a user-facing message, or null when valid.
String? validateMedicationName(String name) {
  if (name.trim().isEmpty) {
    return 'Please enter a medication or treatment name.';
  }
  if (name.trim().length > 128) {
    return 'Please keep the name under 128 characters.';
  }
  return null;
}

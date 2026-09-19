/// Phase 1 adaptive-onboarding personalization model.
///
/// Two cleanly separated concepts (never one overloaded "goal"):
///
/// - [Personalization.interests]: multi-select user intents — why the user
///   is here. Any subset (including empty = skipped) is valid. These only
///   decide WHICH follow-up questions to ask and, later, which content to
///   personalize. They never change backend payloads, predictions, or modes.
/// - [Personalization.mode] + [isActuallyPregnant]: explicit tracking
///   STATE. Pregnancy mode represents an actual pregnancy and is entered
///   only through an explicit user answer — selecting the `pregnancy`
///   interest (which may mean curiosity/learning) never activates it.
///
/// Persistence is local-only (SharedPreferences via
/// `personalizationProvider`): the backend onboarding/profile contract has
/// no interests fields (see `docs/backend_gaps.md`). Nothing here is ever
/// sent to any API, used for predictions/phases, or used for diagnoses.
/// Pure Dart (no widgets, no I/O) so follow-up derivation is unit-tested.
library;

/// Canonical interest ids. Wire values for local persistence; labels are
/// UI-only and may be reworded without migrating stored data.
class UserInterests {
  static const cycleTracking = 'cycle_tracking';
  static const bodyAwareness = 'body_awareness';
  static const reproductiveLearning = 'reproductive_learning';
  static const fertilityAwareness = 'fertility_awareness';
  static const tryingToConceive = 'trying_to_conceive';
  static const pregnancy = 'pregnancy';
  static const wellness = 'wellness';

  static const List<String> all = [
    cycleTracking,
    bodyAwareness,
    reproductiveLearning,
    fertilityAwareness,
    tryingToConceive,
    pregnancy,
    wellness,
  ];
}

class UserInterest {
  final String key;
  final String label;
  final String description;

  const UserInterest(this.key, this.label, this.description);
}

/// Display order. Meaning is preserved even if wording is later refined.
const List<UserInterest> kUserInterests = [
  UserInterest(
    UserInterests.cycleTracking,
    'Track my period & cycle',
    'Period dates, cycle lengths, and history.',
  ),
  UserInterest(
    UserInterests.bodyAwareness,
    'Understand my body & symptoms',
    'Pain, mood, energy, sleep, skin, digestion.',
  ),
  UserInterest(
    UserInterests.reproductiveLearning,
    'Learn about reproductive health',
    'Calm explainers, personalized later in Learn.',
  ),
  UserInterest(
    UserInterests.fertilityAwareness,
    'Understand my fertile days',
    'Server estimates only — never calculated on your device.',
  ),
  UserInterest(
    UserInterests.tryingToConceive,
    'Try to conceive',
    'Fertility-sign tracking preferences.',
  ),
  UserInterest(
    UserInterests.pregnancy,
    'Track a pregnancy',
    'Only with an actual pregnancy — never assumed.',
  ),
  UserInterest(
    UserInterests.wellness,
    'Track my wellness & mood',
    'Everyday wellbeing alongside your cycle.',
  ),
];

String? userInterestLabel(String key) {
  for (final i in kUserInterests) {
    if (i.key == key) return i.label;
  }
  return null;
}

/// Explicit tracking state. Defaults to cycle; pregnancy is entered ONLY
/// through an explicit actual-pregnancy answer, never inferred from the
/// `pregnancy` interest, lateness, symptoms, or estimates.
enum TrackingMode { cycle, pregnancy }

/// Symptom areas for the body-awareness follow-up. Interest flags only —
/// they decide which logging shortcuts/content to surface later, and imply
/// no condition or diagnosis, ever.
class SymptomAreas {
  static const pain = 'pain';
  static const mood = 'mood';
  static const energy = 'energy';
  static const sleep = 'sleep';
  static const skin = 'skin';
  static const digestive = 'digestive';
  static const other = 'other';

  static const List<String> all = [
    pain,
    mood,
    energy,
    sleep,
    skin,
    digestive,
    other,
  ];
}

const Map<String, String> kSymptomAreaLabels = {
  SymptomAreas.pain: 'Pain & cramps',
  SymptomAreas.mood: 'Mood',
  SymptomAreas.energy: 'Energy',
  SymptomAreas.sleep: 'Sleep',
  SymptomAreas.skin: 'Skin',
  SymptomAreas.digestive: 'Digestion',
  SymptomAreas.other: 'Something else',
};

/// Fertility-sign tracking preferences for the fertility/TTC follow-up.
/// Pure preference flags: what the user wants to log. The backend remains
/// the sole estimator — selecting these never computes anything on-device.
class FertilityPrefs {
  static const lhTests = 'lh_tests';
  static const bbt = 'bbt';
  static const cervicalObservations = 'cervical_observations';

  static const List<String> all = [
    lhTests,
    bbt,
    cervicalObservations,
  ];
}

const Map<String, String> kFertilityPrefLabels = {
  FertilityPrefs.lhTests: 'LH tests',
  FertilityPrefs.bbt: 'Basal body temperature',
  FertilityPrefs.cervicalObservations: 'Cervical observations',
};

/// Log categories ("what would you like to track?"). Category flags only:
/// they decide which logging shortcuts and hints to surface later. They
/// create no medical conclusions and never change log validation.
/// LOG vs HOME separation is preserved: these are things the user records;
/// everything MenoMate interprets (cycle day, estimates, patterns) stays
/// server-computed and is never logged.
class TrackingCategories {
  static const periodFlow = 'period_flow';
  static const symptoms = 'symptoms';
  static const mood = 'mood';
  static const sleepEnergy = 'sleep_energy';
  static const discharge = 'discharge';
  static const fertilitySigns = 'fertility_signs';
  static const lifestyle = 'lifestyle';
  static const sexualWellbeing = 'sexual_wellbeing';

  static const List<String> all = [
    periodFlow,
    symptoms,
    mood,
    sleepEnergy,
    discharge,
    fertilitySigns,
    lifestyle,
    sexualWellbeing,
  ];
}

const Map<String, String> kTrackingCategoryLabels = {
  TrackingCategories.periodFlow: 'Period & flow',
  TrackingCategories.symptoms: 'Symptoms',
  TrackingCategories.mood: 'Mood',
  TrackingCategories.sleepEnergy: 'Sleep & energy',
  TrackingCategories.discharge: 'Discharge',
  TrackingCategories.fertilitySigns: 'Fertility signs',
  TrackingCategories.lifestyle: 'Lifestyle',
  TrackingCategories.sexualWellbeing: 'Sexual wellbeing',
};

/// Health concerns for personalization ("what would you like support
/// with?"). CONCERNS / INTERESTS / CONTEXT — never diagnoses. Selecting
/// one means the user wants relevant information and logging support; it
/// never implies the user has the condition, never labels them, and never
/// drives predictions, phases, or clinical claims. Deliberately separate
/// from [HealthCondition] records (real backend-supported context).
class HealthConcerns {
  static const pcos = 'concern_pcos';
  static const endometriosis = 'concern_endometriosis';
  static const fibroids = 'concern_fibroids';
  static const painfulPeriods = 'concern_painful_periods';
  static const heavyBleeding = 'concern_heavy_bleeding';
  static const irregularCycles = 'concern_irregular_cycles';
  static const hormonal = 'concern_hormonal';
  static const fertility = 'concern_fertility';

  static const List<String> all = [
    pcos,
    endometriosis,
    fibroids,
    painfulPeriods,
    heavyBleeding,
    irregularCycles,
    hormonal,
    fertility,
  ];
}

const Map<String, String> kHealthConcernLabels = {
  HealthConcerns.pcos: 'PCOS',
  HealthConcerns.endometriosis: 'Endometriosis',
  HealthConcerns.fibroids: 'Fibroids',
  HealthConcerns.painfulPeriods: 'Painful periods',
  HealthConcerns.heavyBleeding: 'Heavy bleeding',
  HealthConcerns.irregularCycles: 'Irregular cycles',
  HealthConcerns.hormonal: 'Hormonal concerns',
  HealthConcerns.fertility: 'Fertility concerns',
};

/// Local-first personalization snapshot for one tracking identity.
class Personalization {
  /// Selected interest ids (canonical keys). Empty = skipped, not "none".
  final Set<String> interests;

  /// Explicit tracking state. Never derived from interests.
  final TrackingMode mode;

  /// Body-awareness follow-up answers (canonical area keys).
  final Set<String> symptomAreas;

  /// Fertility/TTC follow-up answers (canonical pref keys).
  final Set<String> fertilityPrefs;

  /// Log categories the user wants to track (canonical category keys).
  final Set<String> trackingCategories;

  /// Health concerns for personalization (canonical concern keys).
  /// Concerns only — never diagnoses, never labels, never predictions.
  final Set<String> healthConcerns;

  /// Whether the user already tracks periods elsewhere (migration hint).
  /// Informational only; changes nothing about the flow or the payload.
  final bool tracksElsewhere;

  /// Explicit actual-pregnancy answer. Null = unasked/unanswered.
  /// Only an explicit `true` may route to pregnancy mode later.
  final bool? isActuallyPregnant;

  Personalization({
    Set<String>? interests,
    this.mode = TrackingMode.cycle,
    Set<String>? symptomAreas,
    Set<String>? fertilityPrefs,
    Set<String>? trackingCategories,
    Set<String>? healthConcerns,
    this.tracksElsewhere = false,
    this.isActuallyPregnant,
  })  : interests = Set.unmodifiable(
          (interests ?? const {}).where(UserInterests.all.contains),
        ),
        symptomAreas = Set.unmodifiable(
          (symptomAreas ?? const {}).where(SymptomAreas.all.contains),
        ),
        fertilityPrefs = Set.unmodifiable(
          (fertilityPrefs ?? const {}).where(FertilityPrefs.all.contains),
        ),
        trackingCategories = Set.unmodifiable(
          (trackingCategories ?? const {})
              .where(TrackingCategories.all.contains),
        ),
        healthConcerns = Set.unmodifiable(
          (healthConcerns ?? const {}).where(HealthConcerns.all.contains),
        );

  /// Follow-up sections to ask, derived ONLY from explicit interests.
  /// Unknown/stale keys are ignored (constructor filters them), so old
  /// stored data can never summon an unexpected question.
  bool get wantsSymptomAreas =>
      interests.contains(UserInterests.bodyAwareness);

  bool get wantsFertilityPrefs =>
      interests.contains(UserInterests.fertilityAwareness) ||
      interests.contains(UserInterests.tryingToConceive);

  /// The pregnancy STATE question (actual pregnancy?) is asked only when
  /// the user expressed pregnancy interest. Answering it is what — and the
  /// only thing that — can set [mode] to pregnancy.
  bool get wantsPregnancyState =>
      interests.contains(UserInterests.pregnancy);

  Personalization copyWith({
    Set<String>? interests,
    TrackingMode? mode,
    Set<String>? symptomAreas,
    Set<String>? fertilityPrefs,
    Set<String>? trackingCategories,
    Set<String>? healthConcerns,
    bool? tracksElsewhere,
    bool? isActuallyPregnant,
    bool clearPregnancyAnswer = false,
  }) {
    return Personalization(
      interests: interests ?? this.interests,
      mode: mode ?? this.mode,
      symptomAreas: symptomAreas ?? this.symptomAreas,
      fertilityPrefs: fertilityPrefs ?? this.fertilityPrefs,
      trackingCategories: trackingCategories ?? this.trackingCategories,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      tracksElsewhere: tracksElsewhere ?? this.tracksElsewhere,
      isActuallyPregnant: clearPregnancyAnswer
          ? null
          : (isActuallyPregnant ?? this.isActuallyPregnant),
    );
  }
}

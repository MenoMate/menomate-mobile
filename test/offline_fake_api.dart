import 'package:dio/dio.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/daily_log.dart';
import 'package:menomate_mobile/models/health_context.dart';
import 'package:menomate_mobile/models/onboarding.dart';
import 'package:menomate_mobile/models/care.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/models/reproductive.dart';
import 'package:menomate_mobile/models/summary.dart';
import 'package:menomate_mobile/services/api_service.dart';

/// In-memory fake of the backend contract for offline/sync tests.
/// Mirrors server idempotency semantics: duplicate period_start is a
/// 400/409-style [Conflict]; daily-log upsert converges by log_date.
class FakeApiService extends ApiService {
  FakeApiService() : super(Dio());

  bool offline = false;
  final List<CycleResponse> serverCycles = [];
  final Map<String, DailyLogResponse> serverLogs = {};
  Profile serverProfile = Profile(
    userId: 'user-a',
    name: 'Test User',
    usualCycleDays: 28,
    usualPeriodDays: 5,
    theme: 'light',
    units: 'metric',
  );

  int createCycleCalls = 0;
  int patchCycleCalls = 0;
  int upsertLogCalls = 0;
  int patchProfileCalls = 0;
  int completeOnboardingCalls = 0;

  /// When non-null, completeOnboarding throws this instead of succeeding.
  ApiError? onboardingFailure;

  /// Last onboarding payload received (for timezone/passthrough asserts).
  OnboardingRequest? lastOnboardingRequest;

  /// When true, a second distinct onboarding start throws Conflict (already
  /// onboarded), mirroring the backend one-time contract.
  bool enforceOnboardingOneTime = false;
  final Set<String> _onboardedStarts = {};

  /// Forces [Conflict] from createCycle for these period_start values.
  final Set<String> conflictStarts = {};

  int _nextCycleId = 100;
  int _nextLogId = 200;

  void _guard() {
    if (offline) throw const NetworkUnavailable('offline (fake)');
  }

  @override
  Future<Profile> fetchProfile() async {
    _guard();
    return serverProfile;
  }

  @override
  Future<Profile> patchProfile(Map<String, dynamic> payload) async {
    _guard();
    patchProfileCalls++;
    serverProfile = Profile(
      userId: serverProfile.userId,
      name: payload.containsKey('name')
          ? payload['name'] as String?
          : serverProfile.name,
      usualCycleDays: payload.containsKey('usual_cycle_days')
          ? payload['usual_cycle_days'] as int?
          : serverProfile.usualCycleDays,
      usualPeriodDays: payload.containsKey('usual_period_days')
          ? payload['usual_period_days'] as int?
          : serverProfile.usualPeriodDays,
      theme: payload.containsKey('theme')
          ? payload['theme'] as String?
          : serverProfile.theme,
      units: payload.containsKey('units')
          ? payload['units'] as String?
          : serverProfile.units,
      timezone: payload.containsKey('timezone')
          ? payload['timezone'] as String?
          : serverProfile.timezone,
      birthYear: payload.containsKey('birth_year')
          ? (payload['birth_year'] as num?)?.toInt()
          : serverProfile.birthYear,
      birthMonth: payload.containsKey('birth_month')
          ? (payload['birth_month'] as num?)?.toInt()
          : serverProfile.birthMonth,
    );
    return serverProfile;
  }

  @override
  Future<OnboardingResult> completeOnboarding(OnboardingRequest payload) async {
    _guard();
    completeOnboardingCalls++;
    lastOnboardingRequest = payload;
    if (onboardingFailure != null) throw onboardingFailure!;
    if (payload.name.trim().isEmpty) {
      throw const ValidationError('name must not be blank');
    }
    if (enforceOnboardingOneTime &&
        _onboardedStarts.isNotEmpty &&
        !_onboardedStarts.contains(payload.lastPeriodStart)) {
      throw const Conflict(
        'Onboarding has already been completed for this account. '
        'To add or correct period dates, use History.',
      );
    }
    _onboardedStarts.add(payload.lastPeriodStart);
    final now = DateTime.now();
    serverProfile = Profile(
      userId: serverProfile.userId,
      name: payload.name.trim(),
      usualCycleDays: payload.usualCycleDays,
      usualPeriodDays: payload.usualPeriodDays,
      theme: serverProfile.theme,
      units: serverProfile.units,
      timezone: payload.timezone ?? serverProfile.timezone,
    );
    final row = CycleResponse(
      id: _nextCycleId++,
      userId: serverProfile.userId,
      periodStart: DateTime.parse(payload.lastPeriodStart),
      periodEnd: payload.lastPeriodEnd == null
          ? null
          : DateTime.parse(payload.lastPeriodEnd!),
      periodLengthDays: null,
      createdAt: now,
      updatedAt: now,
    );
    serverCycles.removeWhere(
      (c) => _iso(c.periodStart) == payload.lastPeriodStart,
    );
    serverCycles.add(row);
    return OnboardingResult(
      profile: serverProfile,
      periodId: row.id,
      periodStart: payload.lastPeriodStart,
      periodEnd: payload.lastPeriodEnd,
    );
  }

  @override
  Future<List<CycleResponse>> fetchCycles() async {
    _guard();
    return List.of(serverCycles);
  }

  @override
  Future<CycleResponse> createCycle({
    required String periodStart,
    String? periodEnd,
  }) async {
    _guard();
    createCycleCalls++;
    if (periodEnd != null && periodEnd.compareTo(periodStart) < 0) {
      throw Conflict('period_end cannot be prior to period_start');
    }
    if (conflictStarts.contains(periodStart) ||
        serverCycles.any((c) => _iso(c.periodStart) == periodStart)) {
      throw Conflict('A period starting on $periodStart already exists.');
    }
    final now = DateTime.now();
    final row = CycleResponse(
      id: _nextCycleId++,
      userId: 'user-a',
      periodStart: DateTime.parse(periodStart),
      periodEnd: periodEnd == null ? null : DateTime.parse(periodEnd),
      periodLengthDays: periodEnd == null
          ? null
          : DateTime.parse(periodEnd)
                    .difference(DateTime.parse(periodStart))
                    .inDays +
                1,
      createdAt: now,
      updatedAt: now,
    );
    serverCycles.add(row);
    return row;
  }

  @override
  Future<CycleResponse> patchCycle(
    int serverId, {
    String? periodStart,
    String? periodEnd,
  }) async {
    _guard();
    patchCycleCalls++;
    final i = serverCycles.indexWhere((c) => c.id == serverId);
    if (i < 0) throw const Conflict('Cycle period not found');
    final old = serverCycles[i];
    final start = periodStart ?? _iso(old.periodStart);
    final oldEnd = old.periodEnd == null ? null : _iso(old.periodEnd!);
    final end = periodEnd ?? oldEnd;
    if (end != null && end.compareTo(start) < 0) {
      throw Conflict('period_end cannot be prior to period_start');
    }
    final now = DateTime.now();
    final row = CycleResponse(
      id: old.id,
      userId: old.userId,
      periodStart: periodStart == null
          ? old.periodStart
          : DateTime.parse(periodStart),
      periodEnd: periodEnd == null ? old.periodEnd : DateTime.parse(periodEnd),
      periodLengthDays: old.periodLengthDays,
      createdAt: old.createdAt,
      updatedAt: now,
    );
    serverCycles[i] = row;
    return row;
  }

  @override
  Future<CycleResponse> endOngoingCycle(String dateString) async {
    _guard();
    final i = serverCycles.lastIndexWhere((c) => c.periodEnd == null);
    if (i < 0) throw const Conflict('No active ongoing period found.');
    final old = serverCycles[i];
    final row = CycleResponse(
      id: old.id,
      userId: old.userId,
      periodStart: old.periodStart,
      periodEnd: DateTime.parse(dateString),
      periodLengthDays:
          DateTime.parse(dateString).difference(old.periodStart).inDays + 1,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    serverCycles[i] = row;
    return row;
  }

  @override
  Future<DailyLogResponse?> fetchDailyLog(String date) async {
    _guard();
    return serverLogs[date];
  }

  @override
  Future<DailyLogResponse> upsertDailyLog(DailyLogCreate payload) async {
    _guard();
    upsertLogCalls++;
    final date = payload.logDate ?? '2026-01-01';
    final existing = serverLogs[date];
    final row = DailyLogResponse(
      id: existing?.id ?? _nextLogId++,
      userId: 'user-a',
      logDate: date,
      pain: payload.pain,
      mood: payload.mood,
      discharge: payload.discharge,
      flow: payload.flow,
      notes: payload.notes,
      symptoms: List.of(payload.symptoms),
    );
    serverLogs[date] = row;
    return row;
  }

  @override
  Future<CurrentCycleResponse> fetchCurrentCycle() async {
    _guard();
    fetchCurrentCycleCalls++;
    if (serverCycles.isEmpty) {
      return CurrentCycleResponse(
        hasData: false,
        phase: 'unknown',
        isBleeding: false,
        predictionConfidence: 'insufficient_data',
      );
    }
    return CurrentCycleResponse(
      hasData: true,
      currentCycleDay: 5,
      phase: 'follicular',
      isBleeding: false,
      predictedCycleLength: 28,
      predictedNextPeriod: DateTime(2026, 10, 1),
      daysUntilNextPeriod: 10,
      predictionStatus: 'upcoming',
      predictionConfidence: 'moderate',
      predictionSource: 'history',
      averageCycleLength: 28,
      averagePeriodLength: 5,
    );
  }

  @override
  Future<CareInteractionResponse> postCareInteraction(
    CareInteractionRequest request,
  ) async {
    _guard();
    lastCareRequest = request;
    final preset = cannedCareResponse;
    if (preset != null) return preset;
    if (careFailure != null) throw careFailure!;
    return CareInteractionResponse(
      intent: request.intent,
      responseText: 'Fake care reply.',
      isAiGenerated: false,
      tier: 'info',
      disclaimer: 'Fake disclaimer.',
    );
  }

  /// Preset reply served by postCareInteraction (null = generic reply).
  CareInteractionResponse? cannedCareResponse;

  /// Failure thrown by postCareInteraction instead of replying.
  ApiError? careFailure;

  /// Last Care request received (payload/routing asserts).
  CareInteractionRequest? lastCareRequest;

  @override
  Future<HistorySummaryResponse> fetchCycleHistory() async {
    _guard();
    final sorted = List.of(serverCycles)
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
    final entries = <HistoryPeriodEntry>[];
    for (var i = 0; i < sorted.length; i++) {
      final c = sorted[i];
      entries.add(
        HistoryPeriodEntry(
          id: c.id,
          periodStart: c.periodStart,
          periodEnd: c.periodEnd,
          periodLengthDays: c.periodLengthDays,
          cycleLengthDays: i < sorted.length - 1
              ? sorted[i + 1].periodStart.difference(c.periodStart).inDays
              : null,
        ),
      );
    }
    return HistorySummaryResponse(
      totalPeriodsLogged: sorted.length,
      averageCycleLength: 28.0,
      averagePeriodLength: 5.0,
      history: entries.reversed.toList(),
      symptomFrequencies: const {},
    );
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // --- Health context fakes (mirror the backend contract) ---
  HealthContext? serverHealthContext;
  final List<HealthCondition> serverConditions = [];
  final List<Medication> serverMedications = [];

  int fetchHealthContextCalls = 0;
  int putHealthContextCalls = 0;
  int fetchConditionsCalls = 0;
  int createConditionCalls = 0;
  int patchConditionCalls = 0;
  int deleteConditionCalls = 0;
  int fetchMedicationsCalls = 0;
  int createMedicationCalls = 0;
  int patchMedicationCalls = 0;
  int deleteMedicationCalls = 0;
  int fetchCurrentCycleCalls = 0;

  int _nextConditionId = 300;
  int _nextMedicationId = 400;

  @override
  Future<HealthContext> fetchHealthContext(String userId) async {
    _guard();
    fetchHealthContextCalls++;
    return serverHealthContext ?? HealthContext(userId: serverProfile.userId);
  }

  @override
  Future<HealthContext> putHealthContext(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    putHealthContextCalls++;
    serverHealthContext = HealthContext.fromJson(
      serverProfile.userId,
      Map<String, dynamic>.from(payload),
    );
    return serverHealthContext!;
  }

  @override
  Future<List<HealthCondition>> fetchConditions() async {
    _guard();
    fetchConditionsCalls++;
    return List.of(serverConditions);
  }

  @override
  Future<HealthCondition> createCondition(Map<String, dynamic> payload) async {
    _guard();
    createConditionCalls++;
    final code = payload['condition_code'] as String? ?? '';
    final label = payload['custom_label'] as String?;
    if (code == HealthConditionCodes.other &&
        (label == null || label.trim().isEmpty)) {
      throw const ValidationError('custom_label is required');
    }
    if (serverConditions.any((c) => c.code == code && c.customLabel == label)) {
      throw Conflict('This condition is already recorded for this user.');
    }
    final row = HealthCondition(
      id: _nextConditionId++,
      userId: serverProfile.userId,
      code: code,
      customLabel: label,
      note: payload['note'] as String?,
      isActive: payload['is_active'] as bool? ?? true,
    );
    serverConditions.add(row);
    return row;
  }

  @override
  Future<HealthCondition> patchCondition(
    int serverId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    patchConditionCalls++;
    final i = serverConditions.indexWhere((c) => c.id == serverId);
    if (i < 0) throw const ServerError('Health condition not found');
    final old = serverConditions[i];
    final row = HealthCondition(
      id: old.id,
      userId: old.userId,
      code: payload['condition_code'] as String? ?? old.code,
      customLabel: payload.containsKey('custom_label')
          ? payload['custom_label'] as String?
          : old.customLabel,
      note: payload.containsKey('note') ? payload['note'] as String? : old.note,
      isActive: payload['is_active'] as bool? ?? old.isActive,
    );
    serverConditions[i] = row;
    return row;
  }

  @override
  Future<void> deleteCondition(int serverId) async {
    _guard();
    deleteConditionCalls++;
    // Missing rows are already gone: idempotent success, like the API.
    serverConditions.removeWhere((c) => c.id == serverId);
  }

  @override
  Future<List<Medication>> fetchMedications() async {
    _guard();
    fetchMedicationsCalls++;
    return List.of(serverMedications);
  }

  @override
  Future<Medication> createMedication(Map<String, dynamic> payload) async {
    _guard();
    createMedicationCalls++;
    final name = payload['name'] as String? ?? '';
    if (name.trim().isEmpty) {
      throw const ValidationError('medication name cannot be empty');
    }
    final row = Medication(
      id: _nextMedicationId++,
      userId: serverProfile.userId,
      name: name.trim(),
      note: payload['note'] as String?,
      isActive: payload['is_active'] as bool? ?? true,
    );
    serverMedications.add(row);
    return row;
  }

  @override
  Future<Medication> patchMedication(
    int serverId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    patchMedicationCalls++;
    final i = serverMedications.indexWhere((m) => m.id == serverId);
    if (i < 0) throw const ServerError('Medication not found');
    final old = serverMedications[i];
    final row = Medication(
      id: old.id,
      userId: old.userId,
      name: payload['name'] as String? ?? old.name,
      note: payload.containsKey('note') ? payload['note'] as String? : old.note,
      isActive: payload['is_active'] as bool? ?? old.isActive,
    );
    serverMedications[i] = row;
    return row;
  }

  @override
  Future<void> deleteMedication(int serverId) async {
    _guard();
    deleteMedicationCalls++;
    serverMedications.removeWhere((m) => m.id == serverId);
  }

  // --- Reproductive fakes (mirror the Phase 2–4 backend contracts) ---
  //
  // Observation upsert converges by (date, type) like the backend (second
  // POST overwrites). Pregnancy PUT/PATCH enforce the joint dating rules
  // and the provenance-precedence 409; derived dating display is computed
  // here (test-only mirror of the server derivation — Flutter never
  // computes these values, it only renders what this fake returns).
  // REVIEW GATE: this derivation must stay inside test infrastructure.
  // Never move gestational-age/EDD math into lib/ — production dating is
  // always server-computed.
  final List<FertilityObservation> serverObservations = [];
  PregnancyContext? serverPregnancy;
  AgingContext? serverAging;

  /// Canned estimate served when pregnancy mode is inactive. Tests set the
  /// status under examination (null = INSUFFICIENT_DATA default).
  FertilityEstimate? cannedEstimate;

  int createObservationCalls = 0;
  int listObservationsCalls = 0;
  int patchObservationCalls = 0;
  int deleteObservationCalls = 0;
  int fetchEstimateCalls = 0;
  int fetchPregnancyCalls = 0;
  int putPregnancyCalls = 0;
  int patchPregnancyCalls = 0;
  int deletePregnancyCalls = 0;
  int fetchAgingCalls = 0;
  int putAgingCalls = 0;

  /// Last payloads received (payload-shape asserts, e.g. no `user_id`).
  Map<String, dynamic>? lastObservationPayload;
  Map<String, dynamic>? lastPregnancyPutPayload;
  Map<String, dynamic>? lastPregnancyPatchPayload;

  int _nextObsId = 500;

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static int _daysBetween(String earlier, String later) =>
      DateTime.parse(later).difference(DateTime.parse(earlier)).inDays;

  @override
  Future<FertilityObservation> createObservation(
    Map<String, dynamic> payload,
  ) async {
    _guard();
    createObservationCalls++;
    lastObservationPayload = Map<String, dynamic>.from(payload);
    final date = payload['observation_date'] as String? ?? _todayIso();
    if (date.compareTo(_todayIso()) > 0) {
      throw const Conflict('observation_date cannot be in the future');
    }
    final type = payload['observation_type'] as String? ?? '';
    final hasLh = payload['lh_result'] != null;
    final hasBbt = payload['bbt_celsius'] != null;
    final hasMucus = payload['mucus_category'] != null;
    final valid =
        (type == ObservationTypes.lhTest && hasLh && !hasBbt && !hasMucus) ||
        (type == ObservationTypes.bbt && hasBbt && !hasLh && !hasMucus) ||
        (type == ObservationTypes.cervicalMucus &&
            hasMucus &&
            !hasLh &&
            !hasBbt);
    if (!valid) {
      throw const ValidationError('Value does not match observation type.');
    }
    final existing = serverObservations
        .where((o) => o.observationDate == date && o.observationType == type)
        .toList();
    if (existing.isNotEmpty) {
      // Deterministic upsert: overwrite in place (backend answers 200).
      final old = existing.single;
      final row = FertilityObservation(
        id: old.id,
        userId: old.userId,
        observationDate: date,
        observationType: type,
        lhResult: payload['lh_result'] as String?,
        bbtCelsius: (payload['bbt_celsius'] as num?)?.toDouble(),
        mucusCategory: payload['mucus_category'] as String?,
        source: payload['source'] as String? ?? ObservationSources.manual,
        note: payload['note'] as String?,
      );
      serverObservations[serverObservations.indexOf(old)] = row;
      return row;
    }
    final row = FertilityObservation(
      id: _nextObsId++,
      userId: serverProfile.userId,
      observationDate: date,
      observationType: type,
      lhResult: payload['lh_result'] as String?,
      bbtCelsius: (payload['bbt_celsius'] as num?)?.toDouble(),
      mucusCategory: payload['mucus_category'] as String?,
      source: payload['source'] as String? ?? ObservationSources.manual,
      note: payload['note'] as String?,
    );
    serverObservations.add(row);
    return row;
  }

  @override
  Future<List<FertilityObservation>> listObservations({
    String? startDate,
    String? endDate,
    String? observationType,
  }) async {
    _guard();
    listObservationsCalls++;
    if (startDate != null &&
        endDate != null &&
        startDate.compareTo(endDate) > 0) {
      throw const ValidationError('start_date cannot be after end_date');
    }
    final rows =
        serverObservations
            .where(
              (o) =>
                  (startDate == null ||
                      o.observationDate.compareTo(startDate) >= 0) &&
                  (endDate == null ||
                      o.observationDate.compareTo(endDate) <= 0) &&
                  (observationType == null ||
                      o.observationType == observationType),
            )
            .toList()
          ..sort((a, b) {
            final date = b.observationDate.compareTo(a.observationDate);
            return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
          });
    return rows;
  }

  @override
  Future<FertilityObservation> patchObservation(
    int serverId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    patchObservationCalls++;
    lastObservationPayload = Map<String, dynamic>.from(payload);
    final i = serverObservations.indexWhere((o) => o.id == serverId);
    if (i < 0) throw const ServerError('Fertility observation not found');
    final old = serverObservations[i];
    if (payload.containsKey('lh_result') &&
        payload['lh_result'] != null &&
        old.observationType != ObservationTypes.lhTest) {
      throw const ValidationError('lh_result is only valid for lh_test');
    }
    if (payload.containsKey('bbt_celsius') &&
        payload['bbt_celsius'] != null &&
        old.observationType != ObservationTypes.bbt) {
      throw const ValidationError('bbt_celsius is only valid for bbt');
    }
    if (payload.containsKey('mucus_category') &&
        payload['mucus_category'] != null &&
        old.observationType != ObservationTypes.cervicalMucus) {
      throw const ValidationError(
        'mucus_category is only valid for cervical_mucus',
      );
    }
    final newDate =
        payload['observation_date'] as String? ?? old.observationDate;
    if (newDate.compareTo(_todayIso()) > 0) {
      throw const Conflict('observation_date cannot be in the future');
    }
    if (serverObservations.any(
      (o) =>
          o.id != serverId &&
          o.observationDate == newDate &&
          o.observationType == old.observationType,
    )) {
      throw const Conflict(
        'An observation of this type already exists on that date.',
      );
    }
    final row = FertilityObservation(
      id: old.id,
      userId: old.userId,
      observationDate: newDate,
      observationType: old.observationType,
      lhResult: payload.containsKey('lh_result')
          ? payload['lh_result'] as String?
          : old.lhResult,
      bbtCelsius: payload.containsKey('bbt_celsius')
          ? (payload['bbt_celsius'] as num?)?.toDouble()
          : old.bbtCelsius,
      mucusCategory: payload.containsKey('mucus_category')
          ? payload['mucus_category'] as String?
          : old.mucusCategory,
      source: payload['source'] as String? ?? old.source,
      note: payload.containsKey('note') ? payload['note'] as String? : old.note,
    );
    serverObservations[i] = row;
    return row;
  }

  @override
  Future<void> deleteObservation(int serverId) async {
    _guard();
    deleteObservationCalls++;
    // Idempotent: missing rows are already gone (backend 404 path).
    serverObservations.removeWhere((o) => o.id == serverId);
  }

  @override
  Future<FertilityEstimate> fetchFertilityEstimate({String? asOf}) async {
    _guard();
    fetchEstimateCalls++;
    if (asOf != null && asOf.compareTo(_todayIso()) > 0) {
      throw const Conflict('as_of cannot be in the future');
    }
    // Backend suppression gate: explicit pregnancy mode hides dates.
    if (serverPregnancy?.isActive == true) {
      return FertilityEstimate(
        estimateDate: asOf ?? _todayIso(),
        status: FertilityEstimateStatus.suppressed,
        evidenceSource: EstimateEvidenceSource.estimated,
        evidence: const {'pregnancy_mode_active': true},
        method: 'fertility_v1',
        methodVersion: '1.0.0',
      );
    }
    return cannedEstimate ??
        FertilityEstimate(
          estimateDate: asOf ?? _todayIso(),
          status: FertilityEstimateStatus.insufficientData,
          evidenceSource: EstimateEvidenceSource.estimated,
          method: 'fertility_v1',
          methodVersion: '1.0.0',
        );
  }

  static int _datingPrecedence(String? source) => switch (source) {
    DatingSources.clinician => 3,
    DatingSources.ultrasound => 2,
    DatingSources.lmp => 1,
    DatingSources.unknown => 0,
    _ => -1,
  };

  /// Test-only mirror of the server dating derivation (see note above).
  PregnancyContext _derivePregnancy(
    String userId, {
    required bool isActive,
    String? datingSource,
    String? estimatedDueDate,
    String? lmpDate,
    String? confirmationDate,
    String? datingNote,
  }) {
    final today = _todayIso();
    int? totalDays;
    if (lmpDate != null) {
      totalDays = _daysBetween(lmpDate, today);
      if (totalDays < 0) totalDays = 0;
    } else if (estimatedDueDate != null) {
      totalDays = 280 - _daysBetween(today, estimatedDueDate);
      if (totalDays < 0) totalDays = 0;
    }
    return PregnancyContext(
      userId: userId,
      isActive: isActive,
      datingSource: datingSource,
      estimatedDueDate: estimatedDueDate,
      lmpDate: lmpDate,
      confirmationDate: confirmationDate,
      datingNote: datingNote,
      eddStatus: estimatedDueDate != null ? 'available' : 'unavailable',
      eddLabel: datingSource == DatingSources.clinician
          ? 'clinician_established_due_date'
          : 'estimated_due_date',
      datingConfidence: datingSource == DatingSources.clinician
          ? 'CLINICALLY_CONFIRMED'
          : (datingSource == DatingSources.ultrasound ||
                datingSource == DatingSources.lmp)
          ? 'ESTIMATED'
          : 'UNKNOWN',
      gestationalAgeTotalDays: totalDays,
      gestationalAgeWeeks: totalDays == null ? null : totalDays ~/ 7,
      gestationalAgeDays: totalDays == null ? null : totalDays % 7,
      daysUntilDue: estimatedDueDate == null
          ? null
          : _daysBetween(today, estimatedDueDate),
      asOfDate: today,
      timezoneName: 'UTC (profile timezone unset)',
    );
  }

  void _checkPregnancyRules({
    String? datingSource,
    String? estimatedDueDate,
    String? lmpDate,
    String? confirmationDate,
  }) {
    const known = [
      DatingSources.lmp,
      DatingSources.ultrasound,
      DatingSources.clinician,
    ];
    if (estimatedDueDate != null && !known.contains(datingSource)) {
      throw const ValidationError(
        'estimated_due_date requires a known dating source',
      );
    }
    if (lmpDate != null && datingSource != DatingSources.lmp) {
      throw const ValidationError('lmp_date is only valid with lmp dating');
    }
    if (lmpDate != null && lmpDate.compareTo(_todayIso()) > 0) {
      throw const Conflict('lmp_date cannot be in the future');
    }
    if (confirmationDate != null &&
        confirmationDate.compareTo(_todayIso()) > 0) {
      throw const Conflict('confirmation_date cannot be in the future');
    }
  }

  void _checkDowngrade({
    required String? incomingSource,
    required String? incomingEdd,
  }) {
    final existing = serverPregnancy;
    if (existing?.estimatedDueDate == null || incomingEdd == null) return;
    if (existing!.estimatedDueDate == incomingEdd) return;
    if (_datingPrecedence(incomingSource) <
        _datingPrecedence(existing.datingSource)) {
      throw Conflict(
        'Stored ${existing.datingSource}-based due date ${existing.estimatedDueDate} '
        'has higher provenance than incoming $incomingSource-based date $incomingEdd; '
        'a lower-provenance source cannot silently replace it.',
      );
    }
  }

  @override
  Future<PregnancyContext> fetchPregnancy(String userId) async {
    _guard();
    fetchPregnancyCalls++;
    return serverPregnancy ??
        PregnancyContext(userId: serverProfile.userId, isActive: false);
  }

  @override
  Future<PregnancyContext> putPregnancy(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    putPregnancyCalls++;
    lastPregnancyPutPayload = Map<String, dynamic>.from(payload);
    final source = payload['dating_source'] as String?;
    final edd = payload['estimated_due_date'] as String?;
    _checkPregnancyRules(
      datingSource: source,
      estimatedDueDate: edd,
      lmpDate: payload['lmp_date'] as String?,
      confirmationDate: payload['confirmation_date'] as String?,
    );
    _checkDowngrade(incomingSource: source, incomingEdd: edd);
    serverPregnancy = _derivePregnancy(
      serverProfile.userId,
      isActive: payload['is_active'] as bool? ?? true,
      datingSource: source,
      estimatedDueDate: edd,
      lmpDate: payload['lmp_date'] as String?,
      confirmationDate: payload['confirmation_date'] as String?,
      datingNote: payload['dating_note'] as String?,
    );
    return serverPregnancy!;
  }

  @override
  Future<PregnancyContext> patchPregnancy(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    patchPregnancyCalls++;
    lastPregnancyPatchPayload = Map<String, dynamic>.from(payload);
    final current =
        serverPregnancy ??
        _derivePregnancy(serverProfile.userId, isActive: true);
    final source = payload.containsKey('dating_source')
        ? payload['dating_source'] as String?
        : current.datingSource;
    final edd = payload.containsKey('estimated_due_date')
        ? payload['estimated_due_date'] as String?
        : current.estimatedDueDate;
    final lmp = payload.containsKey('lmp_date')
        ? payload['lmp_date'] as String?
        : current.lmpDate;
    final conf = payload.containsKey('confirmation_date')
        ? payload['confirmation_date'] as String?
        : current.confirmationDate;
    _checkPregnancyRules(
      datingSource: source,
      estimatedDueDate: edd,
      lmpDate: lmp,
      confirmationDate: conf,
    );
    if (payload.containsKey('dating_source') ||
        payload.containsKey('estimated_due_date')) {
      _checkDowngrade(incomingSource: source, incomingEdd: edd);
    }
    serverPregnancy = _derivePregnancy(
      serverProfile.userId,
      isActive: payload.containsKey('is_active')
          ? (payload['is_active'] as bool? ?? current.isActive)
          : current.isActive,
      datingSource: source,
      estimatedDueDate: edd,
      lmpDate: lmp,
      confirmationDate: conf,
      datingNote: payload.containsKey('dating_note')
          ? payload['dating_note'] as String?
          : current.datingNote,
    );
    return serverPregnancy!;
  }

  @override
  Future<void> deletePregnancy() async {
    _guard();
    deletePregnancyCalls++;
    serverPregnancy = null;
  }

  @override
  Future<AgingContext> fetchAgingContext(String userId) async {
    _guard();
    fetchAgingCalls++;
    return serverAging ??
        AgingContext(userId: serverProfile.userId, hasContext: false);
  }

  @override
  Future<AgingContext> putAgingContext(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    _guard();
    putAgingCalls++;
    final notes = payload['notes'] as String?;
    if (notes != null && notes.length > kAgingNoteMaxLength) {
      throw const ValidationError(
        'Please keep this context under 2000 characters.',
      );
    }
    serverAging = AgingContext(
      userId: serverProfile.userId,
      hasContext: notes != null,
      notes: notes,
    );
    return serverAging!;
  }
}

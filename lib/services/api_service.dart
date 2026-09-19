import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/sync_policy.dart';
import '../models/profile.dart';
import '../models/health_context.dart';
import '../models/onboarding.dart';
import '../models/cycle.dart';
import '../models/daily_log.dart';
import '../models/care.dart';
import '../models/summary.dart';
import '../models/device.dart';
import '../models/therapy.dart';
import '../models/reproductive.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// Remote-only transport. Data methods throw typed [ApiError] so
  /// repositories can distinguish no-data from network/auth/server
  /// failures. `null` is returned ONLY for genuine 404 no-data cases.
  Future<Profile> fetchProfile() async {
    try {
      final response = await _dio.get('/api/v1/profile');
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Profile> patchProfile(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch('/api/v1/profile', data: payload);
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Completes onboarding and returns the persisted profile plus the
  /// first-period identity so callers can cache both rows locally.
  /// Throws typed [ApiError] (network / validation / conflict / server):
  /// `null` is never used to signal failure — a missing profile in the
  /// response is a server contract violation ([ServerError]).
  Future<OnboardingResult> completeOnboarding(OnboardingRequest payload) async {
    try {
      final response = await _dio.post(
        '/api/v1/onboarding/complete',
        data: payload.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['profile'] != null) {
        return OnboardingResult.fromJson(data);
      }
      throw const ServerError('Onboarding did not return a profile.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      throw ServerError('Onboarding failed: $e');
    }
  }

  Future<CurrentCycleResponse> fetchCurrentCycle() async {
    try {
      final response = await _dio.get('/api/v1/cycles/current');
      return CurrentCycleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching current cycle: $e');
      rethrow;
    }
  }

  /// Returns null ONLY on 404 (no log for this date). All other failures
  /// throw typed [ApiError].
  Future<DailyLogResponse?> fetchDailyLog(String dateString) async {
    try {
      final response = await _dio.get('/api/v1/logs/$dateString');
      if (response.data == null || response.data.toString().isEmpty) {
        return null;
      }
      return DailyLogResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching daily log: $e');
      rethrow;
    }
  }

  Future<DailyLogResponse> upsertDailyLog(DailyLogCreate payload) async {
    try {
      final response = await _dio.post('/api/v1/logs', data: payload.toJson());
      return DailyLogResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error saving daily log: $e');
      rethrow;
    }
  }

  // --- Care Interaction API ---
  Future<CareInteractionResponse> postCareInteraction(
    CareInteractionRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/care/interactions',
        data: request.toJson(),
      );
      return CareInteractionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error posting care interaction: $e');
      rethrow;
    }
  }

  // --- Summary API ---
  Future<HistorySummaryResponse> fetchCycleHistory() async {
    try {
      final response = await _dio.get('/api/v1/summary/history');
      return HistorySummaryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching cycle history: $e');
      rethrow;
    }
  }

  // --- Devices API ---
  Future<List<Device>> getDevices() async {
    try {
      final response = await _dio.get('/api/v1/devices');
      final List data = response.data;
      return data.map((json) => Device.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      return [];
    }
  }

  Future<Device?> registerDevice(DeviceCreate payload) async {
    try {
      final response = await _dio.post(
        '/api/v1/devices',
        data: payload.toJson(),
      );
      return Device.fromJson(response.data);
    } catch (e) {
      debugPrint('Error registering device: $e');
      return null;
    }
  }

  // --- Cycles API ---
  Future<List<CycleResponse>> fetchCycles() async {
    try {
      final response = await _dio.get('/api/v1/cycles');
      final List data = response.data;
      return data.map((json) => CycleResponse.fromJson(json)).toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching cycles: $e');
      rethrow;
    }
  }

  Future<CycleResponse> createCycle({
    required String periodStart,
    String? periodEnd,
  }) async {
    try {
      final data = <String, dynamic>{'period_start': periodStart};
      if (periodEnd != null) data['period_end'] = periodEnd;
      final response = await _dio.post('/api/v1/cycles', data: data);
      return CycleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error creating period: $e');
      rethrow;
    }
  }

  Future<CycleResponse> patchCycle(
    int serverId, {
    String? periodStart,
    String? periodEnd,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (periodStart != null) data['period_start'] = periodStart;
      if (periodEnd != null) data['period_end'] = periodEnd;
      final response = await _dio.patch('/api/v1/cycles/$serverId', data: data);
      return CycleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error updating period: $e');
      rethrow;
    }
  }

  Future<CycleResponse> endOngoingCycle(String dateString) async {
    try {
      final response = await _dio.post(
        '/api/v1/cycles/current/end',
        data: {'period_end': dateString},
      );
      return CycleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error ending ongoing period: $e');
      rethrow;
    }
  }

  // --- Health Context API ---
  //
  // V1 foundation: user-provided context only. The backend stores and
  // returns these values verbatim; it never diagnoses, infers, or lets
  // them alter predictions — and neither does this client.

  /// GET the singleton. Never 404s: the backend returns an empty object
  /// when nothing is stored yet.
  Future<HealthContext> fetchHealthContext(String userId) async {
    try {
      final response = await _dio.get('/api/v1/health-context');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return HealthContext.fromJson(userId, data);
      }
      throw const ServerError('Health context response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error fetching health context: $e');
      throw ServerError('Health context fetch failed: $e');
    }
  }

  /// PUT the singleton (full replacement; omitted fields clear to null).
  Future<HealthContext> putHealthContext(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put('/api/v1/health-context', data: payload);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return HealthContext.fromJson(userId, data);
      }
      throw const ServerError('Health context response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error saving health context: $e');
      throw ServerError('Health context save failed: $e');
    }
  }

  Future<List<HealthCondition>> fetchConditions() async {
    try {
      final response = await _dio.get('/api/v1/health-context/conditions');
      final List data = response.data;
      return data
          .map((json) => HealthCondition.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching conditions: $e');
      rethrow;
    }
  }

  Future<HealthCondition> createCondition(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '/api/v1/health-context/conditions',
        data: payload,
      );
      return HealthCondition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error creating condition: $e');
      rethrow;
    }
  }

  Future<HealthCondition> patchCondition(
    int serverId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/v1/health-context/conditions/$serverId',
        data: payload,
      );
      return HealthCondition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error updating condition: $e');
      rethrow;
    }
  }

  /// DELETE is idempotent: a 404 means the row is already gone, which is
  /// the desired end state, so it succeeds silently.
  Future<void> deleteCondition(int serverId) async {
    try {
      await _dio.delete('/api/v1/health-context/conditions/$serverId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error deleting condition: $e');
      rethrow;
    }
  }

  Future<List<Medication>> fetchMedications() async {
    try {
      final response = await _dio.get('/api/v1/health-context/medications');
      final List data = response.data;
      return data
          .map((json) => Medication.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching medications: $e');
      rethrow;
    }
  }

  Future<Medication> createMedication(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '/api/v1/health-context/medications',
        data: payload,
      );
      return Medication.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error creating medication: $e');
      rethrow;
    }
  }

  Future<Medication> patchMedication(
    int serverId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/v1/health-context/medications/$serverId',
        data: payload,
      );
      return Medication.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  /// DELETE is idempotent: a 404 means the row is already gone, which is
  /// the desired end state, so it succeeds silently.
  Future<void> deleteMedication(int serverId) async {
    try {
      await _dio.delete('/api/v1/health-context/medications/$serverId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  // --- Therapy API ---
  Future<TherapyRecommendationResponse?> getTherapyRecommendations({
    int? painScore,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (painScore != null) {
        payload['pain_score'] = painScore;
      }
      final response = await _dio.post(
        '/api/v1/therapy/recommend',
        data: payload,
      );
      return TherapyRecommendationResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting therapy recommendations: $e');
      return null;
    }
  }

  Future<List<TherapySessionResponse>> getTherapyHistory() async {
    try {
      final response = await _dio.get('/api/v1/therapy/sessions');
      final List data = response.data;
      return data.map((json) => TherapySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching therapy history: $e');
      return [];
    }
  }

  // --- Reproductive API (Phase 2–4 contracts; backend authoritative) ---
  //
  // Exact route names and response schemas from
  // `MenoMate_core/app/api/v1/reproductive.py`. All payloads are Maps built
  // by the domain models; no `user_id` is ever sent (the backend determines
  // ownership from the session). Errors throw typed [ApiError] via
  // [mapDioException]; `null` is never used to signal failure.

  /// POST: records one observation; re-posting the same (date, type)
  /// overwrites deterministically (200 vs 201 — both decode identically).
  Future<FertilityObservation> createObservation(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/reproductive/observations',
        data: payload,
      );
      return FertilityObservation.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error creating fertility observation: $e');
      rethrow;
    }
  }

  Future<List<FertilityObservation>> listObservations({
    String? startDate,
    String? endDate,
    String? observationType,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;
      if (observationType != null) query['observation_type'] = observationType;
      final response = await _dio.get(
        '/api/v1/reproductive/observations',
        queryParameters: query,
      );
      final List data = response.data as List;
      return data
          .map(
            (json) =>
                FertilityObservation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error listing fertility observations: $e');
      rethrow;
    }
  }

  Future<FertilityObservation> patchObservation(
    int serverId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/v1/reproductive/observations/$serverId',
        data: payload,
      );
      return FertilityObservation.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error updating fertility observation: $e');
      rethrow;
    }
  }

  /// DELETE is idempotent: a 404 means the row is already gone, which is
  /// the desired end state, so it succeeds silently.
  Future<void> deleteObservation(int serverId) async {
    try {
      await _dio.delete('/api/v1/reproductive/observations/$serverId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error deleting fertility observation: $e');
      rethrow;
    }
  }

  /// GET the server-computed estimate. Always HTTP 200; INSUFFICIENT_DATA /
  /// LOW_CONFIDENCE / SUPPRESSED answers carry null dates (never invented).
  Future<FertilityEstimate> fetchFertilityEstimate({String? asOf}) async {
    try {
      final query = <String, dynamic>{};
      if (asOf != null) query['as_of'] = asOf;
      final response = await _dio.get(
        '/api/v1/reproductive/estimates',
        queryParameters: query,
      );
      return FertilityEstimate.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error fetching fertility estimate: $e');
      rethrow;
    }
  }

  /// GET the pregnancy-mode singleton. Never 404s: the backend returns an
  /// inactive unset default when pregnancy mode was never entered.
  Future<PregnancyContext> fetchPregnancy(String userId) async {
    try {
      final response = await _dio.get('/api/v1/reproductive/pregnancy');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PregnancyContext.fromJson(userId, data);
      }
      throw const ServerError('Pregnancy response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error fetching pregnancy context: $e');
      throw ServerError('Pregnancy fetch failed: $e');
    }
  }

  /// PUT full replacement (omitted dating fields clear to null; `is_active`
  /// defaults true server-side on activation).
  Future<PregnancyContext> putPregnancy(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/reproductive/pregnancy',
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PregnancyContext.fromJson(userId, data);
      }
      throw const ServerError('Pregnancy response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error saving pregnancy context: $e');
      throw ServerError('Pregnancy save failed: $e');
    }
  }

  /// PATCH partial update (only included fields change; explicit null
  /// clears). Deactivation is explicit via `{is_active: false}`.
  Future<PregnancyContext> patchPregnancy(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/v1/reproductive/pregnancy',
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PregnancyContext.fromJson(userId, data);
      }
      throw const ServerError('Pregnancy response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error updating pregnancy context: $e');
      throw ServerError('Pregnancy update failed: $e');
    }
  }

  /// DELETE erases the singleton row (explicit exit with erasure). The
  /// backend answers 204 even when nothing existed.
  Future<void> deletePregnancy() async {
    try {
      await _dio.delete('/api/v1/reproductive/pregnancy');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error deleting pregnancy context: $e');
      rethrow;
    }
  }

  /// GET the aging singleton. Never 404s: unset/cleared yields
  /// `has_context` false with `user_declared` provenance.
  Future<AgingContext> fetchAgingContext(String userId) async {
    try {
      final response = await _dio.get('/api/v1/reproductive/aging-context');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AgingContext.fromJson(userId, data);
      }
      throw const ServerError('Aging context response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error fetching aging context: $e');
      throw ServerError('Aging context fetch failed: $e');
    }
  }

  /// PUT full replacement: notes set verbatim; omitted/null clears.
  Future<AgingContext> putAgingContext(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/reproductive/aging-context',
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AgingContext.fromJson(userId, data);
      }
      throw const ServerError('Aging context response malformed.');
    } on DioException catch (e) {
      throw mapDioException(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('Error saving aging context: $e');
      throw ServerError('Aging context save failed: $e');
    }
  }
}

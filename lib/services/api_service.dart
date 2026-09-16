import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../data/sync_policy.dart';
import '../models/profile.dart';
import '../models/onboarding.dart';
import '../models/cycle.dart';
import '../models/daily_log.dart';
import '../models/care.dart';
import '../models/summary.dart';
import '../models/device.dart';
import '../models/therapy.dart';

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
      final response = await _dio.post('/api/v1/onboarding/complete', data: payload.toJson());
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
  Future<CareInteractionResponse?> postCareInteraction(CareInteractionRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/care/interact',
        data: request.toJson(),
      );
      return CareInteractionResponse.fromJson(response.data);
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
      final response = await _dio.post('/api/v1/devices', data: payload.toJson());
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
      final response =
          await _dio.patch('/api/v1/cycles/$serverId', data: data);
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
      final response = await _dio.post('/api/v1/cycles/current/end', data: {
        'period_end': dateString,
      });
      return CycleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      debugPrint('Error ending ongoing period: $e');
      rethrow;
    }
  }

  // --- Therapy API ---
  Future<TherapyRecommendationResponse?> getTherapyRecommendations({int? painScore}) async {
    try {
      final payload = <String, dynamic>{};
      if (painScore != null) {
        payload['pain_score'] = painScore;
      }
      final response = await _dio.post('/api/v1/therapy/recommend', data: payload);
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
}

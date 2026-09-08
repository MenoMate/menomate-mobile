import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
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

  Future<Profile?> getProfile() async {
    try {
      final response = await _dio.get('/api/v1/profile');
      if (response.data == null) return null;
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      debugPrint('DioException fetching profile: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Profile?> updateProfile(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch('/api/v1/profile', data: payload);
      return Profile.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<Profile?> completeOnboarding(OnboardingRequest payload) async {
    try {
      final response = await _dio.post('/api/v1/onboarding/complete', data: payload.toJson());
      if (response.data != null && response.data['profile'] != null) {
        return Profile.fromJson(response.data['profile']);
      }
      return null;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      rethrow;
    }
  }

  Future<CurrentCycleResponse?> getCurrentCycle() async {
    try {
      final response = await _dio.get('/api/v1/cycles/current');
      return CurrentCycleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching current cycle: $e');
      return null;
    }
  }

  Future<DailyLogResponse?> getDailyLog(String dateString) async {
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
      debugPrint('DioException fetching daily log: $e');
      return null;
    } catch (e) {
      debugPrint('Error fetching daily log: $e');
      return null;
    }
  }

  Future<DailyLogResponse?> saveDailyLog(DailyLogCreate payload) async {
    try {
      final response = await _dio.post('/api/v1/logs', data: payload.toJson());
      return DailyLogResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error saving daily log: $e');
      return null;
    }
  }

  Future<DailyLogResponse?> upsertDailyLog(DailyLogCreate payload) => saveDailyLog(payload);


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
  Future<HistorySummaryResponse?> getCycleHistory() async {
    try {
      final response = await _dio.get('/api/v1/summary/history');
      return HistorySummaryResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching cycle history: $e');
      return null;
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
  Future<List<CycleResponse>> getCycles() async {
    try {
      final response = await _dio.get('/api/v1/cycles');
      final List data = response.data;
      return data.map((json) => CycleResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching cycles: $e');
      return [];
    }
  }

  Future<void> startPeriod(DateTime date) async {
    try {
      await _dio.post('/api/v1/cycles', data: {
        'period_start': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      });
    } catch (e) {
      debugPrint('Error starting period: $e');
      rethrow;
    }
  }

  Future<void> endPeriod(int cycleId, DateTime date) async {
    try {
      await _dio.patch('/api/v1/cycles/$cycleId', data: {
        'period_end': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      });
    } catch (e) {
      debugPrint('Error ending period: $e');
      rethrow;
    }
  }

  Future<void> endOngoingPeriod(DateTime date) async {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    try {
      await _dio.post('/api/v1/cycles/current/end', data: {
        'period_end': dateStr,
      });
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

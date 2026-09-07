import 'package:dio/dio.dart';
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
      return Profile.fromJson(response.data);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<CurrentCycleResponse?> getCurrentCycle() async {
    try {
      final response = await _dio.get('/api/v1/cycles/current');
      return CurrentCycleResponse.fromJson(response.data);
    } catch (e) {
      print('Error fetching current cycle: $e');
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
      print('Error fetching daily log: $e');
      return null;
    } catch (e) {
      print('Error fetching daily log: $e');
      return null;
    }
  }

  Future<DailyLogResponse?> upsertDailyLog(DailyLogCreate payload) async {
    try {
      final response = await _dio.post('/api/v1/logs', data: payload.toJson());
      return DailyLogResponse.fromJson(response.data);
    } catch (e) {
      print('Error upserting daily log: $e');
      return null;
    }
  }

  Future<void> completeOnboarding(OnboardingRequest request) async {
    await _dio.post('/api/v1/onboarding/complete', data: request.toJson());
  }

  // --- Care API ---
  Future<CareInteractionResponse?> postCareInteraction(CareInteractionRequest request) async {
    try {
      final response = await _dio.post('/api/v1/care/interactions', data: request.toJson());
      return CareInteractionResponse.fromJson(response.data);
    } catch (e) {
      print('Error posting care interaction: $e');
      return null;
    }
  }

  // --- Summary API ---
  Future<HistorySummaryResponse?> getCycleHistory() async {
    try {
      final response = await _dio.get('/api/v1/summary/history');
      return HistorySummaryResponse.fromJson(response.data);
    } catch (e) {
      print('Error fetching history summary: $e');
      return null;
    }
  }

  // --- Devices API ---
  Future<Device?> registerDevice(DeviceCreate payload) async {
    try {
      final response = await _dio.post('/api/v1/devices', data: payload.toJson());
      return Device.fromJson(response.data);
    } catch (e) {
      print('Error registering device: $e');
      return null;
    }
  }

  // --- Cycles API ---
  Future<void> startPeriod(DateTime date) async {
    try {
      await _dio.post('/api/v1/cycles', data: {
        'period_start': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      });
    } catch (e) {
      print('Error starting period: $e');
      rethrow;
    }
  }

  Future<void> endPeriod(int cycleId, DateTime date) async {
    try {
      await _dio.patch('/api/v1/cycles/$cycleId', data: {
        'period_end': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      });
    } catch (e) {
      print('Error ending period: $e');
      rethrow;
    }
  }

  // --- Therapy API ---
  Future<TherapyRecommendationResponse?> getTherapyRecommendations({int? painScore}) async {
    try {
      final response = await _dio.post('/api/v1/therapy/recommend', data: {
        if (painScore != null) 'pain_score': painScore,
      });
      return TherapyRecommendationResponse.fromJson(response.data);
    } catch (e) {
      print('Error getting therapy recommendations: $e');
      return null;
    }
  }

  Future<List<TherapySessionResponse>> getTherapyHistory() async {
    try {
      final response = await _dio.get('/api/v1/therapy/sessions');
      final List data = response.data;
      return data.map((json) => TherapySessionResponse.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching therapy history: $e');
      return [];
    }
  }
}

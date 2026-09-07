class TherapyRecommendationResponse {
  final int painScore;
  final double targetTemperatureC;
  final String vibrationMode;
  final int vibrationIntensity;
  final int durationMinutes;
  final String reasoning;
  final double appliedSensitivityIndex;

  TherapyRecommendationResponse({
    required this.painScore,
    required this.targetTemperatureC,
    required this.vibrationMode,
    required this.vibrationIntensity,
    required this.durationMinutes,
    required this.reasoning,
    required this.appliedSensitivityIndex,
  });

  factory TherapyRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return TherapyRecommendationResponse(
      painScore: json['pain_score'] as int,
      targetTemperatureC: (json['target_temperature_c'] as num).toDouble(),
      vibrationMode: json['vibration_mode'] as String,
      vibrationIntensity: json['vibration_intensity'] as int,
      durationMinutes: json['duration_minutes'] as int,
      reasoning: json['reasoning'] as String,
      appliedSensitivityIndex: (json['applied_sensitivity_index'] as num).toDouble(),
    );
  }
}

class TherapySessionResponse {
  final int id;
  final String userId;
  final String? deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String mode;
  final double? targetTemperatureC;
  final int? vibrationIntensity;
  final String? vibrationMode;
  final int? painBefore;
  final int? painAfter;
  final String? feedback;
  final DateTime createdAt;

  TherapySessionResponse({
    required this.id,
    required this.userId,
    this.deviceId,
    required this.startedAt,
    this.endedAt,
    required this.mode,
    this.targetTemperatureC,
    this.vibrationIntensity,
    this.vibrationMode,
    this.painBefore,
    this.painAfter,
    this.feedback,
    required this.createdAt,
  });

  factory TherapySessionResponse.fromJson(Map<String, dynamic> json) {
    return TherapySessionResponse(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String?,
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      mode: json['mode'] as String,
      targetTemperatureC: (json['target_temperature_c'] as num?)?.toDouble(),
      vibrationIntensity: json['vibration_intensity'] as int?,
      vibrationMode: json['vibration_mode'] as String?,
      painBefore: json['pain_before'] as int?,
      painAfter: json['pain_after'] as int?,
      feedback: json['feedback'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

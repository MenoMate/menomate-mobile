class SymptomItem {
  final String symptomType;
  final int severity;

  SymptomItem({
    required this.symptomType,
    this.severity = 0,
  });

  factory SymptomItem.fromJson(Map<String, dynamic> json) {
    return SymptomItem(
      symptomType: json['symptom_type'] as String,
      severity: json['severity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptom_type': symptomType,
      'severity': severity,
    };
  }
}

class DailyLogCreate {
  final String? logDate;
  final int pain;
  final String? mood;
  final String? discharge;
  final String? flow;
  final List<SymptomItem> symptoms;
  final String? notes;

  DailyLogCreate({
    this.logDate,
    this.pain = 0,
    this.mood,
    this.discharge,
    this.flow,
    this.symptoms = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (logDate != null) 'log_date': logDate,
      'pain': pain,
      if (mood != null) 'mood': mood,
      if (discharge != null) 'discharge': discharge,
      if (flow != null) 'flow': flow,
      'symptoms': symptoms.map((e) => e.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}

class DailyLogResponse {
  final int id;
  final String userId;
  final String logDate;
  final int pain;
  final String? mood;
  final String? discharge;
  final String? flow;
  final String? notes;
  final List<SymptomItem> symptoms;

  DailyLogResponse({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.pain,
    this.mood,
    this.discharge,
    this.flow,
    this.notes,
    this.symptoms = const [],
  });

  factory DailyLogResponse.fromJson(Map<String, dynamic> json) {
    return DailyLogResponse(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      logDate: json['log_date'] as String,
      pain: json['pain'] as int,
      mood: json['mood'] as String?,
      discharge: json['discharge'] as String?,
      flow: json['flow'] as String?,
      notes: json['notes'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => SymptomItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

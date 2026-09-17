import 'dart:convert';

class SymptomItem {
  final String symptomType;
  final int severity;

  const SymptomItem({
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

/// Canonical loggable symptoms, mirroring the backend catalog
/// (`GET /api/v1/symptoms`; `SUPPORTED_SYMPTOMS` in
/// `MenoMate_core/app/schemas/daily_log.py`).
///
/// The backend is the canonical source: ids must match exactly or the
/// server rejects the row with 422. A backend test pins
/// `EXPECTED_SYMPTOM_IDS`, so any catalog change there must update this
/// list in the same change. No mobile-only symptom ids may be added here.
class LoggableSymptom {
  final String id;
  final String label;

  const LoggableSymptom(this.id, this.label);
}

const List<LoggableSymptom> kLoggableSymptoms = [
  LoggableSymptom('cramps', 'Cramps'),
  LoggableSymptom('headache', 'Headache'),
  LoggableSymptom('back_pain', 'Lower Back Pain'),
  LoggableSymptom('nausea', 'Nausea'),
  LoggableSymptom('bloating', 'Bloating'),
  LoggableSymptom('low_energy', 'Low Energy / Fatigue'),
  LoggableSymptom('breast_tenderness', 'Breast Tenderness'),
  LoggableSymptom('acne', 'Acne / Skin Breakouts'),
  LoggableSymptom('sleep_difficulty', 'Sleep Difficulty'),
  LoggableSymptom('appetite_change', 'Appetite Changes'),
  LoggableSymptom('dizziness', 'Dizziness / Lightheadedness'),
];

/// Qualitative discharge characteristics (not amount), mirroring the
/// backend `DischargeEnum`. Stored legacy values outside this set (from
/// before the vocabulary change) render as unselected — never reinterpreted.
class DischargeOption {
  final String id;
  final String label;

  const DischargeOption(this.id, this.label);
}

const List<DischargeOption> kDischargeOptions = [
  DischargeOption('sticky', 'Sticky'),
  DischargeOption('creamy', 'Creamy'),
  DischargeOption('watery', 'Watery'),
  DischargeOption('slippery', 'Slippery / Stretchy'),
];

class DailyLogCreate {
  final String? logDate;

  /// Null = pain not provided; 0 = explicitly logged no pain.
  final int? pain;

  /// Null/empty = no mood logged. Serialized as a JSON array string
  /// server-side; the repository encodes/decodes transparently.
  final List<String>? mood;
  final String? discharge;
  final String? flow;
  final List<SymptomItem> symptoms;
  final String? notes;

  DailyLogCreate({
    this.logDate,
    this.pain,
    this.mood,
    this.discharge,
    this.flow,
    this.symptoms = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (logDate != null) 'log_date': logDate,
      if (pain != null) 'pain': pain,
      if (mood != null && mood!.isNotEmpty) 'mood': mood,
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

  /// Null = pain not provided; 0 = explicitly logged no pain.
  final int? pain;

  /// Null/empty = no mood logged.
  final List<String>? mood;
  final String? discharge;
  final String? flow;
  final String? notes;
  final List<SymptomItem> symptoms;

  DailyLogResponse({
    required this.id,
    required this.userId,
    required this.logDate,
    this.pain,
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
      pain: json['pain'] as int?,
      mood: parseMoods(json['mood']),
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

/// Encode a mood selection for local TEXT storage (mirrors the server
/// JSON-array convention). Null/empty stores NULL.
String? encodeMoods(List<String>? moods) {
  if (moods == null || moods.isEmpty) return null;
  return jsonEncode(moods);
}

/// Tolerant mood reader: JSON arrays, legacy bare strings ("happy" ->
/// ["happy"]), and null all decode without ever throwing.
List<String>? parseMoods(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    final items =
        value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    return items.isEmpty ? null : items;
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) return parseMoods(decoded);
      } catch (_) {
        // Fall through to bare-string handling below.
      }
    }
    return [text];
  }
  return null;
}

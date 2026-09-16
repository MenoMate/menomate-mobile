class CareInteractionRequest {
  final String intent;
  final String? userMessage;

  /// Transient active-session turns (most recent last). Never stored
  /// anywhere; the server forwards them to the provider as prompt
  /// context only.
  final List<CareTurn> recentTurns;

  CareInteractionRequest({
    required this.intent,
    this.userMessage,
    this.recentTurns = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      if (userMessage != null) 'user_message': userMessage,
      'recent_turns': recentTurns.map((t) => t.toJson()).toList(),
    };
  }
}

class CareInteractionResponse {
  final String intent;
  final String responseText;
  final bool isAiGenerated;

  /// Deterministic tier: info, advisory, or urgent. Unknown values fall
  /// back to info so rendering never breaks on contract drift.
  final String tier;
  final List<CareAction> actions;
  final String disclaimer;
  final String? therapyProfile;

  const CareInteractionResponse({
    required this.intent,
    required this.responseText,
    required this.isAiGenerated,
    this.tier = 'info',
    this.actions = const [],
    required this.disclaimer,
    this.therapyProfile,
  });

  String get response => responseText;

  bool get isUrgent => tier == 'urgent';
  bool get isAdvisory => tier == 'advisory';

  factory CareInteractionResponse.fromJson(Map<String, dynamic> json) {
    final tierRaw = json['tier'] as String?;
    final actionsRaw = json['actions'] as List<dynamic>?;
    return CareInteractionResponse(
      intent: json['intent'] as String,
      responseText: (json['response_text'] ?? json['response']) as String? ?? '',
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      tier: (tierRaw == 'urgent' || tierRaw == 'advisory') ? tierRaw! : 'info',
      actions: actionsRaw
              ?.map((e) => CareAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      disclaimer: json['disclaimer'] as String? ?? '',
      therapyProfile: json['therapy_profile'] as String?,
    );
  }
}

/// One semantic Care action: stable [id] for routing, [label] for display.
/// Routing must use the id only — never substring-match the label.
class CareAction {
  final String id;
  final String label;

  const CareAction({required this.id, required this.label});

  factory CareAction.fromJson(Map<String, dynamic> json) {
    return CareAction(
      id: json['id'] as String? ?? 'none',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

/// Semantic routing target for a [CareAction.id]. Pure mapping so action
/// routing is unit-testable without widgets or navigation.
enum CareActionTarget {
  logger,
  historyTab,
  homeTab,
  therapy,
  emergencyInfo,
  none,
}

CareActionTarget resolveCareActionTarget(String id) {
  return switch (id) {
    'open_logger' => CareActionTarget.logger,
    'log_period_start' => CareActionTarget.logger,
    'open_calendar' => CareActionTarget.historyTab,
    'open_history' => CareActionTarget.historyTab,
    'connect_wearable' => CareActionTarget.homeTab,
    'view_therapy' => CareActionTarget.therapy,
    'seek_emergency_care' => CareActionTarget.emergencyInfo,
    'call_doctor' => CareActionTarget.emergencyInfo,
    _ => CareActionTarget.none,
  };
}

/// One retained turn of the active Care session (Step 1).
///
/// In-memory only: no persistence, no IDs, no timestamps. Text is
/// truncated to ~300 characters; [facts] carries only the small
/// snapshot relevant to the turn (e.g. intent, profile label).
class CareTurn {
  static const int maxTextLength = 300;

  final String role; // 'user' | 'care'
  final String text;
  final String? topic;
  final Map<String, String> facts;

  CareTurn({
    required this.role,
    required String text,
    this.topic,
    this.facts = const {},
  }) : text = text.length <= maxTextLength
            ? text
            : text.substring(0, maxTextLength);

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      if (topic != null) 'topic': topic,
    };
  }
}

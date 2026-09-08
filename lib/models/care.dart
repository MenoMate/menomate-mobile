class CareInteractionRequest {
  final String intent;
  final String? userMessage;

  CareInteractionRequest({
    required this.intent,
    this.userMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      if (userMessage != null) 'user_message': userMessage,
    };
  }
}

class CareInteractionResponse {
  final String intent;
  final String responseText;
  final bool isAiGenerated;
  final List<String> suggestedActions;
  final String disclaimer;
  final String? therapyProfile;

  CareInteractionResponse({
    required this.intent,
    required this.responseText,
    required this.isAiGenerated,
    required this.suggestedActions,
    required this.disclaimer,
    this.therapyProfile,
  });

  String get response => responseText;

  factory CareInteractionResponse.fromJson(Map<String, dynamic> json) {
    return CareInteractionResponse(
      intent: json['intent'] as String,
      responseText: (json['response_text'] ?? json['response']) as String? ?? '',
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      suggestedActions: (json['suggested_actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      disclaimer: json['disclaimer'] as String? ?? '',
      therapyProfile: json['therapy_profile'] as String?,
    );
  }
}

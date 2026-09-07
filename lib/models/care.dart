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

  CareInteractionResponse({
    required this.intent,
    required this.responseText,
    required this.isAiGenerated,
    required this.suggestedActions,
    required this.disclaimer,
  });

  factory CareInteractionResponse.fromJson(Map<String, dynamic> json) {
    return CareInteractionResponse(
      intent: json['intent'] as String,
      responseText: json['response_text'] as String,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      suggestedActions: (json['suggested_actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

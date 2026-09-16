import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/care.dart';

/// Active-session Care memory (Step 1): the last 4 completed turns
/// (2 user + 2 assistant) plus the in-flight user message.
///
/// In-memory only — no SharedPreferences, no database, no timestamps.
/// Survives tab switches (provider-scoped, and tabs sit in an
/// IndexedStack); cleared on explicit new-chat reset and on logout;
/// never restored across app restarts (fresh container = empty).
final careSessionProvider =
    NotifierProvider<CareSessionNotifier, List<CareTurn>>(
        CareSessionNotifier.new);

class CareSessionNotifier extends Notifier<List<CareTurn>> {
  /// Maximum retained completed turns.
  static const int maxTurns = 4;

  @override
  List<CareTurn> build() => const [];

  void _add(CareTurn turn) {
    final next = [...state, turn];
    while (next.length > maxTurns) {
      next.removeAt(0);
    }
    state = List.unmodifiable(next);
  }

  void addUserTurn(String text, {String? topic}) {
    _add(CareTurn(role: 'user', text: text, topic: topic));
  }

  void addCareTurn(String text, {String? topic, Map<String, String> facts = const {}}) {
    _add(CareTurn(role: 'care', text: text, topic: topic, facts: facts));
  }

  /// Explicit new-chat reset (and logout wipe path).
  void clear() => state = const [];

  /// Transient payload for the next request: turns retained so far
  /// (the in-flight user message travels separately as user_message).
  List<Map<String, dynamic>> recentTurnsPayload() =>
      state.map((t) => t.toJson()).toList();
}

/// Pure request builder so the recent_turns wiring is unit-testable
/// without widgets or networking.
CareInteractionRequest buildCareRequest({
  required String text,
  required String intent,
  required List<CareTurn> priorTurns,
}) {
  return CareInteractionRequest(
    intent: intent,
    userMessage: text,
    recentTurns: List.unmodifiable(priorTurns),
  );
}

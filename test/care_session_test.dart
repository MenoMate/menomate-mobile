import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/models/care.dart';
import 'package:menomate_mobile/providers/care_session_provider.dart';
import 'package:menomate_mobile/screens/tabs/assistant_tab.dart';

/// Step 1 — active-session memory: in-memory last-4-turns window,
/// explicit reset, logout wipe, transient request payload.
void main() {
  group('session retention (§5.1–§5.4)', () {
    test('first message creates one session turn', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(careSessionProvider.notifier)
          .addUserTurn('My cramps are worse today.', topic: 'symptom');

      final turns = container.read(careSessionProvider);
      expect(turns, hasLength(1));
      expect(turns.single.role, 'user');
      expect(turns.single.text, 'My cramps are worse today.');
      expect(turns.single.topic, 'symptom');
    });

    test('exchange retains recent context in order', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = container.read(careSessionProvider.notifier);

      session.addUserTurn('My cramps are worse today.', topic: 'symptom');
      session.addCareTurn('Sorry to hear that.', topic: 'symptom');
      session.addUserTurn('What about yesterday?', topic: 'symptom');

      final turns = container.read(careSessionProvider);
      expect(turns, hasLength(3));
      expect(turns.map((t) => t.role).toList(),
          ['user', 'care', 'user']);
      expect(turns.last.text, 'What about yesterday?');
    });

    test('window caps at 4 retained turns', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = container.read(careSessionProvider.notifier);

      for (var i = 0; i < 6; i++) {
        session.addUserTurn('message $i');
      }
      expect(container.read(careSessionProvider), hasLength(4));
    });

    test('oldest turn is evicted FIFO', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = container.read(careSessionProvider.notifier);

      session.addUserTurn('first');
      session.addCareTurn('second');
      session.addUserTurn('third');
      session.addCareTurn('fourth');
      session.addUserTurn('fifth');

      final texts =
          container.read(careSessionProvider).map((t) => t.text).toList();
      expect(texts, ['second', 'third', 'fourth', 'fifth']);
    });

    test('long text is truncated to ~300 characters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(careSessionProvider.notifier)
          .addUserTurn('x' * 1000);

      expect(container.read(careSessionProvider).single.text, hasLength(300));
    });
  });

  group('session lifecycle (§5.5–§5.8)', () {
    testWidgets('tab switch preserves session turns', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(careSessionProvider.notifier).addUserTurn('remember me');

      // Simulate leaving the Care tab: replace the whole subtree while
      // keeping the same provider container alive.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: Text('other tab'))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AssistantTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(careSessionProvider), hasLength(1));
      expect(container.read(careSessionProvider).single.text, 'remember me');
    });

    testWidgets('explicit new-chat clears session and messages',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(careSessionProvider.notifier).addUserTurn('remember me');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AssistantTab()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Start new chat'));
      await tester.pumpAndSettle();

      expect(container.read(careSessionProvider), isEmpty);
      expect(find.text('How can I help today?'), findsOneWidget);
    });

    test('logout wipe clears session (same call sign-out makes)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(careSessionProvider.notifier).addUserTurn('remember me');
      expect(container.read(careSessionProvider), isNotEmpty);

      // signOutAndClearLocalData calls ref.invalidate(careSessionProvider).
      container.invalidate(careSessionProvider);

      expect(container.read(careSessionProvider), isEmpty);
    });

    test('app restart does not restore session', () {
      final first = ProviderContainer();
      addTearDown(first.dispose);
      first.read(careSessionProvider.notifier).addUserTurn('remember me');
      expect(first.read(careSessionProvider), isNotEmpty);

      final restarted = ProviderContainer();
      addTearDown(restarted.dispose);
      expect(restarted.read(careSessionProvider), isEmpty);
    });
  });

  group('request payload (§5.9–§5.10)', () {
    test('recent_turns are included in the Care request', () {
      final turns = [
        CareTurn(role: 'user', text: 'cramps worse', topic: 'symptom'),
        CareTurn(role: 'care', text: 'sorry', topic: 'symptom'),
      ];
      final request = buildCareRequest(
        text: 'What about yesterday?',
        intent: 'symptom',
        priorTurns: turns,
      );
      final json = request.toJson();
      expect(json['user_message'], 'What about yesterday?');
      expect(json['intent'], 'symptom');
      expect(json['recent_turns'], hasLength(2));
      expect(json['recent_turns'][0]['role'], 'user');
      expect(json['recent_turns'][0]['text'], 'cramps worse');
      expect(json['recent_turns'][0]['topic'], 'symptom');
    });

    test('request omits user_message when null but keeps turns key', () {
      final request = CareInteractionRequest(intent: 'wellness_help');
      final json = request.toJson();
      expect(json.containsKey('user_message'), isFalse);
      expect(json['recent_turns'], isEmpty);
    });

    test('turns carry no persistent identity (transient only)', () {
      final turn = CareTurn(role: 'user', text: 'hi', topic: 'symptom');
      final json = turn.toJson();
      expect(json.keys, unorderedEquals(['role', 'text', 'topic']));
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
    });
  });
}

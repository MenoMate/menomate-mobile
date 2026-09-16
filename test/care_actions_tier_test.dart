import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/care.dart';
import 'package:menomate_mobile/widgets/care_message_bubble.dart';

/// Step 6 — semantic actions, tier rendering, typed Care errors.
void main() {
  group('action routing is id-based (§26.8–§26.9)', () {
    test('every known id resolves to its target', () {
      expect(resolveCareActionTarget('open_logger'), CareActionTarget.logger);
      expect(resolveCareActionTarget('log_period_start'), CareActionTarget.logger);
      expect(resolveCareActionTarget('open_calendar'), CareActionTarget.historyTab);
      expect(resolveCareActionTarget('open_history'), CareActionTarget.historyTab);
      expect(resolveCareActionTarget('connect_wearable'), CareActionTarget.homeTab);
      expect(resolveCareActionTarget('view_therapy'), CareActionTarget.therapy);
      expect(resolveCareActionTarget('seek_emergency_care'), CareActionTarget.emergencyInfo);
      expect(resolveCareActionTarget('call_doctor'), CareActionTarget.emergencyInfo);
    });

    test('unknown ids route nowhere (never substring-guessed)', () {
      expect(resolveCareActionTarget('log'), CareActionTarget.none);
      expect(resolveCareActionTarget('therapy'), CareActionTarget.none);
      expect(resolveCareActionTarget(''), CareActionTarget.none);
      expect(resolveCareActionTarget('Start Thermal Therapy'), CareActionTarget.none);
    });
  });

  group('response parsing (§26.7)', () {
    test('tier and actions parse; unknown tier falls back to info', () {
      final urgent = CareInteractionResponse.fromJson({
        'intent': 'pain_help',
        'response_text': 'x',
        'is_ai_generated': false,
        'tier': 'urgent',
        'actions': [
          {'id': 'seek_emergency_care', 'label': 'Seek Emergency Care'},
        ],
        'disclaimer': 'd',
      });
      expect(urgent.isUrgent, isTrue);
      expect(urgent.isAdvisory, isFalse);
      expect(urgent.actions.single.id, 'seek_emergency_care');

      final weird = CareInteractionResponse.fromJson({
        'intent': 'pain_help',
        'response_text': 'x',
        'is_ai_generated': false,
        'tier': 'critical',
        'disclaimer': 'd',
      });
      expect(weird.tier, 'info');
      expect(weird.actions, isEmpty);
    });
  });

  group('typed Care errors (§26.13)', () {
    test('Care 422 maps to ValidationError', () {
      final err = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/api/v1/care/interactions'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/care/interactions'),
          statusCode: 422,
          data: {'detail': 'bad intent'},
        ),
      ));
      expect(err, isA<ValidationError>());
    });

    test('Care transport failure maps to NetworkUnavailable', () {
      final err = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/api/v1/care/interactions'),
        type: DioExceptionType.connectionError,
      ));
      expect(err, isA<NetworkUnavailable>());
    });
  });

  group('tier rendering (§26.7, §26.11–§26.12, §26.16)', () {
    Future<void> pumpBubble(
      WidgetTester tester,
      Map<String, dynamic> message, {
      Brightness brightness = Brightness.light,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: CareMessageBubble(
                message: message,
                bleConnected: false,
                onAction: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('urgent tier renders safety card keyed on tier, not text',
        (tester) async {
      // NOTE: body text deliberately lacks the legacy English marker —
      // the card must still render from tier alone.
      await pumpBubble(tester, {
        'isUser': false,
        'text': 'Please get help right away.',
        'tier': 'urgent',
        'actions': const [
          CareAction(id: 'seek_emergency_care', label: 'Seek Emergency Care'),
        ],
      });

      expect(find.text('CLINICAL SAFETY ADVISORY'), findsOneWidget);
      expect(find.text('Seek Emergency Care'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('advisory tier renders caution frame', (tester) async {
      await pumpBubble(tester, {
        'isUser': false,
        'text': 'Take this seriously and talk to a clinician.',
        'tier': 'advisory',
        'actions': const [
          CareAction(id: 'open_logger', label: 'Log Symptoms'),
        ],
      });

      expect(find.text('HEALTH NOTE'), findsOneWidget);
      expect(find.text('CLINICAL SAFETY ADVISORY'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('out-of-scope renders no chips', (tester) async {
      await pumpBubble(tester, {
        'isUser': false,
        'text': "I can't help with unrelated topics.",
        'tier': 'info',
        'actions': const <CareAction>[],
      });

      expect(find.byType(ActionChip), findsNothing);
      expect(find.text("I can't help with unrelated topics."), findsOneWidget);
    });

    testWidgets('chip tap routes the action id, not the label', (tester) async {
      CareAction? tapped;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CareMessageBubble(
                message: {
                  'isUser': false,
                  'text': 'See your history.',
                  'tier': 'info',
                  // Misleading label, unambiguous id.
                  'actions': const [
                    CareAction(id: 'open_logger', label: 'Totally Different Words'),
                  ],
                },
                bleConnected: false,
                onAction: (action) => tapped = action,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Totally Different Words'));
      await tester.pumpAndSettle();

      expect(tapped, isNotNull);
      expect(tapped!.id, 'open_logger');
      expect(resolveCareActionTarget(tapped!.id), CareActionTarget.logger);
    });

    testWidgets('dark theme renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpBubble(
        tester,
        {
          'isUser': false,
          'text': 'A longer advisory body to exercise wrapping across '
              'multiple lines on a narrow viewport without clipping.',
          'tier': 'advisory',
          'actions': const [
            CareAction(id: 'open_logger', label: 'Log Symptoms'),
            CareAction(id: 'connect_wearable', label: 'Connect Wearable'),
          ],
          'therapyProfile': 'MODERATE',
        },
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('HEALTH NOTE'), findsOneWidget);
    });
  });
}

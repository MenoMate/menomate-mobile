import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/models/care.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/tabs/assistant_tab.dart';
import 'package:menomate_mobile/services/api_service.dart';
import 'package:menomate_mobile/services/ble_service.dart';

import 'offline_fake_api.dart';

class _NoBle extends BleService {
  @override
  bool get isConnected => false;
}

class _YesBle extends BleService {
  @override
  bool get isConnected => true;
}

class _QuietProfileNotifier extends ProfileNotifier {
  @override
  Future<DataState<Profile?>> build() async => const NoData<Profile?>();
}

/// Step 7 — therapy taps never claim a start (§26.14–§26.15).
void main() {
  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  Future<void> pumpCare(
    WidgetTester tester, {
    required FakeApiService api,
    required BleService ble,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(api),
          bleServiceProvider.overrideWithValue(ble),
          currentUserIdProvider.overrideWithValue('user-a'),
          profileProvider.overrideWith(() => _QuietProfileNotifier()),
        ],
        child: const MaterialApp(home: AssistantTab()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendPainMessage(WidgetTester tester) async {
    await tester.tap(find.text('Help with my current pain'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  CareInteractionResponse therapyReply() => const CareInteractionResponse(
        intent: 'therapy_recommendation',
        responseText: 'Moderate warmth fits your logged pain.',
        isAiGenerated: true,
        tier: 'info',
        actions: [
          CareAction(id: 'view_therapy', label: 'Start Moderate Thermal Therapy'),
        ],
        disclaimer: 'd',
        therapyProfile: 'MODERATE',
      );

  testWidgets('disconnected tap is truthful, never claims a start',
      (tester) async {
    final api = FakeApiService()..cannedCareResponse = therapyReply();
    await pumpCare(tester, api: api, ble: _NoBle());
    await sendPainMessage(tester);

    // The profile chip from the canned reply is rendered...
    final chip = find.widgetWithText(ActionChip, 'Start Moderate Thermal Therapy');
    expect(chip, findsWidgets);

    await tester.tap(chip.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Wearable not connected. Pair your device to use the recommended setup.'),
      findsOneWidget,
    );
    expect(find.textContaining('Started'), findsNothing);
  });

  testWidgets('connected tap stays pending without firing BLE', (tester) async {
    final api = FakeApiService()..cannedCareResponse = therapyReply();
    await pumpCare(tester, api: api, ble: _YesBle());
    await sendPainMessage(tester);

    final chip = find.widgetWithText(ActionChip, 'Start Moderate Thermal Therapy');
    expect(chip, findsWidgets);

    await tester.tap(chip.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("isn't available yet"), findsOneWidget);
    expect(find.textContaining('Started'), findsNothing);
  });
}

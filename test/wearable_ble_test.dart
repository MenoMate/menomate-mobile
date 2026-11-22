import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/models/wearable_state.dart';
import 'package:menomate_mobile/services/ble_service.dart';
import 'package:menomate_mobile/widgets/device_telemetry_card.dart';

void main() {
  group('WearableDeviceStatus & Models', () {
    test('WearableHeatLevel maps levels and duty cycles correctly', () {
      expect(WearableHeatLevel.fromInt(0), WearableHeatLevel.off);
      expect(WearableHeatLevel.fromInt(1), WearableHeatLevel.low);
      expect(WearableHeatLevel.fromInt(2), WearableHeatLevel.medium);
      expect(WearableHeatLevel.fromInt(3), WearableHeatLevel.high);
      expect(WearableHeatLevel.fromInt(99), WearableHeatLevel.off);

      expect(WearableHeatLevel.low.dutyCycle, '20%');
      expect(WearableHeatLevel.medium.dutyCycle, '35%');
      expect(WearableHeatLevel.high.dutyCycle, '50%');
    });

    test('WearableMotorMode maps wire values correctly and excludes pulse', () {
      expect(WearableMotorMode.fromWire('off'), WearableMotorMode.off);
      expect(WearableMotorMode.fromWire('steady'), WearableMotorMode.steady);
      expect(WearableMotorMode.fromWire('smooth'), WearableMotorMode.steady);
      expect(WearableMotorMode.fromWire('wave'), WearableMotorMode.wave);
      // Rapid pulse/tap is rejected and defaults to off for relay safety
      expect(WearableMotorMode.fromWire('pulse'), WearableMotorMode.off);
      expect(WearableMotorMode.fromWire('tap'), WearableMotorMode.off);
      expect(WearableMotorMode.fromWire('unknown'), WearableMotorMode.off);
    });

    test('WearableDeviceStatus parses ESP32 status JSON payload', () {
      final json = {
        'connected': true,
        'on': true,
        'heat': 2,
        'motor': 'wave',
        'heater_active': true,
        'motor_active': false,
      };

      final status = WearableDeviceStatus.fromJson(json);
      expect(status.isConnected, isTrue);
      expect(status.isPowerOn, isTrue);
      expect(status.heatLevel, WearableHeatLevel.medium);
      expect(status.motorMode, WearableMotorMode.wave);
      expect(status.isHeaterActive, isTrue);
      expect(status.isMotorActive, isFalse);
    });

    test('WearableDeviceStatus handles legacy hon field and defaults safely', () {
      final json = {
        'connected': true,
        'on': false,
        'heat': 0,
        'motor': 'off',
        'hon': true,
      };

      final status = WearableDeviceStatus.fromJson(json);
      expect(status.isPowerOn, isFalse);
      expect(status.heatLevel, WearableHeatLevel.off);
      expect(status.motorMode, WearableMotorMode.off);
      expect(status.isHeaterActive, isTrue);
      expect(status.isMotorActive, isFalse);
    });
  });

  group('BleService UUIDs & Architecture', () {
    test('UUID constants match firmware specification', () {
      expect(BleService.serviceUuid, '00000001-e099-4d24-a5e9-1152a2818987');
      expect(BleService.commandCharUuid, '00000002-e099-4d24-a5e9-1152a2818987');
      expect(BleService.statusCharUuid, '00000003-e099-4d24-a5e9-1152a2818987');
    });

    test('Initial service state is cleanly disconnected with safe defaults', () {
      final service = BleService();
      expect(service.isConnected, isFalse);
      expect(service.connectionStatus, BleConnectionStatus.disconnected);
      expect(service.deviceStatus.isPowerOn, isFalse);
      expect(service.deviceStatus.heatLevel, WearableHeatLevel.off);
      expect(service.deviceStatus.motorMode, WearableMotorMode.off);
      service.dispose();
    });
  });

  group('DeviceTelemetryCard Widget Tests', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected,
      WearableDeviceStatus deviceStatus = const WearableDeviceStatus(),
      bool isBusy = false,
      String? errorMessage,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bleConnectionStatusProvider.overrideWith((ref) => Stream.value(connectionStatus)),
            wearableStatusProvider.overrideWith((ref) => Stream.value(deviceStatus)),
            discoveredWearablesProvider.overrideWith((ref) => Stream.value(const [])),
            bleIsBusyProvider.overrideWith((ref) => Stream.value(isBusy)),
            bleErrorProvider.overrideWith((ref) => Stream.value(errorMessage)),
          ],
          child: MaterialApp(
            theme: MenoMateTheme.starryNightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(child: DeviceTelemetryCard()),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Disconnected state renders title, badge, and Connect button', (tester) async {
      await pumpCard(tester, connectionStatus: BleConnectionStatus.disconnected);

      expect(find.text('MenoMate Wearable'), findsOneWidget);
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Connect Device'), findsOneWidget);
      // Connected actuator controls are not rendered while disconnected
      expect(find.text('ALL OFF'), findsNothing);
      expect(find.text('Heating Level'), findsNothing);
      expect(find.text('Vibration Mode'), findsNothing);
    });

    testWidgets('Connected state with Master OFF renders controls in disabled state', (tester) async {
      await pumpCard(
        tester,
        connectionStatus: BleConnectionStatus.connected,
        deviceStatus: const WearableDeviceStatus(
          isConnected: true,
          isPowerOn: false,
          heatLevel: WearableHeatLevel.off,
          motorMode: WearableMotorMode.off,
        ),
      );

      expect(find.text('MenoMate Wearable'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('MASTER: OFF'), findsOneWidget);
      expect(find.text('ALL OFF'), findsOneWidget);
      expect(find.text('Heating Level'), findsOneWidget);
      expect(find.text('Vibration Mode'), findsOneWidget);

      // Verify heat options exist (OFF, LOW, MEDIUM, HIGH)
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);

      // Verify motor options exist (OFF, STEADY, WAVE)
      expect(find.text('STEADY'), findsOneWidget);
      expect(find.text('WAVE'), findsOneWidget);
      // Pulse must NOT be present
      expect(find.text('PULSE'), findsNothing);
      expect(find.text('TAP'), findsNothing);

      // Temperature in Celsius must NOT be shown
      expect(find.textContaining('°C'), findsNothing);
    });

    testWidgets('Connected state with Master ON renders active relay indicators', (tester) async {
      await pumpCard(
        tester,
        connectionStatus: BleConnectionStatus.connected,
        deviceStatus: const WearableDeviceStatus(
          isConnected: true,
          isPowerOn: true,
          heatLevel: WearableHeatLevel.medium,
          motorMode: WearableMotorMode.wave,
          isHeaterActive: true,
          isMotorActive: false,
        ),
      );

      expect(find.text('MASTER: ON'), findsOneWidget);
      expect(find.text('● Relay Closed (Heating)'), findsOneWidget);
      expect(find.text('○ Motor Resting'), findsOneWidget);
    });

    testWidgets('Emergency ALL OFF button is visible and tappable when connected', (tester) async {
      await pumpCard(
        tester,
        connectionStatus: BleConnectionStatus.connected,
        deviceStatus: const WearableDeviceStatus(
          isConnected: true,
          isPowerOn: true,
          heatLevel: WearableHeatLevel.high,
          motorMode: WearableMotorMode.steady,
        ),
      );

      final allOffBtn = find.text('ALL OFF');
      expect(allOffBtn, findsOneWidget);
      await tester.tap(allOffBtn);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Error message renders banner with descriptive text', (tester) async {
      await pumpCard(
        tester,
        connectionStatus: BleConnectionStatus.disconnected,
        errorMessage: 'Bluetooth adapter unavailable',
      );

      expect(find.text('Bluetooth adapter unavailable'), findsOneWidget);
    });
  });
}

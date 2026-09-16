import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/daily_log_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/daily_log.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/symptom_logger_screen.dart';
import 'package:menomate_mobile/services/api_service.dart';

import 'offline_fake_api.dart';

/// Structured logging truthfulness: catalog, severity, discharge,
/// pain/mood/flow null semantics, persistence, sync, UI toggles.
void main() {
  // Mirrors backend SUPPORTED_SYMPTOM_IDS (pinned by
  // test_logs.py::test_symptom_catalog_ids_stable — update together).
  const backendSymptomIds = {
    'cramps', 'headache', 'back_pain', 'nausea', 'bloating', 'low_energy',
    'breast_tenderness', 'acne', 'sleep_difficulty', 'appetite_change',
    'dizziness',
  };

  group('catalog + serialization', () {
    test('mobile catalog matches the canonical backend set exactly', () {
      expect(kLoggableSymptoms.map((s) => s.id).toSet(), backendSymptomIds);
      expect(kLoggableSymptoms, hasLength(11));
    });

    test('SymptomItem round-trips severity', () {
      const item = SymptomItem(symptomType: 'cramps', severity: 6);
      final back = SymptomItem.fromJson(item.toJson());
      expect(back.symptomType, 'cramps');
      expect(back.severity, 6);
    });

    test('unset pain is omitted from the payload; explicit 0 is sent', () {
      final unset = DailyLogCreate(logDate: '2026-09-10', mood: 'calm');
      expect(unset.toJson().containsKey('pain'), isFalse);

      final zero = DailyLogCreate(logDate: '2026-09-10', pain: 0);
      expect(zero.toJson()['pain'], 0);
    });

    test('symptoms and discharge serialize', () {
      final payload = DailyLogCreate(
        logDate: '2026-09-10',
        pain: 6,
        discharge: 'light',
        symptoms: const [SymptomItem(symptomType: 'cramps', severity: 6)],
      );
      final json = payload.toJson();
      expect(json['discharge'], 'light');
      expect(json['symptoms'], [
        {'symptom_type': 'cramps', 'severity': 6}
      ]);
    });

    test('response parses null pain', () {
      final res = DailyLogResponse.fromJson({
        'id': 1,
        'user_id': 'u',
        'log_date': '2026-09-10',
        'pain': null,
        'symptoms': [],
        'created_at': '2026-09-10T00:00:00Z',
        'updated_at': '2026-09-10T00:00:00Z',
      });
      expect(res.pain, isNull);
    });
  });

  group('repository persistence + sync', () {
    test('save/load round-trips symptoms, severity, discharge, null pain',
        () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = DailyLogRepository(db, api);

      final state = await repo.saveLog(
        'user-a',
        DailyLogCreate(
          logDate: '2026-09-10',
          mood: 'tired',
          flow: 'light',
          discharge: 'light',
          symptoms: const [
            SymptomItem(symptomType: 'cramps', severity: 6),
            SymptomItem(symptomType: 'headache', severity: 3),
          ],
        ),
      );
      expect(state, isA<Fresh<DailyLogResponse>>());

      final loaded = await repo.loadLog('user-a', '2026-09-10');
      final log = loaded.dataOrNull!;
      expect(log.pain, isNull);
      expect(log.discharge, 'light');
      expect(
        {for (final s in log.symptoms) s.symptomType: s.severity},
        {'cramps': 6, 'headache': 3},
      );
    });

    test('sync payload carries symptoms to the server', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = DailyLogRepository(db, api);

      await repo.saveLog(
        'user-a',
        DailyLogCreate(
          logDate: '2026-09-10',
          pain: 5,
          symptoms: const [SymptomItem(symptomType: 'nausea', severity: 4)],
        ),
      );
      final server = api.serverLogs['2026-09-10']!;
      expect(server.symptoms.single.symptomType, 'nausea');
      expect(server.symptoms.single.severity, 4);
    });

    test('editing a day replaces symptoms wholesale', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = DailyLogRepository(db, api);

      await repo.saveLog(
        'user-a',
        DailyLogCreate(
          logDate: '2026-09-10',
          symptoms: const [SymptomItem(symptomType: 'cramps', severity: 6)],
        ),
      );
      await repo.saveLog(
        'user-a',
        DailyLogCreate(
          logDate: '2026-09-10',
          symptoms: const [SymptomItem(symptomType: 'headache', severity: 2)],
        ),
      );
      final loaded = await repo.loadLog('user-a', '2026-09-10');
      expect(
        loaded.dataOrNull!.symptoms.map((s) => s.symptomType).toList(),
        ['headache'],
      );
    });

    test('offline save stays pending with full content', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = DailyLogRepository(db, api);

      final state = await repo.saveLog(
        'user-a',
        DailyLogCreate(
          logDate: '2026-09-10',
          discharge: 'moderate',
          symptoms: const [SymptomItem(symptomType: 'bloating', severity: 5)],
        ),
      );
      expect(state, isA<PendingSync<DailyLogResponse>>());
      final local = state.dataOrNull!;
      expect(local.discharge, 'moderate');
      expect(local.symptoms.single.symptomType, 'bloating');
    });

    test('mood/flow set, clear, and none round-trip', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = DailyLogRepository(db, api);

      await repo.saveLog(
          'user-a', DailyLogCreate(logDate: '2026-09-10', mood: 'happy', flow: 'none'));
      var loaded = await repo.loadLog('user-a', '2026-09-10');
      expect(loaded.dataOrNull!.mood, 'happy');
      expect(loaded.dataOrNull!.flow, 'none');

      await repo.saveLog(
          'user-a', DailyLogCreate(logDate: '2026-09-10', pain: 2));
      loaded = await repo.loadLog('user-a', '2026-09-10');
      // Full-replace upsert: omitted optionals clear.
      expect(loaded.dataOrNull!.mood, isNull);
      expect(loaded.dataOrNull!.flow, isNull);
      expect(loaded.dataOrNull!.pain, 2);
    });
  });

  group('logger screen toggles', () {
    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
    }

    Future<void> tapSave(WidgetTester tester) async {
      // Let any previous SnackBar expire so it cannot cover the button.
      await tester.pump(const Duration(seconds: 5));
      await tapVisible(tester, find.text('Save Log'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> pumpLogger(
        WidgetTester tester, AppDatabase db, FakeApiService api) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            apiServiceProvider.overrideWithValue(api),
            currentUserIdProvider.overrideWithValue('user-a'),
            profileProvider.overrideWith(() => _QuietProfileNotifier()),
          ],
          child: const MaterialApp(home: SymptomLoggerScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mood tap selects, second tap clears', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await pumpLogger(tester, db, FakeApiService());

      await tapVisible(tester, find.text('Happy'));
      await tapSave(tester);

      var row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.mood, 'happy');

      // Form reset after create: select again, then tapping the
      // selected value clears it.
      await tapVisible(tester, find.text('Happy'));
      await tapVisible(tester, find.text('Happy'));
      await tapSave(tester);

      row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.mood, isNull);
    });

    testWidgets('flow none is selectable; pain toggles to unset', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await pumpLogger(tester, db, FakeApiService());

      // 'None' exists in both Flow and Discharge sections; Flow comes
      // first, so .first is the flow option.
      await tapVisible(tester, find.text('None').first);
      // Select then immediately deselect pain: unset, not zero.
      await tapVisible(tester, find.text('5'));
      await tapVisible(tester, find.text('5'));
      await tapSave(tester);

      final row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.flow, 'none');
      expect(row.pain, isNull);
    });

    testWidgets('symptom select + severity stepper + discharge persist',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpLogger(tester, db, api);

      await tapVisible(tester, find.text('Cramps'));
      // Severity stepper appears for the selected symptom.
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline).first);
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline).first);
      // 'Moderate' is unique to the Discharge section.
      await tapVisible(tester, find.text('Moderate'));
      await tapSave(tester);

      final symptoms = await db.select(db.localSymptoms).get();
      expect(symptoms, hasLength(1));
      expect(symptoms.single.symptomType, 'cramps');
      expect(symptoms.single.severity, 2);
      expect(api.serverLogs.values.single.symptoms.single.severity, 2);
      final row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.discharge, 'moderate');
    });
  });
}

class _QuietProfileNotifier extends ProfileNotifier {
  @override
  Future<DataState<Profile?>> build() async => const NoData<Profile?>();
}

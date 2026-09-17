import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
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
      final unset = DailyLogCreate(logDate: '2026-09-10', mood: ['calm']);
      expect(unset.toJson().containsKey('pain'), isFalse);

      final zero = DailyLogCreate(logDate: '2026-09-10', pain: 0);
      expect(zero.toJson()['pain'], 0);
    });

    test('fully empty create serializes to date + empty symptoms only', () {
      final json = DailyLogCreate(logDate: '2026-09-10').toJson();
      expect(json.keys, unorderedEquals(['log_date', 'symptoms']));
      expect(json['symptoms'], isEmpty);
    });

    test('mood serializes as a list; empty means omitted', () {
      expect(
        DailyLogCreate(logDate: '2026-09-10', mood: ['happy', 'calm']).toJson()['mood'],
        ['happy', 'calm'],
      );
      expect(
        DailyLogCreate(logDate: '2026-09-10', mood: []).toJson().containsKey('mood'),
        isFalse,
      );
      expect(
        DailyLogCreate(logDate: '2026-09-10').toJson().containsKey('mood'),
        isFalse,
      );
    });

    test('mood codec tolerates legacy bare strings', () {
      expect(parseMoods(null), isNull);
      expect(parseMoods(''), isNull);
      expect(parseMoods('happy'), ['happy']);
      expect(parseMoods('["happy", "calm"]'), ['happy', 'calm']);
      expect(parseMoods(['tired']), ['tired']);
      expect(encodeMoods(null), isNull);
      expect(encodeMoods([]), isNull);
      expect(encodeMoods(['sad']), '["sad"]');
    });

    test('symptoms and discharge serialize', () {
      final payload = DailyLogCreate(
        logDate: '2026-09-10',
        pain: 6,
        discharge: 'creamy',
        symptoms: const [SymptomItem(symptomType: 'cramps', severity: 6)],
      );
      final json = payload.toJson();
      expect(json['discharge'], 'creamy');
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
          mood: ['tired'],
          flow: 'light',
          discharge: 'creamy',
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
      expect(log.discharge, 'creamy');
      expect(log.mood, ['tired']);
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
          discharge: 'creamy',
          symptoms: const [SymptomItem(symptomType: 'bloating', severity: 5)],
        ),
      );
      expect(state, isA<PendingSync<DailyLogResponse>>());
      final local = state.dataOrNull!;
      expect(local.discharge, 'creamy');
      expect(local.symptoms.single.symptomType, 'bloating');
    });

    test('mood/flow multi set, clear round-trip (no synthetic none)', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = DailyLogRepository(db, api);

      await repo.saveLog(
          'user-a',
          DailyLogCreate(
              logDate: '2026-09-10', mood: ['happy', 'calm'], flow: 'light'));
      var loaded = await repo.loadLog('user-a', '2026-09-10');
      expect(loaded.dataOrNull!.mood, ['happy', 'calm']);
      expect(loaded.dataOrNull!.flow, 'light');

      await repo.saveLog(
          'user-a', DailyLogCreate(logDate: '2026-09-10', pain: 2));
      loaded = await repo.loadLog('user-a', '2026-09-10');
      // Full-replace upsert: omitted optionals clear to unset (null),
      // never to a synthetic "none" value.
      expect(loaded.dataOrNull!.mood, isNull);
      expect(loaded.dataOrNull!.flow, isNull);
      expect(loaded.dataOrNull!.pain, 2);
    });

    test('legacy bare-string mood row decodes to a single selection', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = DailyLogRepository(db, api);

      // Simulate a pre-list row written by an older client.
      await db.into(db.localDailyLogs).insert(
            LocalDailyLogsCompanion.insert(
              userId: 'user-a',
              logDate: '2026-09-10',
              mood: const Value('happy'),
            ),
          );
      final loaded = await repo.loadLog('user-a', '2026-09-10');
      expect(loaded.dataOrNull!.mood, ['happy']);
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

    testWidgets('mood multi-select toggles independently; empty is valid',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await pumpLogger(tester, db, FakeApiService());

      await tapVisible(tester, find.text('Happy'));
      await tapVisible(tester, find.text('Calm'));
      await tapSave(tester);

      var row = await (db.select(db.localDailyLogs)).getSingle();
      expect(parseMoods(row.mood), ['happy', 'calm']);

      // Form reset after create: select Happy+Calm again, then tapping
      // Happy alone deselects just it (multi-select toggles), then
      // deselecting Calm too leaves zero moods (valid empty state).
      await tapVisible(tester, find.text('Happy'));
      await tapVisible(tester, find.text('Calm'));
      await tapVisible(tester, find.text('Happy'));
      await tapVisible(tester, find.text('Calm'));
      await tapSave(tester);

      row = await (db.select(db.localDailyLogs)).getSingle();
      expect(parseMoods(row.mood), isNull);
    });

    testWidgets('flow single-select replaces; reselect deselects; no None',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await pumpLogger(tester, db, FakeApiService());

      // No "None" option exists anywhere on the reworked screen.
      expect(find.text('None'), findsNothing);

      await tapVisible(tester, find.text('Light'));
      await tapVisible(tester, find.text('Heavy'));
      await tapSave(tester);

      var row = await (db.select(db.localDailyLogs)).getSingle();
      // Heavy replaced Light: multiple flow values impossible.
      expect(row.flow, 'heavy');
      // Zero symptoms selected serializes to an empty list.
      expect(await db.select(db.localSymptoms).get(), isEmpty);

      // Form reset after create: select Heavy, then reselecting the
      // selected option deselects it (empty = unset).
      await tapVisible(tester, find.text('Heavy'));
      await tapVisible(tester, find.text('Heavy'));
      await tapSave(tester);

      row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.flow, isNull);
    });

    testWidgets('discharge single-select uses qualitative vocabulary',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await pumpLogger(tester, db, FakeApiService());

      for (final label in ['Sticky', 'Creamy', 'Watery', 'Slippery / Stretchy']) {
        expect(find.text(label), findsOneWidget);
      }
      // Old amount vocabulary is gone, and no None option exists.
      expect(find.text('Moderate'), findsNothing);
      expect(find.text('None'), findsNothing);

      await tapVisible(tester, find.text('Creamy'));
      await tapVisible(tester, find.text('Watery'));
      await tapSave(tester);

      var row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.discharge, 'watery');

      await tapVisible(tester, find.text('Watery'));
      await tapVisible(tester, find.text('Watery'));
      await tapSave(tester);

      row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.discharge, isNull);
    });

    testWidgets('pain slider sets exact value; Clear returns to unset',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await pumpLogger(tester, db, FakeApiService());

      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('Clear'), findsNothing);

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      // Tap at 60% of the track width (recomputed after scrolling into
      // view): value 6 on the 0–10 scale.
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      Future<void> tapSliderAtSix() async {
        final sliderSize = tester.getSize(slider);
        final sliderCenter = tester.getCenter(slider);
        await tester.tapAt(Offset(
          sliderCenter.dx - sliderSize.width / 2 + sliderSize.width * 0.6,
          sliderCenter.dy,
        ));
        await tester.pump();
      }

      await tapSliderAtSix();
      await tapSave(tester);

      var row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.pain, 6);

      // Form reset after create: log 6 again so the Clear control exists,
      // then Clear returns to unset (badge back to "Not logged").
      await tapSliderAtSix();
      await tapVisible(tester, find.text('Clear'));
      await tapSave(tester);

      row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.pain, isNull);
      expect(find.text('Not logged'), findsOneWidget);
    });

    testWidgets('symptom select + severity stepper + discharge persist',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpLogger(tester, db, api);

      await tapVisible(tester, find.text('Cramps'));
      await tapVisible(tester, find.text('Headache'));
      // Deselect Headache again: multi-select toggles independently.
      await tapVisible(tester, find.text('Headache'));
      // Severity stepper appears for the selected symptom.
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline).first);
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline).first);
      await tapVisible(tester, find.text('Creamy'));
      await tapSave(tester);

      final symptoms = await db.select(db.localSymptoms).get();
      expect(symptoms, hasLength(1));
      expect(symptoms.single.symptomType, 'cramps');
      expect(symptoms.single.severity, 2);
      expect(api.serverLogs.values.single.symptoms.single.severity, 2);
      final row = await (db.select(db.localDailyLogs)).getSingle();
      expect(row.discharge, 'creamy');
    });

    testWidgets('narrow layout: no overflow, chips wrap, save reachable',
        (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            apiServiceProvider.overrideWithValue(FakeApiService()),
            currentUserIdProvider.overrideWithValue('user-a'),
            profileProvider.overrideWith(() => _QuietProfileNotifier()),
          ],
          child: const MaterialApp(home: SymptomLoggerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Long labels wrap without overflow; every section is present.
      expect(find.text('Slippery / Stretchy'), findsOneWidget);
      expect(find.text('Daily Check-In'), findsOneWidget);

      await tester.ensureVisible(find.text('Save Log'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Save Log'), findsOneWidget);
    });
  });
}

class _QuietProfileNotifier extends ProfileNotifier {
  @override
  Future<DataState<Profile?>> build() async => const NoData<Profile?>();
}

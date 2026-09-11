import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/services/api_service.dart';
import 'package:menomate_mobile/widgets/period_tracker_button.dart';

import 'offline_fake_api.dart';

const _userId = 'user-a';

String _iso(DateTime d) => toIsoDate(d);

DateTime _day(int daysAgo) {
  final n = DateTime.now();
  final t = DateTime(n.year, n.month, n.day);
  return t.subtract(Duration(days: daysAgo));
}

/// Retrospective period-end logging: a user who forgot to record the end
/// supplies the actual historical date. Same local row, same identity,
/// existing backend contract, no inferred dates.
void main() {
  // Online historical end-date correction: one row, correct dates.
  test('online historical end updates the same synced row', () async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    final repo = CycleRepository(db, api);
    final start = _iso(_day(10));
    final end = _iso(_day(6));

    await repo.startPeriod(_userId, start);
    final state = await repo.endOngoingPeriod(_userId, end);

    expect(api.serverCycles.length, 1);
    expect(api.serverCycles.single.periodStart, DateTime.parse(start));
    expect(api.serverCycles.single.periodEnd, DateTime.parse(end));
    final rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userId)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.periodEnd, end);
    expect(rows.single.syncState, SyncState.synced);
    expect(rows.single.serverId, isNotNull);
    expect(state, isA<Fresh>());
  });

  // Offline historical end: local-first, pending, then one synced row.
  test('offline historical end stays pending then syncs once', () async {
    final db = AppDatabase.memory();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);
    final repo = CycleRepository(db, api);
    final start = _iso(_day(6));
    final end = _iso(_day(3));

    await repo.startPeriod(_userId, start);
    final saved = await repo.endOngoingPeriod(_userId, end);

    expect(saved, isA<PendingSync>());
    var rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userId)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.periodEnd, end);
    expect(rows.single.syncState, SyncState.pending);

    api.offline = false;
    await repo.syncPending(_userId);
    expect(api.serverCycles.length, 1);
    expect(api.serverCycles.single.periodEnd, DateTime.parse(end));
    rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userId)))
        .get();
    expect(rows.single.syncState, SyncState.synced);
  });

  // Invalid end date before start: rejected, row untouched, no push.
  test('end date before start is rejected without server write', () async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    final repo = CycleRepository(db, api);
    final start = _iso(_day(5));

    await repo.startPeriod(_userId, start);
    final callsBefore = api.createCycleCalls + api.patchCycleCalls;
    final state = await repo.endOngoingPeriod(_userId, _iso(_day(8)));

    expect(state, isA<ConflictState>());
    expect(api.createCycleCalls + api.patchCycleCalls, callsBefore);
    final rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userId)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.periodEnd, isNull);
  });

  // Restart persistence of the corrected end date.
  test('corrected end date survives restart while offline', () async {
    final dir = await Directory.systemTemp.createTemp('mm_retro');
    addTearDown(() => dir.delete(recursive: true));
    AppDatabase openDb() =>
        AppDatabase(NativeDatabase(File('${dir.path}/t.db')));
    final api = FakeApiService()..offline = true;
    final start = _iso(_day(6));
    final end = _iso(_day(2));

    var db = openDb();
    final repo = CycleRepository(db, api);
    await repo.startPeriod(_userId, start);
    await repo.endOngoingPeriod(_userId, end);
    await db.close();

    db = openDb();
    addTearDown(db.close);
    final rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userId)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.periodEnd, end);
    final view =
        (await CycleRepository(db, api).loadCurrent(_userId)).dataOrNull!;
    expect(view.isOngoing, isFalse);
    expect(view.latestPeriodEnd, DateTime.parse(end));
  });

  // Repeated sync: exactly one server cycle with correct dates.
  test('repeated sync keeps exactly one corrected server cycle', () async {
    final db = AppDatabase.memory();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);
    final repo = CycleRepository(db, api);

    await repo.startPeriod(_userId, _iso(_day(9)));
    await repo.endOngoingPeriod(_userId, _iso(_day(5)));
    api.offline = false;
    await repo.syncPending(_userId);
    await repo.syncPending(_userId);
    await repo.syncPending(_userId);

    expect(api.createCycleCalls, 1);
    expect(api.serverCycles.length, 1);
    expect(api.serverCycles.single.periodStart, DateTime.parse(_iso(_day(9))));
    expect(api.serverCycles.single.periodEnd, DateTime.parse(_iso(_day(5))));
  });

  // History/calendar + no-longer-ongoing after correction.
  test('corrected cycle appears completed in history and current state',
      () async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    final repo = CycleRepository(db, api);
    final start = _iso(_day(10));
    final end = _iso(_day(6));

    await repo.startPeriod(_userId, start);
    await repo.endOngoingPeriod(_userId, end);

    final current = (await repo.loadCurrent(_userId)).dataOrNull!;
    expect(current.isOngoing, isFalse);
    expect(current.isBleeding, isFalse);
    expect(current.latestPeriodEnd, DateTime.parse(end));

    final history = (await repo.loadHistory(_userId)).dataOrNull!;
    expect(history.history.length, 1);
    expect(history.history.single.periodEnd, DateTime.parse(end));
    expect(history.history.single.periodLengthDays, 5);

    final cycles = (await repo.loadCycles(_userId)).dataOrNull!;
    expect(cycles.length, 1);
    expect(cycles.single.periodEnd, DateTime.parse(end));
  });

  // Widget: affordance visible while ongoing; picker submits the correction.
  testWidgets('forgot-to-log affordance corrects the end date', (tester) async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    final start = _day(4);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiServiceProvider.overrideWith((ref) => api),
          currentUserIdProvider.overrideWithValue(_userId),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PeriodTrackerButton(
              isOngoing: true,
              ongoingStart: start,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The retrospective path is discoverable on the existing control.
    expect(find.text('Forgot to log when it ended?'), findsOneWidget);

    // Seed the ongoing row the picker flow will correct.
    final repo = CycleRepository(db, api);
    await repo.startPeriod(_userId, _iso(start));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot to log when it ended?'));
    await tester.pumpAndSettle();
    expect(find.text('When did your period end?'), findsOneWidget);

    // Accept the default (today) to prove picker-to-submit wiring.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Period marked as ended today.'), findsOneWidget);
    expect(api.serverCycles.length, 1);
    expect(api.serverCycles.single.periodStart, DateTime.parse(_iso(start)));
    final today = _day(0);
    expect(api.serverCycles.single.periodEnd, DateTime.parse(_iso(today)));
  });

  // Widget: no retrospective affordance when nothing is ongoing.
  testWidgets('no correction affordance when period is not ongoing',
      (tester) async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiServiceProvider.overrideWith((ref) => api),
          currentUserIdProvider.overrideWithValue(_userId),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PeriodTrackerButton(isOngoing: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Forgot to log when it ended?'), findsNothing);
    expect(find.text('Log Period Started Today'), findsOneWidget);
  });
}

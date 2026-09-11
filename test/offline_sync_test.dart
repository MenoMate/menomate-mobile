import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/repositories/daily_log_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/daily_log.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/theme_provider.dart';

import 'offline_fake_api.dart';

/// Test-only constructor helper (keeps server fixtures readable).
extension CycleResponseShim on CycleResponse {
  static CycleResponse cycle(
    int id,
    String start,
    String? end,
    DateTime now,
    String userId,
  ) {
    return CycleResponse(
      id: id,
      userId: userId,
      periodStart: DateTime.parse(start),
      periodEnd: end == null ? null : DateTime.parse(end),
      periodLengthDays: end == null
          ? null
          : DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1,
      createdAt: now,
      updatedAt: now,
    );
  }
}

const _userA = 'user-a';
const _userB = 'user-b';

AppDatabase _memoryDb() => AppDatabase.memory();

Future<void> _seedSyncedCycles(
  AppDatabase db,
  String userId,
  List<(String, String?)> periods,
) async {
  for (final (start, end) in periods) {
    await db.into(db.localCycles).insert(LocalCyclesCompanion.insert(
          localId: 'seed-$userId-$start',
          userId: userId,
          periodStart: start,
          periodEnd: Value(end),
          syncState: const Value(SyncState.synced),
        ));
  }
}

void main() {
  // (1) Offline history read: existing local history displays without network.
  test('offline history read shows local data as cached, not empty', () async {
    final db = _memoryDb();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);
    await _seedSyncedCycles(db, _userA, const [
      ('2026-07-01', '2026-07-05'),
      ('2026-07-29', '2026-08-02'),
    ]);

    final repo = CycleRepository(db, api);
    final state = await repo.loadHistory(_userA);

    expect(state, isA<Cached>());
    final view = state.dataOrNull!;
    expect(view.totalPeriodsLogged, 2);
    expect(view.history.length, 2);
  });

  // (2) No-data vs unavailable: network failure with no local data is NOT
  // rendered as "no history".
  test('network failure with no local data yields Unavailable, not NoData',
      () async {
    final db = _memoryDb();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);

    final repo = CycleRepository(db, api);
    final history = await repo.loadHistory(_userA);
    final current = await repo.loadCurrent(_userA);
    final cycles = await repo.loadCycles(_userA);

    expect(history, isA<Unavailable>());
    expect(current, isA<Unavailable>());
    expect(cycles, isA<Unavailable>());
    expect(history.dataOrNull, isNull);
  });

  // (3) Offline daily-log create: saves locally, persists, stays pending.
  test('offline daily-log create persists locally as pending', () async {
    final db = _memoryDb();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);

    final repo = DailyLogRepository(db, api);
    final state = await repo.saveLog(
      _userA,
      DailyLogCreate(logDate: '2026-08-10', pain: 5, mood: 'tired'),
    );

    expect(state, isA<PendingSync>());
    expect(state.dataOrNull!.pain, 5);
    final rows = await (db.select(db.localDailyLogs)
          ..where((t) => t.userId.equals(_userA)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.syncState, SyncState.pending);
  });

  // (4) Offline daily-log edit converges to one server record on sync.
  test('offline edits to same date converge to one synced server record',
      () async {
    final db = _memoryDb();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);

    final repo = DailyLogRepository(db, api);
    await repo.saveLog(
        _userA, DailyLogCreate(logDate: '2026-08-10', pain: 3));
    await repo.saveLog(
        _userA, DailyLogCreate(logDate: '2026-08-10', pain: 7));

    final localRows = await (db.select(db.localDailyLogs)
          ..where((t) => t.userId.equals(_userA)))
        .get();
    expect(localRows.length, 1);

    api.offline = false;
    await repo.syncPending(_userA);

    expect(api.serverLogs.length, 1);
    expect(api.serverLogs['2026-08-10']!.pain, 7);
    expect(api.upsertLogCalls, 1);
    final after = await (db.select(db.localDailyLogs)
          ..where((t) => t.userId.equals(_userA)))
        .get();
    expect(after.single.syncState, SyncState.synced);
  });

  // (5) Restart persistence: file-backed DB survives close/reopen offline.
  test('offline data survives database close and reopen', () async {
    final dir = await Directory.systemTemp.createTemp('mm_offline');
    addTearDown(() => dir.delete(recursive: true));
    AppDatabase openDb() =>
        AppDatabase(NativeDatabase(File('${dir.path}/t.db')));

    final api = FakeApiService()..offline = true;
    var db = openDb();
    final repo = DailyLogRepository(db, api);
    await repo.saveLog(
        _userA, DailyLogCreate(logDate: '2026-08-10', pain: 4));
    final cycles = CycleRepository(db, api);
    await cycles.startPeriod(_userA, '2026-08-01');
    await db.close();

    db = openDb();
    addTearDown(db.close);
    final logState = await DailyLogRepository(db, api)
        .loadLog(_userA, '2026-08-10');
    final cycleState =
        await CycleRepository(db, api).loadCycles(_userA);

    expect(logState, isA<PendingSync>());
    expect(logState.dataOrNull!.pain, 4);
    expect(cycleState.dataOrNull!.length, 1);
  });

  // (6)+(7) Offline start/end/restart/sync yields exactly one server cycle;
  // repeated syncs never duplicate.
  test('offline start, end, restart, sync reconciles one server cycle',
      () async {
    final dir = await Directory.systemTemp.createTemp('mm_cycle');
    addTearDown(() => dir.delete(recursive: true));
    AppDatabase openDb() =>
        AppDatabase(NativeDatabase(File('${dir.path}/t.db')));
    final api = FakeApiService()..offline = true;

    var db = openDb();
    final repo = CycleRepository(db, api);
    await repo.startPeriod(_userA, '2026-08-01');
    await repo.endOngoingPeriod(_userA, '2026-08-05');
    await db.close();

    db = openDb();
    addTearDown(db.close);
    final repo2 = CycleRepository(db, api);
    var rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userA)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.periodEnd, '2026-08-05');
    expect(rows.single.syncState, SyncState.pending);

    api.offline = false;
    await repo2.syncPending(_userA);
    // Repeat the pass: must not create duplicates.
    await repo2.syncPending(_userA);

    expect(api.serverCycles.length, 1);
    expect(api.createCycleCalls, 1);
    expect(api.serverCycles.single.periodEnd, DateTime(2026, 8, 5));
    rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userA)))
        .get();
    expect(rows.length, 1);
    expect(rows.single.syncState, SyncState.synced);
    expect(rows.single.serverId, isNotNull);
  });

  // (8) Conflict marks only that item; later independent rows still sync.
  test('400/409 conflict flags one row while later rows sync', () async {
    final db = _memoryDb();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);
    api.conflictStarts.add('2026-06-01');

    final repo = CycleRepository(db, api);
    await repo.startPeriod(_userA, '2026-06-01');
    await repo.endOngoingPeriod(_userA, '2026-06-05');
    await repo.startPeriod(_userA, '2026-07-01');

    api.offline = false;
    await repo.syncPending(_userA);

    final rows = await (db.select(db.localCycles)
          ..where((t) => t.userId.equals(_userA))
          ..orderBy([(t) => OrderingTerm.asc(t.periodStart)]))
        .get();
    expect(rows.length, 2);
    expect(rows[0].syncState, SyncState.conflict);
    expect(rows[1].syncState, SyncState.synced);
    expect(api.serverCycles.length, 1);
  });

  // (9) User isolation: A offline data, sign out (wipe), B sees nothing.
  test('sign-out wipe prevents cross-user local visibility', () async {
    final db = _memoryDb();
    final api = FakeApiService();
    addTearDown(db.close);

    await _seedSyncedCycles(db, _userA, const [
      ('2026-07-01', '2026-07-05'),
    ]);
    await DailyLogRepository(db, api).saveLog(
        _userA, DailyLogCreate(logDate: '2026-08-10', pain: 2));

    await db.clearAllUserData();

    api.offline = true;
    final cycles = CycleRepository(db, api);
    expect(await cycles.loadCycles(_userB), isA<Unavailable>());
    expect(await cycles.loadHistory(_userB), isA<Unavailable>());
    expect(
        await DailyLogRepository(db, api).loadLog(_userB, '2026-08-10'),
        isA<Unavailable>());
    expect(await db.select(db.localCycles).get(), isEmpty);
    expect(await db.select(db.localDailyLogs).get(), isEmpty);
    expect(await db.select(db.localSymptoms).get(), isEmpty);
    expect(await db.select(db.localProfiles).get(), isEmpty);
    expect(await db.select(db.predictionCache).get(), isEmpty);
  });

  // (11) Calendar offline: local cycles render; cached prediction passes
  // through verbatim (display only — no local prediction calculation).
  //
  // REVIEW CHECKLIST (verification by inspection, per locked plan):
  // - history_tab.dart _buildCalendarCell reads only the local cycle list
  //   + CurrentCycleResponse.predictedNextPeriod/averagePeriodLength.
  // - cycle_repository._assembleCurrent copies cache fields verbatim into
  //   the view; the only date math is isoDayDifference for the Day N label
  //   and observed history-tile intervals (display-only, never prediction).
  // - grep `lib/` for prediction keywords outside services/models/data
  //   fixtures to confirm no second algorithm exists.
  test('offline calendar uses local cycles plus verbatim cached prediction',
      () async {
    final db = _memoryDb();
    final api = FakeApiService();
    addTearDown(db.close);
    final now = DateTime.now();
    api.serverCycles.addAll([
      CycleResponseShim.cycle(
          1, '2026-07-01', '2026-07-05', now, _userA),
      CycleResponseShim.cycle(
          2, '2026-07-29', '2026-08-02', now, _userA),
    ]);

    final repo = CycleRepository(db, api);
    await repo.loadCycles(_userA);
    await repo.loadCurrent(_userA);

    api.offline = true;
    final cycles = await repo.loadCycles(_userA);
    final current = await repo.loadCurrent(_userA);

    expect(cycles.dataOrNull!.length, 2);
    final view = current.dataOrNull!;
    expect(view.predictedNextPeriod, DateTime(2026, 10, 1));
    expect(view.predictionConfidence, 'moderate');
    expect(view.predictionStatus, 'upcoming');
    expect(view.daysUntilNextPeriod, 10);
  });

  // (12) Theme persists locally and survives provider rebuilds.
  test('theme choice persists locally across restarts', () async {
    final db = _memoryDb();
    addTearDown(db.close);
    await db.into(db.localProfiles).insert(LocalProfilesCompanion.insert(
          userId: _userA,
          theme: const Value('dark'),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue(_userA),
    ]);
    addTearDown(container.dispose);

    // Hydrate runs on build via microtask.
    container.read(themeModeProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(themeModeProvider), ThemeMode.dark);

    container.read(themeModeProvider.notifier).toggleTheme(false);
    expect(container.read(themeModeProvider), ThemeMode.light);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final row = await (db.select(db.localProfiles)
          ..where((t) => t.userId.equals(_userA)))
        .getSingle();
    expect(row.theme, 'light');
    expect(row.syncState, SyncState.pending);
  });
}

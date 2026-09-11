import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/repositories/daily_log_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/daily_log.dart';

import 'offline_fake_api.dart';

/// Regression tests for real-device Phase 2 findings:
/// period-end state refresh, restart persistence, and daily-log
/// single-record guarantees.
void main() {
  String iso(DateTime d) => toIsoDate(d);
  DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // Period start -> end refreshes visible current state from the server.
  test('period end refreshes current state with server-derived values',
      () async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    const userId = 'user-a';
    final repo = CycleRepository(db, api);

    await repo.startPeriod(userId, '2026-08-01');
    var state = await repo.loadCurrent(userId);
    expect(state.dataOrNull!.isOngoing, isTrue);

    await repo.endOngoingPeriod(userId, '2026-08-05');
    state = await repo.loadCurrent(userId);

    final view = state.dataOrNull!;
    expect(view.isOngoing, isFalse);
    expect(view.isBleeding, isFalse);
    expect(view.latestPeriodEnd, DateTime(2026, 8, 5));
    // Server-derived phase from the refreshed cache (fake serves
    // 'follicular'); without the post-push refresh this stays 'unknown'.
    expect(view.phase, 'follicular');
  });

  // Restart after period end keeps the corrected factual state.
  test('restart after period end preserves corrected state', () async {
    final dir = await Directory.systemTemp.createTemp('mm_end_restart');
    addTearDown(() => dir.delete(recursive: true));
    AppDatabase openDb() =>
        AppDatabase(NativeDatabase(File('${dir.path}/t.db')));
    final api = FakeApiService()..offline = true;
    const userId = 'user-a';

    final start = iso(today().subtract(const Duration(days: 4)));
    final end = iso(today());
    var db = openDb();
    final repo = CycleRepository(db, api);
    await repo.startPeriod(userId, start);
    await repo.endOngoingPeriod(userId, end);
    await db.close();

    db = openDb();
    addTearDown(db.close);
    final view =
        (await CycleRepository(db, api).loadCurrent(userId)).dataOrNull!;

    expect(view.isOngoing, isFalse);
    expect(view.isBleeding, isFalse);
    expect(view.latestPeriodStart, DateTime.parse(start));
    expect(view.latestPeriodEnd, DateTime.parse(end));
    expect(view.currentCycleDay, 5);
  });

  // No duplicate daily log after repeated sync; latest values win.
  test('repeated sync keeps exactly one daily log record', () async {
    final db = AppDatabase.memory();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);
    const userId = 'user-a';
    final repo = DailyLogRepository(db, api);

    await repo.saveLog(
        userId, DailyLogCreate(logDate: '2026-08-10', pain: 3));
    await repo.saveLog(
        userId, DailyLogCreate(logDate: '2026-08-10', pain: 8));

    api.offline = false;
    await repo.syncPending(userId);
    await repo.syncPending(userId);
    await repo.syncPending(userId);

    expect(api.serverLogs.length, 1);
    expect(api.serverLogs['2026-08-10']!.pain, 8);
    expect(api.upsertLogCalls, 1);
    final local = await (db.select(db.localDailyLogs)
          ..where((t) => t.userId.equals(userId)))
        .get();
    expect(local.length, 1);
    expect(local.single.syncState, SyncState.synced);
  });

  // Offline create is locally visible, then syncs the same record.
  test('offline daily log is discoverable locally then syncs', () async {
    final db = AppDatabase.memory();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);
    const userId = 'user-a';
    final repo = DailyLogRepository(db, api);

    await repo.saveLog(userId,
        DailyLogCreate(logDate: '2026-08-10', pain: 6, notes: 'cramps'));

    final visible = await repo.loadLog(userId, '2026-08-10');
    expect(visible, isA<PendingSync>());
    expect(visible.dataOrNull!.notes, 'cramps');

    api.offline = false;
    await repo.syncPending(userId);
    final synced = await repo.loadLog(userId, '2026-08-10');
    expect(synced, isA<Fresh>());
    expect(api.serverLogs['2026-08-10']!.pain, 6);
  });
}

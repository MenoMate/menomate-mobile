import 'package:drift/drift.dart';

import '../../models/daily_log.dart';
import '../../services/api_service.dart';
import '../app_database.dart';
import '../sync_policy.dart';

/// Offline-capable daily logs + symptoms. Natural key (user_id, log_date)
/// matches the backend full-day upsert contract, so repeated offline edits
/// to the same date converge to exactly one server record holding the
/// latest local state. Symptom rows are replaced wholesale with the parent.
class DailyLogRepository {
  final AppDatabase db;
  final ApiService api;

  DailyLogRepository(this.db, this.api);

  Future<LocalDailyLog?> _localRow(String userId, String isoDate) {
    return (db.select(db.localDailyLogs)
          ..where((t) =>
              t.userId.equals(userId) & t.logDate.equals(isoDate)))
        .getSingleOrNull();
  }

  Future<List<LocalSymptom>> _localSymptoms(
    String userId,
    String isoDate,
  ) {
    return (db.select(db.localSymptoms)
          ..where((t) =>
              t.userId.equals(userId) & t.logDate.equals(isoDate)))
        .get();
  }

  DailyLogResponse _assemble(LocalDailyLog row, List<LocalSymptom> symptoms) {
    return DailyLogResponse(
      id: row.id,
      userId: row.userId,
      logDate: row.logDate,
      pain: row.pain,
      mood: parseMoods(row.mood),
      discharge: row.discharge,
      flow: row.flow,
      notes: row.notes,
      symptoms: [
        for (final s in symptoms)
          SymptomItem(symptomType: s.symptomType, severity: s.severity),
      ],
    );
  }

  Future<void> _storeLocal(
    String userId,
    DailyLogCreate payload,
    SyncState state,
  ) async {
    final isoDate = payload.logDate ?? todayIso();
    await db.transaction(() async {
      final existing = await _localRow(userId, isoDate);
      // Mood is stored encoded (JSON array string); decode tolerates
      // legacy bare-string rows.
      final encodedMood = encodeMoods(payload.mood);
      if (existing == null) {
        await db.into(db.localDailyLogs).insert(
              LocalDailyLogsCompanion.insert(
                userId: userId,
                logDate: isoDate,
                pain: Value(payload.pain),
                mood: Value(encodedMood),
                flow: Value(payload.flow),
                discharge: Value(payload.discharge),
                notes: Value(payload.notes),
                syncState: Value(state),
              ),
            );
      } else {
        await (db.update(db.localDailyLogs)
              ..where((t) =>
                  t.userId.equals(userId) & t.logDate.equals(isoDate)))
            .write(LocalDailyLogsCompanion(
          pain: Value(payload.pain),
          mood: Value(encodedMood),
          flow: Value(payload.flow),
          discharge: Value(payload.discharge),
          notes: Value(payload.notes),
          syncState: Value(state),
          updatedAt: Value(DateTime.now()),
        ));
      }
      await (db.delete(db.localSymptoms)
            ..where((t) =>
                t.userId.equals(userId) & t.logDate.equals(isoDate)))
          .go();
      for (final s in payload.symptoms) {
        await db.into(db.localSymptoms).insert(
              LocalSymptomsCompanion.insert(
                userId: userId,
                logDate: isoDate,
                symptomType: s.symptomType,
                severity: Value(s.severity),
              ),
            );
      }
    });
  }

  Future<void> _markState(String userId, String isoDate, SyncState state) {
    return (db.update(db.localDailyLogs)
          ..where(
              (t) => t.userId.equals(userId) & t.logDate.equals(isoDate)))
        .write(LocalDailyLogsCompanion(
      syncState: Value(state),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Local-first read: local row renders immediately; remote refresh
  /// replaces it when reachable. 404 with no local row is genuine no-data;
  /// transport failure with no local row is [Unavailable], never no-data.
  Future<DataState<DailyLogResponse?>> loadLog(
    String userId,
    String isoDate,
  ) async {
    final local = await _localRow(userId, isoDate);
    if (local == null) {
      try {
        final remote = await api.fetchDailyLog(isoDate);
        if (remote == null) return const NoData();
        await _storeFromResponse(userId, remote, SyncState.synced);
        return Fresh(remote);
      } on NetworkUnavailable catch (e) {
        return Unavailable(e.message);
      } on ServerError catch (e) {
        return Unavailable(e.message);
      } on AuthFailure {
        rethrow;
      } on Conflict {
        return const Unavailable('Server rejected the request.');
      }
    }
    final symptoms = await _localSymptoms(userId, isoDate);
    final view = _assemble(local, symptoms);
    try {
      final remote = await api.fetchDailyLog(isoDate);
      if (remote == null) {
        // Server has no record but local does (pending write): keep local.
        if (local.syncState == SyncState.conflict) {
          return ConflictState(view, 'This entry needs review.');
        }
        if (local.syncState == SyncState.pending) return PendingSync(view);
        return Cached(view, local.updatedAt);
      }
      await _storeFromResponse(userId, remote, SyncState.synced);
      final fresh = await _localRow(userId, isoDate);
      final freshSymptoms = await _localSymptoms(userId, isoDate);
      return Fresh(_assemble(fresh!, freshSymptoms));
    } on ApiError {
      if (local.syncState == SyncState.conflict) {
        return ConflictState(view, 'This entry needs review.');
      }
      if (local.syncState == SyncState.pending) return PendingSync(view);
      return Cached(view, local.updatedAt);
    }
  }

  Future<void> _storeFromResponse(
    String userId,
    DailyLogResponse remote,
    SyncState state,
  ) async {
    await _storeLocal(
      userId,
      DailyLogCreate(
        logDate: remote.logDate,
        pain: remote.pain,
        mood: remote.mood,
        discharge: remote.discharge,
        flow: remote.flow,
        symptoms: remote.symptoms,
        notes: remote.notes,
      ),
      state,
    );
  }

  /// Local-first save: persists locally (pending) before any network
  /// attempt, so the entry survives offline + restart. On 2xx the row is
  /// marked synced; on conflict only this date is flagged.
  Future<DataState<DailyLogResponse>> saveLog(
    String userId,
    DailyLogCreate payload,
  ) async {
    final isoDate = payload.logDate ?? todayIso();
    await _storeLocal(userId, payload, SyncState.pending);
    try {
      final remote = await api.upsertDailyLog(payload);
      await _storeFromResponse(userId, remote, SyncState.synced);
      return Fresh(remote);
    } on ApiError catch (e) {
      final row = await _localRow(userId, isoDate);
      final view = _assemble(row!, await _localSymptoms(userId, isoDate));
      final outcome = classifySyncError(e);
      if (e is AuthFailure) rethrow;
      if (outcome == SyncOutcome.conflict) {
        await _markState(userId, isoDate, SyncState.conflict);
        return ConflictState(view, e.message);
      }
      return PendingSync(view);
    }
  }

  /// Pushes pending dates oldest-first. Upsert-by-date is idempotent, so
  /// repeats converge. Continues past conflicts; stops on network/5xx/auth.
  Future<void> syncPending(String userId) async {
    final pending = await (db.select(db.localDailyLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.syncState.equals(SyncState.pending.index))
          ..orderBy([(t) => OrderingTerm.asc(t.logDate)]))
        .get();
    for (final row in pending) {
      final symptoms = await _localSymptoms(userId, row.logDate);
      try {
        final remote = await api.upsertDailyLog(DailyLogCreate(
          logDate: row.logDate,
          pain: row.pain,
          mood: parseMoods(row.mood),
          discharge: row.discharge,
          flow: row.flow,
          symptoms: [
            for (final s in symptoms)
              SymptomItem(symptomType: s.symptomType, severity: s.severity),
          ],
          notes: row.notes,
        ));
        await _storeFromResponse(userId, remote, SyncState.synced);
      } on ApiError catch (e) {
        final outcome = classifySyncError(e);
        if (outcome == SyncOutcome.conflict) {
          await _markState(userId, row.logDate, SyncState.conflict);
          continue;
        }
        return;
      }
    }
  }
}

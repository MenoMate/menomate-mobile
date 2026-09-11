import 'dart:math';

import 'package:drift/drift.dart';

import '../../models/cycle.dart';
import '../../models/summary.dart';
import '../../services/api_service.dart';
import '../app_database.dart';
import '../sync_policy.dart';

String _newLocalId() {
  final r = Random.secure();
  return 'local_${DateTime.now().microsecondsSinceEpoch}_${r.nextInt(1 << 32)}';
}

/// Offline-capable cycle data: history, period start/end, calendar source,
/// and cached server prediction (display only).
///
/// Local-first: reads serve local rows immediately and refresh from remote
/// when reachable; writes mutate the local row first (marked pending) and
/// push afterwards. record-level `sync_state` is the only queue — there is
/// no separate outbox table.
///
/// Phase 1 freeze: this repository performs NO prediction calculation. All
/// predicted/confidence/phase values are verbatim server cache. The only
/// arithmetic on dates is display-only Day N / observed-interval labels.
class CycleRepository {
  final AppDatabase db;
  final ApiService api;

  CycleRepository(this.db, this.api);

  // ---------------------------------------------------------- reads

  Future<List<LocalCycle>> _localRows(String userId) {
    return (db.select(db.localCycles)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.periodStart)]))
        .get();
  }

  Future<PredictionCacheData?> _cache(String userId) {
    return (db.select(db.predictionCache)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  bool _hasConflict(List<LocalCycle> rows) =>
      rows.any((r) => r.syncState == SyncState.conflict);
  bool _hasPending(List<LocalCycle> rows) =>
      rows.any((r) => r.syncState == SyncState.pending);

  DateTime _fetchedAt(PredictionCacheData? cache, List<LocalCycle> rows) {
    if (cache != null) return cache.fetchedAt;
    if (rows.isNotEmpty) {
      // No server fetch ever recorded: fall back to the newest local
      // write time so `cached` stays honest about provenance.
      DateTime latest = rows.first.updatedAt;
      for (final r in rows) {
        if (r.updatedAt.isAfter(latest)) latest = r.updatedAt;
      }
      return latest;
    }
    return DateTime.now();
  }

  /// Assembles the current-cycle view from local rows + verbatim cache.
  CurrentCycleResponse? _assembleCurrent(
    List<LocalCycle> rows,
    PredictionCacheData? cache,
  ) {
    if (rows.isEmpty) return null;
    final today = todayIso();
    final observed =
        rows.where((r) => r.periodStart.compareTo(today) <= 0).toList();

    LocalCycle? ongoing;
    for (final r in rows.reversed) {
      if (r.periodEnd == null && r.periodStart.compareTo(today) <= 0) {
        ongoing = r;
        break;
      }
    }

    if (ongoing == null && observed.isEmpty) {
      // Only future user-entered periods exist: display them, predict nothing.
      final first = rows.first;
      final days = isoDayDifference(today, first.periodStart);
      return CurrentCycleResponse(
        hasData: true,
        currentCycleDay: null,
        phase: 'unknown',
        isBleeding: false,
        isOngoing: false,
        latestPeriodStart: parseIsoDate(first.periodStart),
        latestPeriodEnd: first.periodEnd == null
            ? null
            : parseIsoDate(first.periodEnd!),
        predictedCycleLength: null,
        predictedNextPeriod: parseIsoDate(first.periodStart),
        daysUntilNextPeriod: days,
        predictionStatus: days == 0 ? 'today' : 'upcoming',
        predictionConfidence: 'high',
        predictionSource: 'user_logged',
        averageCycleLength: cache?.averageCycleLength?.round(),
        averagePeriodLength: cache?.averagePeriodLength?.round(),
      );
    }

    final active = ongoing ?? observed.last;
    // Display-only date arithmetic: Day N from the locally stored start.
    // Never used for prediction, phase, confidence, or predicted dates.
    final cycleDay = isoDayDifference(active.periodStart, today) + 1;
    return CurrentCycleResponse(
      hasData: true,
      currentCycleDay: cycleDay,
      phase: cache?.phase ?? 'unknown',
      isBleeding: ongoing != null,
      isOngoing: ongoing != null,
      activeCycleId: ongoing?.serverId,
      latestPeriodStart: parseIsoDate(active.periodStart),
      latestPeriodEnd: active.periodEnd == null
          ? null
          : parseIsoDate(active.periodEnd!),
      predictedCycleLength: null,
      predictedNextPeriod: cache?.predictedNextPeriod == null
          ? null
          : parseIsoDate(cache!.predictedNextPeriod!),
      daysUntilNextPeriod: cache?.daysUntilNextPeriod,
      predictionStatus: cache?.predictionStatus,
      predictionConfidence: cache?.predictionConfidence ?? 'None',
      predictionSource: null,
      averageCycleLength: cache?.averageCycleLength?.round(),
      averagePeriodLength: cache?.averagePeriodLength?.round(),
    );
  }

  List<CycleResponse> _toCycleList(List<LocalCycle> rows) {
    final desc = rows.reversed.toList();
    return [
      for (final r in desc)
        CycleResponse(
          id: r.serverId ?? -r.id,
          userId: r.userId,
          periodStart: parseIsoDate(r.periodStart),
          periodEnd:
              r.periodEnd == null ? null : parseIsoDate(r.periodEnd!),
          // Observed bleeding duration from stored dates (display only).
          periodLengthDays: r.periodEnd == null
              ? null
              : isoDayDifference(r.periodStart, r.periodEnd!) + 1,
          createdAt: r.updatedAt,
          updatedAt: r.updatedAt,
        ),
    ];
  }

  HistorySummaryResponse _assembleHistory(
    List<LocalCycle> rows,
    PredictionCacheData? cache,
  ) {
    final asc = rows.toList();
    final entries = <HistoryPeriodEntry>[];
    for (var i = 0; i < asc.length; i++) {
      final r = asc[i];
      int? interval;
      if (i < asc.length - 1) {
        // Observed start-to-start interval between two logged periods,
        // shown as a history label only. Never used for prediction.
        interval =
            isoDayDifference(r.periodStart, asc[i + 1].periodStart);
      }
      entries.add(HistoryPeriodEntry(
        id: r.serverId ?? -r.id,
        periodStart: parseIsoDate(r.periodStart),
        periodEnd:
            r.periodEnd == null ? null : parseIsoDate(r.periodEnd!),
        periodLengthDays: r.periodEnd == null
            ? null
            : isoDayDifference(r.periodStart, r.periodEnd!) + 1,
        cycleLengthDays: interval,
      ));
    }
    return HistorySummaryResponse(
      totalPeriodsLogged: rows.length,
      averageCycleLength: cache?.averageCycleLength,
      averagePeriodLength: cache?.averagePeriodLength,
      cycleVariabilityStdDev: null,
      history: entries.reversed.toList(),
      symptomFrequencies: const {},
    );
  }

  /// Merges a server cycle list into local rows. Synced rows adopt server
  /// values; pending/conflict rows are left untouched so no local edit is
  /// silently discarded. New server rows are inserted as synced.
  Future<void> _mergeServerCycles(
    String userId,
    List<CycleResponse> server,
  ) async {
    final rows = await _localRows(userId);
    await db.transaction(() async {
      for (final s in server) {
        final sStart = toIsoDate(s.periodStart);
        final sEnd = s.periodEnd == null ? null : toIsoDate(s.periodEnd!);
        LocalCycle? match;
        for (final r in rows) {
          if (r.serverId == s.id) {
            match = r;
            break;
          }
        }
        match ??= _findByStart(rows, sStart);
        if (match == null) {
          await db.into(db.localCycles).insert(LocalCyclesCompanion.insert(
                localId: _newLocalId(),
                userId: userId,
                serverId: Value(s.id),
                periodStart: sStart,
                periodEnd: Value(sEnd),
                syncState: Value(SyncState.synced),
              ));
        } else if (match.syncState == SyncState.synced) {
          await (db.update(db.localCycles)
                ..where((t) => t.id.equals(match!.id)))
              .write(LocalCyclesCompanion(
            serverId: Value(s.id),
            periodStart: Value(sStart),
            periodEnd: Value(sEnd),
          ));
        } else if (match.serverId == null) {
          // Offline-created row now matches a server row by start date:
          // reconcile the identity but keep local values pending push.
          await (db.update(db.localCycles)
                ..where((t) => t.id.equals(match!.id)))
              .write(LocalCyclesCompanion(serverId: Value(s.id)));
        }
      }
    });
  }

  LocalCycle? _findByStart(List<LocalCycle> rows, String start) {
    for (final r in rows) {
      if (r.periodStart == start) return r;
    }
    return null;
  }

  /// Persists exactly the 7 approved server-computed prediction fields.
  Future<void> _storePredictionCache(
    String userId,
    CurrentCycleResponse current,
  ) async {
    await db.into(db.predictionCache).insertOnConflictUpdate(
          PredictionCacheCompanion.insert(
            userId: userId,
            phase: Value(current.phase),
            predictedNextPeriod: Value(current.predictedNextPeriod == null
                ? null
                : toIsoDate(current.predictedNextPeriod!)),
            daysUntilNextPeriod: Value(current.daysUntilNextPeriod),
            predictionStatus: Value(current.predictionStatus),
            predictionConfidence: Value(current.predictionConfidence),
            averageCycleLength: Value(
                current.averageCycleLength?.toDouble()),
            averagePeriodLength: Value(
                current.averagePeriodLength?.toDouble()),
            fetchedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Pulls server cycles + current prediction into local storage.
  /// Returns false when remote was unreachable (local data untouched).
  Future<bool> _refreshFromRemote(String userId) async {
    try {
      final results = await Future.wait([
        api.fetchCycles(),
        api.fetchCurrentCycle(),
      ]);
      final serverCycles = results[0] as List<CycleResponse>;
      final current = results[1] as CurrentCycleResponse;
      await _mergeServerCycles(userId, serverCycles);
      await _storePredictionCache(userId, current);
      return true;
    } on ApiError {
      return false;
    }
  }

  DataState<CurrentCycleResponse?> _stateFor(
    CurrentCycleResponse? view,
    List<LocalCycle> rows,
    PredictionCacheData? cache,
  ) {
    if (view == null) return const NoData();
    if (_hasConflict(rows)) {
      return ConflictState(view, 'One entry needs review.');
    }
    if (_hasPending(rows)) return PendingSync(view);
    return Fresh(view);
  }

  // -------------------------------------------------- public reads

  Future<DataState<CurrentCycleResponse?>> loadCurrent(String userId) async {
    final rows = await _localRows(userId);
    final cache = await _cache(userId);
    if (rows.isEmpty && cache == null) {
      try {
        final current = await api.fetchCurrentCycle();
        await _storePredictionCache(userId, current);
        final freshRows = await _localRows(userId);
        if (current.hasData && freshRows.isEmpty) {
          try {
            await _mergeServerCycles(userId, await api.fetchCycles());
          } on ApiError {
            // Prediction cached; cycle rows retry on next load.
          }
        }
        final view =
            _assembleCurrent(await _localRows(userId), await _cache(userId));
        if (view == null && !current.hasData) return const NoData();
        return Fresh(view ?? current);
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
    final ok = await _refreshFromRemote(userId);
    final view =
        _assembleCurrent(await _localRows(userId), await _cache(userId));
    if (!ok) {
      final r = await _localRows(userId);
      final c = await _cache(userId);
      final v = _assembleCurrent(r, c);
      if (v == null) return const NoData();
      if (_hasConflict(r)) return ConflictState(v, 'One entry needs review.');
      if (_hasPending(r)) return PendingSync(v);
      return Cached(v, _fetchedAt(c, r));
    }
    return _stateFor(view, await _localRows(userId), await _cache(userId));
  }

  Future<DataState<HistorySummaryResponse>> loadHistory(String userId) async {
    var rows = await _localRows(userId);
    var cache = await _cache(userId);
    if (rows.isEmpty && cache == null) {
      try {
        final serverCycles = await api.fetchCycles();
        await _mergeServerCycles(userId, serverCycles);
        final history = await api.fetchCycleHistory();
        rows = await _localRows(userId);
        final current = await api.fetchCurrentCycle();
        await _storePredictionCache(userId, current);
        cache = await _cache(userId);
        // History averages ride on the shared cache row.
        if (history.averageCycleLength != null ||
            history.averagePeriodLength != null) {
          await _storeHistoryAverages(userId, history);
          cache = await _cache(userId);
        }
        return Fresh(_assembleHistory(rows, cache));
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
    final ok = await _refreshFromRemote(userId);
    rows = await _localRows(userId);
    cache = await _cache(userId);
    final view = _assembleHistory(rows, cache);
    if (!ok) {
      if (_hasConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_hasPending(rows)) return PendingSync(view);
      return Cached(view, _fetchedAt(cache, rows));
    }
    if (_hasConflict(rows)) {
      return ConflictState(view, 'One entry needs review.');
    }
    if (_hasPending(rows)) return PendingSync(view);
    return Fresh(view);
  }

  Future<void> _storeHistoryAverages(
    String userId,
    HistorySummaryResponse history,
  ) async {
    final existing = await _cache(userId);
    await db.into(db.predictionCache).insertOnConflictUpdate(
          PredictionCacheCompanion.insert(
            userId: userId,
            phase: Value(existing?.phase),
            predictedNextPeriod: Value(existing?.predictedNextPeriod),
            daysUntilNextPeriod: Value(existing?.daysUntilNextPeriod),
            predictionStatus: Value(existing?.predictionStatus),
            predictionConfidence: Value(existing?.predictionConfidence),
            averageCycleLength: Value(history.averageCycleLength),
            averagePeriodLength: Value(history.averagePeriodLength),
            fetchedAt: Value(existing?.fetchedAt ?? DateTime.now()),
          ),
        );
  }

  Future<DataState<List<CycleResponse>>> loadCycles(String userId) async {
    var rows = await _localRows(userId);
    if (rows.isEmpty) {
      try {
        await _mergeServerCycles(userId, await api.fetchCycles());
        rows = await _localRows(userId);
        if (rows.isEmpty) return const NoData();
        return Fresh(_toCycleList(rows));
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
    var ok = true;
    try {
      await _mergeServerCycles(userId, await api.fetchCycles());
    } on ApiError {
      ok = false;
    }
    rows = await _localRows(userId);
    final view = _toCycleList(rows);
    if (!ok) {
      if (_hasConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_hasPending(rows)) return PendingSync(view);
      return Cached(view, _fetchedAt(await _cache(userId), rows));
    }
    if (_hasConflict(rows)) {
      return ConflictState(view, 'One entry needs review.');
    }
    if (_hasPending(rows)) return PendingSync(view);
    return Fresh(view);
  }

  // -------------------------------------------------- writes

  /// Local-first period start. Never duplicates: an existing local ongoing
  /// row is returned as-is; retry re-sends the same row.
  Future<DataState<CurrentCycleResponse?>> startPeriod(
    String userId,
    String isoDate,
  ) async {
    final rows = await _localRows(userId);
    final today = todayIso();
    final hasOngoing =
        rows.any((r) => r.periodEnd == null && r.periodStart.compareTo(today) <= 0);
    if (!hasOngoing) {
      await db.into(db.localCycles).insert(LocalCyclesCompanion.insert(
            localId: _newLocalId(),
            userId: userId,
            periodStart: isoDate,
            syncState: Value(SyncState.pending),
          ));
    }
    await syncPending(userId);
    final r = await _localRows(userId);
    final view = _assembleCurrent(r, await _cache(userId));
    if (_hasConflict(r)) return ConflictState(view, 'One entry needs review.');
    if (_hasPending(r)) return PendingSync(view);
    return Fresh(view);
  }

  /// Local-first period end on the same local row created offline.
  Future<DataState<CurrentCycleResponse?>> endOngoingPeriod(
    String userId,
    String isoDate,
  ) async {
    final rows = await _localRows(userId);
    final today = todayIso();
    LocalCycle? ongoing;
    for (final r in rows.reversed) {
      if (r.periodEnd == null && r.periodStart.compareTo(today) <= 0) {
        ongoing = r;
        break;
      }
    }
    if (ongoing == null) {
      // No local ongoing row: fall back to the server end endpoint once.
      try {
        final ended = await api.endOngoingCycle(isoDate);
        await _mergeServerCycles(userId, [ended]);
      } on ApiError catch (e) {
        if (e is NetworkUnavailable || e is ServerError) {
          final r = await _localRows(userId);
          final view = _assembleCurrent(r, await _cache(userId));
          if (view == null) return Unavailable(e.message);
          return Cached(view, _fetchedAt(await _cache(userId), r));
        }
        if (e is AuthFailure) rethrow;
        final r = await _localRows(userId);
        final view = _assembleCurrent(r, await _cache(userId));
        return ConflictState(view, e.message);
      }
    } else {
      await (db.update(db.localCycles)..where((t) => t.id.equals(ongoing!.id)))
          .write(LocalCyclesCompanion(
        periodEnd: Value(isoDate),
        syncState: const Value(SyncState.pending),
        updatedAt: Value(DateTime.now()),
      ));
    }
    await syncPending(userId);
    final r = await _localRows(userId);
    final view = _assembleCurrent(r, await _cache(userId));
    if (_hasConflict(r)) return ConflictState(view, 'One entry needs review.');
    if (_hasPending(r)) return PendingSync(view);
    return Fresh(view);
  }

  /// Pushes pending rows oldest-first. Continues past 400/409 conflicts;
  /// stops the pass on network/5xx/auth failures.
  Future<void> syncPending(String userId) async {
    final pending = await (db.select(db.localCycles)
          ..where((t) =>
              t.userId.equals(userId) &
              t.syncState.equals(SyncState.pending.index))
          ..orderBy([(t) => OrderingTerm.asc(t.periodStart)]))
        .get();
    for (final row in pending) {
      ApiError? failure;
      CycleResponse? created;
      try {
        if (row.serverId == null) {
          created = await api.createCycle(
            periodStart: row.periodStart,
            periodEnd: row.periodEnd,
          );
        } else {
          created = await api.patchCycle(
            row.serverId!,
            periodStart: row.periodStart,
            periodEnd: row.periodEnd,
          );
        }
      } on ApiError catch (e) {
        failure = e;
      }
      if (failure == null && created != null) {
        await (db.update(db.localCycles)..where((t) => t.id.equals(row.id)))
            .write(LocalCyclesCompanion(
          serverId: Value(created.id),
          periodStart: Value(toIsoDate(created.periodStart)),
          periodEnd: Value(created.periodEnd == null
              ? null
              : toIsoDate(created.periodEnd!)),
          syncState: const Value(SyncState.synced),
          updatedAt: Value(DateTime.now()),
        ));
        continue;
      }
      final outcome = classifySyncError(failure!);
      if (outcome == SyncOutcome.conflict) {
        await (db.update(db.localCycles)..where((t) => t.id.equals(row.id)))
            .write(const LocalCyclesCompanion(
                syncState: Value(SyncState.conflict)));
        // Obtain the authoritative server copy where possible while
        // keeping the local record and its conflict flag.
        await _adoptServerMatch(userId, row);
        continue;
      }
      // Network error, 5xx, or auth failure: stop this pass.
      return;
    }
  }

  Future<void> _adoptServerMatch(String userId, LocalCycle row) async {
    try {
      final server = await api.fetchCycles();
      for (final s in server) {
        if (toIsoDate(s.periodStart) == row.periodStart) {
          await (db.update(db.localCycles)..where((t) => t.id.equals(row.id)))
              .write(LocalCyclesCompanion(
            serverId: Value(s.id),
            periodEnd: Value(
                s.periodEnd == null ? null : toIsoDate(s.periodEnd!)),
          ));
          return;
        }
      }
    } on ApiError {
      // Server copy unavailable; local conflict row is retained safely.
    }
  }
}

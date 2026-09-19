import 'dart:math';

import 'package:drift/drift.dart';

import '../../models/reproductive.dart';
import '../../services/api_service.dart';
import '../app_database.dart';
import '../sync_policy.dart';

String _newLocalId() {
  final r = Random.secure();
  return 'local_${DateTime.now().microsecondsSinceEpoch}_${r.nextInt(1 << 32)}';
}

/// Sentinel distinguishing "field not included" from "explicit null (clear)"
/// in partial pregnancy updates (mirrors the backend PATCH contract).
const _unset = Object();

/// Offline-capable Phase 5 reproductive health: fertility observations,
/// server-computed fertility estimates (read-only), explicit pregnancy mode
/// + dating display, and user-declared reproductive-aging context.
///
/// Local-first like every other repository: reads serve local rows first
/// and refresh from remote when reachable; writes mutate locally (marked
/// pending) and push afterwards. Record-level `sync_state` is the only
/// queue — there is no separate outbox table.
///
/// Safety boundaries (mirroring the backend contracts):
/// - Observations store user-measured facts verbatim. Nothing here derives
///   ovulation, fertile windows, or any estimate from them.
/// - Estimates are computed server-side on read and consumed verbatim. This
///   repository performs no estimate math and caches no estimate: a stale
///   fertile window must never display as current, so offline estimate
///   reads are [Unavailable] (logged signs stay available offline).
/// - Pregnancy mode changes only through explicit user actions here. Late
///   periods, symptoms, estimates, and cycle history never flip it.
/// - Pregnancy dating values are rendered from server-provided fields only;
///   Flutter never calculates EDDs or gestational age.
/// - Aging context stores verbatim user notes; nothing classifies, stages,
///   or diagnoses, and it never alters predictions or estimates.
/// - This repository never calls prediction endpoints and never triggers
///   prediction refreshes. Cycle semantics are untouched.
class ReproductiveRepository {
  final AppDatabase db;
  final ApiService api;

  ReproductiveRepository(this.db, this.api);

  // ---------------------------------------------------------- observations

  Future<List<LocalFertilityObservation>> _observationRows(String userId) {
    return (db.select(db.localFertilityObservations)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.observationDate),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  List<FertilityObservation> _assembleObservations(
    List<LocalFertilityObservation> rows,
  ) {
    return [
      for (final r in rows.where((r) => !r.isDeleted))
        FertilityObservation(
          id: r.serverId,
          localId: r.localId,
          userId: r.userId,
          observationDate: r.observationDate,
          observationType: r.observationType,
          lhResult: r.lhResult,
          bbtCelsius: r.bbtCelsius,
          mucusCategory: r.mucusCategory,
          source: r.source,
          note: r.note,
        ),
    ];
  }

  LocalFertilityObservation? _liveByTriple(
    List<LocalFertilityObservation> rows,
    String date,
    String type,
  ) {
    for (final r in rows) {
      if (!r.isDeleted &&
          r.observationDate == date &&
          r.observationType == type) {
        return r;
      }
    }
    return null;
  }

  LocalFertilityObservation? _byLocalId(
    List<LocalFertilityObservation> rows,
    String localId,
  ) {
    for (final r in rows) {
      if (r.localId == localId) return r;
    }
    return null;
  }

  bool _obsConflict(List<LocalFertilityObservation> rows) =>
      rows.any((r) => r.syncState == SyncState.conflict);
  bool _obsPending(List<LocalFertilityObservation> rows) =>
      rows.any((r) => r.syncState == SyncState.pending);

  DataState<List<FertilityObservation>> _observationState(
    List<LocalFertilityObservation> rows,
  ) {
    final view = _assembleObservations(rows);
    if (view.isEmpty) {
      // Only tombstones (or nothing) stored: nothing to show, but pending
      // deletes are still real unsynced work.
      if (_obsConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_obsPending(rows)) return PendingSync(view);
      return const NoData();
    }
    if (_obsConflict(rows)) {
      return ConflictState(view, 'One entry needs review.');
    }
    if (_obsPending(rows)) return PendingSync(view);
    return Fresh(view);
  }

  /// Merges a full server observation list into local rows. Synced rows
  /// adopt server values; pending/conflict rows (including delete
  /// tombstones) are left untouched so no local edit is silently discarded.
  /// Server-side removals propagate by dropping local synced rows absent
  /// remotely. Always merges the FULL list (never a filtered subset) so
  /// the absent-remote drop stays correct.
  Future<void> _mergeServerObservations(
    String userId,
    List<FertilityObservation> server,
  ) async {
    final rows = await _observationRows(userId);
    final byServerId = <int, FertilityObservation>{};
    for (final s in server) {
      if (s.id != null) byServerId[s.id!] = s;
    }
    await db.transaction(() async {
      for (final s in server) {
        LocalFertilityObservation? match;
        for (final r in rows) {
          if (r.serverId != null && r.serverId == s.id) {
            match = r;
            break;
          }
        }
        if (match == null) {
          await db
              .into(db.localFertilityObservations)
              .insert(
                LocalFertilityObservationsCompanion.insert(
                  localId: _newLocalId(),
                  userId: userId,
                  serverId: Value(s.id),
                  observationDate: s.observationDate,
                  observationType: s.observationType,
                  lhResult: Value(s.lhResult),
                  bbtCelsius: Value(s.bbtCelsius),
                  mucusCategory: Value(s.mucusCategory),
                  source: Value(s.source),
                  note: Value(s.note),
                  syncState: const Value(SyncState.synced),
                ),
              );
        } else if (match.syncState == SyncState.synced) {
          await (db.update(
            db.localFertilityObservations,
          )..where((t) => t.id.equals(match!.id))).write(
            LocalFertilityObservationsCompanion(
              observationDate: Value(s.observationDate),
              observationType: Value(s.observationType),
              lhResult: Value(s.lhResult),
              bbtCelsius: Value(s.bbtCelsius),
              mucusCategory: Value(s.mucusCategory),
              source: Value(s.source),
              note: Value(s.note),
            ),
          );
        }
        // Pending/conflict rows keep local values for the sync push.
      }
      for (final r in rows) {
        if (r.syncState == SyncState.synced &&
            r.serverId != null &&
            !byServerId.containsKey(r.serverId)) {
          await (db.delete(
            db.localFertilityObservations,
          )..where((t) => t.id.equals(r.id))).go();
        }
      }
    });
  }

  Future<DataState<List<FertilityObservation>>> loadObservations(
    String userId,
  ) async {
    var rows = await _observationRows(userId);
    if (rows.where((r) => !r.isDeleted).isEmpty) {
      try {
        await _mergeServerObservations(userId, await api.listObservations());
        rows = await _observationRows(userId);
        if (rows.where((r) => !r.isDeleted).isEmpty) {
          // Pending tombstones with no visible rows are still work.
          if (_obsPending(rows) || _obsConflict(rows)) {
            return _observationState(rows);
          }
          return const NoData();
        }
        return _observationState(rows);
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
      await _mergeServerObservations(userId, await api.listObservations());
    } on ApiError {
      ok = false;
    }
    rows = await _observationRows(userId);
    final view = _assembleObservations(rows);
    if (!ok) {
      if (_obsConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_obsPending(rows)) return PendingSync(view);
      if (view.isEmpty) return const NoData();
      return Cached(view, _latestObsUpdate(rows));
    }
    return _observationState(rows);
  }

  /// Local-only read for offline tracking: no network attempt, empty is
  /// [NoData].
  Future<DataState<List<FertilityObservation>>> loadObservationsLocal(
    String userId,
  ) async {
    return _observationState(await _observationRows(userId));
  }

  DateTime _latestObsUpdate(List<LocalFertilityObservation> rows) {
    DateTime latest = rows.first.updatedAt;
    for (final r in rows.skip(1)) {
      if (r.updatedAt.isAfter(latest)) latest = r.updatedAt;
    }
    return latest;
  }

  Future<DataState<FertilityObservation>> _stateForObservation(
    String userId,
    String localId,
  ) async {
    final rows = await _observationRows(userId);
    final match = _byLocalId(rows, localId)!;
    final view = _assembleObservations([match]).single;
    if (match.syncState == SyncState.conflict) {
      return ConflictState(view, 'This entry needs review.');
    }
    if (match.syncState == SyncState.pending) return PendingSync(view);
    return Fresh(view);
  }

  /// Records one observation locally first (pending), then POSTs unless
  /// [localOnly]. Re-saving the same (date, type) overwrites the live local
  /// row in place — mirroring the backend deterministic upsert — so repeats
  /// converge instead of duplicating. Client-enforces the backend
  /// exactly-one-value contract so a 422 can never come from a malformed
  /// local write.
  Future<DataState<FertilityObservation>> saveObservation(
    String userId, {
    required String observationDate,
    required String observationType,
    String? lhResult,
    double? bbtCelsius,
    String? mucusCategory,
    String? note,
    bool localOnly = false,
  }) async {
    final error = validateObservationInput(
      observationType: observationType,
      lhResult: lhResult,
      bbtCelsius: bbtCelsius,
      mucusCategory: mucusCategory,
      note: note,
      observationDate: observationDate,
    );
    if (error != null) throw ValidationError(error);
    final cleanNote = note?.trim().isEmpty == true ? null : note?.trim();

    final rows = await _observationRows(userId);
    var match = _liveByTriple(rows, observationDate, observationType);
    final String localId;
    if (match == null || match.isDeleted) {
      localId = _newLocalId();
      await db
          .into(db.localFertilityObservations)
          .insert(
            LocalFertilityObservationsCompanion.insert(
              localId: localId,
              userId: userId,
              observationDate: observationDate,
              observationType: observationType,
              lhResult: Value(lhResult),
              bbtCelsius: Value(bbtCelsius),
              mucusCategory: Value(mucusCategory),
              note: Value(cleanNote),
              syncState: const Value(SyncState.pending),
            ),
          );
    } else {
      localId = match.localId;
      await (db.update(
        db.localFertilityObservations,
      )..where((t) => t.id.equals(match.id))).write(
        LocalFertilityObservationsCompanion(
          lhResult: Value(lhResult),
          bbtCelsius: Value(bbtCelsius),
          mucusCategory: Value(mucusCategory),
          note: Value(cleanNote),
          syncState: const Value(SyncState.pending),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    if (localOnly) {
      return PendingSync(
        FertilityObservation(
          localId: localId,
          userId: userId,
          observationDate: observationDate,
          observationType: observationType,
          lhResult: lhResult,
          bbtCelsius: bbtCelsius,
          mucusCategory: mucusCategory,
          note: cleanNote,
        ),
      );
    }
    await syncPendingObservations(userId);
    return _stateForObservation(userId, localId);
  }

  /// Corrects an observation locally first (pending). `observationType` is
  /// immutable: value fields not matching the row's own type are rejected
  /// locally (mirroring the backend 422) instead of surfacing a raw error.
  /// Moving the date onto another live row of the same type is rejected
  /// locally (mirroring the backend 409).
  Future<DataState<FertilityObservation>> updateObservation(
    String userId,
    String localId, {
    Object? observationDate = _unset,
    String? lhResult,
    double? bbtCelsius,
    String? mucusCategory,
    Object? source = _unset,
    Object? note = _unset,
    bool clearNote = false,
    bool localOnly = false,
  }) async {
    final rows = await _observationRows(userId);
    final match = _byLocalId(rows, localId);
    if (match == null || match.isDeleted) {
      throw const Conflict('This entry no longer exists.');
    }
    final kind = match.observationType;
    // Type-immutability guard: only the row's own value column may be set.
    if (kind == ObservationTypes.lhTest &&
        (bbtCelsius != null || mucusCategory != null)) {
      throw const ValidationError('That value does not match this entry type.');
    }
    if (kind == ObservationTypes.bbt &&
        (lhResult != null || mucusCategory != null)) {
      throw const ValidationError('That value does not match this entry type.');
    }
    if (kind == ObservationTypes.cervicalMucus &&
        (lhResult != null || bbtCelsius != null)) {
      throw const ValidationError('That value does not match this entry type.');
    }
    final newDate = observationDate is String
        ? observationDate
        : match.observationDate;
    if (newDate != match.observationDate) {
      if (!_isValidLocalDate(newDate)) {
        throw const ValidationError(
          'Observation dates can\u2019t be in the future.',
        );
      }
      final clash = _liveByTriple(rows, newDate, kind);
      if (clash != null && clash.localId != localId) {
        throw const Conflict(
          'An observation of this type already exists on that date.',
        );
      }
    }
    final newNote = clearNote
        ? null
        : note is String
        ? (note.trim().isEmpty ? null : note.trim())
        : match.note;
    if (newNote != null && newNote.length > kObservationNoteMaxLength) {
      throw const ValidationError('Please keep notes under 1000 characters.');
    }
    await (db.update(
      db.localFertilityObservations,
    )..where((t) => t.id.equals(match.id))).write(
      LocalFertilityObservationsCompanion(
        observationDate: Value(newDate),
        lhResult: kind == ObservationTypes.lhTest && lhResult != null
            ? Value(lhResult)
            : const Value.absent(),
        bbtCelsius: kind == ObservationTypes.bbt && bbtCelsius != null
            ? Value(bbtCelsius)
            : const Value.absent(),
        mucusCategory:
            kind == ObservationTypes.cervicalMucus && mucusCategory != null
            ? Value(mucusCategory)
            : const Value.absent(),
        source: source is String ? Value(source) : const Value.absent(),
        note: clearNote || note is String
            ? Value(newNote)
            : const Value.absent(),
        syncState: const Value(SyncState.pending),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (!localOnly) await syncPendingObservations(userId);
    return _stateForObservation(userId, localId);
  }

  /// Retracts an observation: rows that never reached the server disappear
  /// immediately; synced rows become delete tombstones flushed as DELETE
  /// on the next push, so offline deletes never resurrect on refetch.
  Future<void> deleteObservation(
    String userId,
    String localId, {
    bool localOnly = false,
  }) async {
    final rows = await _observationRows(userId);
    final match = _byLocalId(rows, localId);
    if (match == null) return;
    if (match.serverId == null) {
      await (db.delete(
        db.localFertilityObservations,
      )..where((t) => t.id.equals(match.id))).go();
      return;
    }
    await (db.update(
      db.localFertilityObservations,
    )..where((t) => t.id.equals(match.id))).write(
      const LocalFertilityObservationsCompanion(
        isDeleted: Value(true),
        syncState: Value(SyncState.pending),
      ),
    );
    if (!localOnly) {
      try {
        await syncPendingObservations(userId);
      } on AuthFailure {
        rethrow;
      } on ApiError {
        // Row stays a pending tombstone; the pass retries later.
      }
    }
  }

  /// Pushes pending observation rows oldest-first: tombstones DELETE (a 404
  /// means already gone — desired end state), new/edited rows POST (the
  /// backend upsert converges by date+type), synced-but-edited rows PATCH
  /// with full current values. Continues past conflicts; stops the pass on
  /// network/5xx/auth failures.
  Future<void> syncPendingObservations(String userId) async {
    final pending =
        await (db.select(db.localFertilityObservations)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.syncState.equals(SyncState.pending.index),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.observationDate),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    for (final row in pending) {
      ApiError? failure;
      FertilityObservation? remote;
      try {
        if (row.isDeleted && row.serverId != null) {
          await api.deleteObservation(row.serverId!);
        } else if (row.isDeleted) {
          // Never reached the server: dropping the local row is the sync.
        } else if (row.serverId == null) {
          remote = await api.createObservation({
            'observation_date': row.observationDate,
            'observation_type': row.observationType,
            if (row.lhResult != null) 'lh_result': row.lhResult,
            if (row.bbtCelsius != null) 'bbt_celsius': row.bbtCelsius,
            if (row.mucusCategory != null) 'mucus_category': row.mucusCategory,
            'source': row.source,
            if (row.note != null) 'note': row.note,
          });
        } else {
          remote = await api.patchObservation(row.serverId!, {
            'observation_date': row.observationDate,
            if (row.observationType == ObservationTypes.lhTest)
              'lh_result': row.lhResult,
            if (row.observationType == ObservationTypes.bbt)
              'bbt_celsius': row.bbtCelsius,
            if (row.observationType == ObservationTypes.cervicalMucus)
              'mucus_category': row.mucusCategory,
            'source': row.source,
            'note': row.note,
          });
        }
      } on ApiError catch (e) {
        failure = e;
      }
      if (failure == null) {
        if (row.isDeleted || remote == null) {
          await (db.delete(
            db.localFertilityObservations,
          )..where((t) => t.id.equals(row.id))).go();
        } else {
          await (db.update(
            db.localFertilityObservations,
          )..where((t) => t.id.equals(row.id))).write(
            LocalFertilityObservationsCompanion(
              serverId: Value(remote.id),
              observationDate: Value(remote.observationDate),
              observationType: Value(remote.observationType),
              lhResult: Value(remote.lhResult),
              bbtCelsius: Value(remote.bbtCelsius),
              mucusCategory: Value(remote.mucusCategory),
              source: Value(remote.source),
              note: Value(remote.note),
              syncState: const Value(SyncState.synced),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
        continue;
      }
      final outcome = classifySyncError(failure);
      if (outcome == SyncOutcome.conflict) {
        await (db.update(
          db.localFertilityObservations,
        )..where((t) => t.id.equals(row.id))).write(
          const LocalFertilityObservationsCompanion(
            syncState: Value(SyncState.conflict),
          ),
        );
        continue;
      }
      // Network error, 5xx, or auth failure: stop this pass.
      return;
    }
  }

  bool _isValidLocalDate(String iso) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso)) return false;
    try {
      final parsed = DateTime.parse(iso);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final check = DateTime(parsed.year, parsed.month, parsed.day);
      return !check.isAfter(today);
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------- estimate
  //
  // Server-computed on read, consumed verbatim, never cached. Caching a
  // fertile window locally risks displaying a stale window as current, so
  // offline estimate reads are [Unavailable] with guidance. Logged signs
  // themselves remain available offline through the observation store.

  /// Local-only read for offline tracking: estimates need a connection, so
  /// this is always [Unavailable] with guidance (never an error, never
  /// stale data presented as current).
  Future<DataState<FertilityEstimate?>> loadEstimateLocal() async {
    return const Unavailable(
      'Fertility estimates need a connection. Your logged signs stay on this device.',
    );
  }

  Future<DataState<FertilityEstimate?>> loadEstimate() async {
    try {
      return Fresh<FertilityEstimate?>(await api.fetchFertilityEstimate());
    } on NetworkUnavailable catch (e) {
      return Unavailable(e.message);
    } on ServerError catch (e) {
      return Unavailable(e.message);
    } on AuthFailure {
      rethrow;
    } on ApiError {
      return const Unavailable('Server rejected the request.');
    }
  }

  // ---------------------------------------------------------- pregnancy

  Future<LocalPregnancyContextData?> _pregnancyRow(String userId) {
    return (db.select(
      db.localPregnancyContext,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  PregnancyContext _assemblePregnancy(LocalPregnancyContextData row) {
    return PregnancyContext(
      userId: row.userId,
      isActive: row.isActive,
      datingSource: row.datingSource,
      estimatedDueDate: row.estimatedDueDate,
      lmpDate: row.lmpDate,
      confirmationDate: row.confirmationDate,
      datingNote: row.datingNote,
      eddStatus: row.eddStatus ?? 'unavailable',
      eddLabel: row.eddLabel,
      datingConfidence: row.datingConfidence,
      gestationalAgeTotalDays: row.gestationalAgeTotalDays,
      gestationalAgeWeeks: row.gestationalAgeWeeks,
      gestationalAgeDays: row.gestationalAgeDays,
      daysUntilDue: row.daysUntilDue,
      asOfDate: row.asOfDate,
      timezoneName: row.timezoneName,
    );
  }

  /// Stores pregnancy state under the local tracking id [userId].
  /// The key always comes from the caller — never from a server echo, which
  /// carries the backend's user identity, not the local row key.
  Future<void> _storePregnancy(
    String userId,
    PregnancyContext value,
    SyncState state,
  ) {
    return db
        .into(db.localPregnancyContext)
        .insertOnConflictUpdate(
          LocalPregnancyContextCompanion.insert(
            userId: userId,
            isActive: Value(value.isActive),
            datingSource: Value(value.datingSource),
            estimatedDueDate: Value(value.estimatedDueDate),
            lmpDate: Value(value.lmpDate),
            confirmationDate: Value(value.confirmationDate),
            datingNote: Value(value.datingNote),
            eddStatus: Value(value.eddStatus),
            eddLabel: Value(value.eddLabel),
            datingConfidence: Value(value.datingConfidence),
            gestationalAgeTotalDays: Value(value.gestationalAgeTotalDays),
            gestationalAgeWeeks: Value(value.gestationalAgeWeeks),
            gestationalAgeDays: Value(value.gestationalAgeDays),
            daysUntilDue: Value(value.daysUntilDue),
            asOfDate: Value(value.asOfDate),
            timezoneName: Value(value.timezoneName),
            syncState: Value(state),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<DataState<PregnancyContext?>> loadPregnancy(String userId) async {
    final local = await _pregnancyRow(userId);
    if (local == null) {
      try {
        final remote = await api.fetchPregnancy(userId);
        await _storePregnancy(userId, remote, SyncState.synced);
        return Fresh<PregnancyContext?>(remote);
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
    final view = _assemblePregnancy(local);
    try {
      final remote = await api.fetchPregnancy(userId);
      await _storePregnancy(userId, remote, SyncState.synced);
      return Fresh<PregnancyContext?>(remote);
    } on ApiError {
      if (local.syncState == SyncState.conflict) {
        return ConflictState<PregnancyContext?>(
          view,
          'Pregnancy details need review.',
        );
      }
      if (local.syncState == SyncState.pending) {
        return PendingSync<PregnancyContext?>(view);
      }
      return Cached<PregnancyContext?>(view, local.updatedAt);
    }
  }

  /// Local-only read for offline tracking: serves the local singleton
  /// without any network attempt. No row is [NoData], never an error.
  Future<DataState<PregnancyContext?>> loadPregnancyLocal(String userId) async {
    final local = await _pregnancyRow(userId);
    if (local == null) return const NoData();
    final view = _assemblePregnancy(local);
    if (local.syncState == SyncState.conflict) {
      return ConflictState<PregnancyContext?>(
        view,
        'Pregnancy details need review.',
      );
    }
    if (local.syncState == SyncState.pending) {
      return PendingSync<PregnancyContext?>(view);
    }
    return Fresh<PregnancyContext?>(view);
  }

  /// Activates or replaces pregnancy mode (PUT full replacement). Explicit
  /// user action only — nothing else in this repository activates it.
  /// Pending rows clear the server-derived display until the push succeeds,
  /// so a new due date is never shown with a stale gestational age.
  Future<DataState<PregnancyContext>> savePregnancyPut(
    String userId,
    PregnancyContext value, {
    bool localOnly = false,
  }) async {
    final error = validatePregnancyInput(
      datingSource: value.datingSource,
      estimatedDueDate: value.estimatedDueDate,
      lmpDate: value.lmpDate,
      confirmationDate: value.confirmationDate,
      datingNote: value.datingNote,
    );
    if (error != null) throw ValidationError(error);
    final pending = PregnancyContext(
      userId: userId,
      isActive: value.isActive,
      datingSource: value.datingSource,
      estimatedDueDate: value.estimatedDueDate,
      lmpDate: value.lmpDate,
      confirmationDate: value.confirmationDate,
      datingNote: value.datingNote,
    );
    await _storePregnancy(userId, pending, SyncState.pending);
    if (localOnly) return PendingSync(pending);
    try {
      final remote = await api.putPregnancy(userId, value.toPutJson());
      await _storePregnancy(userId, remote, SyncState.synced);
      return Fresh(remote);
    } on ApiError catch (e) {
      if (e is AuthFailure) rethrow;
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storePregnancy(userId, pending, SyncState.conflict);
        return ConflictState(pending, e.message);
      }
      return PendingSync(pending);
    }
  }

  /// Partially updates pregnancy mode (PATCH). Only explicitly included
  /// fields change; explicit null clears. Deactivation is explicit via
  /// `isActive: false` (history retained) — never automatic.
  Future<DataState<PregnancyContext>> patchPregnancy(
    String userId, {
    bool? isActive,
    Object? datingSource = _unset,
    Object? estimatedDueDate = _unset,
    Object? lmpDate = _unset,
    Object? confirmationDate = _unset,
    Object? datingNote = _unset,
    bool localOnly = false,
  }) async {
    final local = await _pregnancyRow(userId);
    final current = local == null
        ? PregnancyContext(userId: userId, isActive: true)
        : _assemblePregnancy(local);
    final candidate = PregnancyContext(
      userId: userId,
      isActive: isActive ?? current.isActive,
      datingSource: datingSource is String?
          ? datingSource
          : current.datingSource,
      estimatedDueDate: estimatedDueDate is String?
          ? estimatedDueDate
          : current.estimatedDueDate,
      lmpDate: lmpDate is String? ? lmpDate : current.lmpDate,
      confirmationDate: confirmationDate is String?
          ? confirmationDate
          : current.confirmationDate,
      datingNote: datingNote is String? ? datingNote : current.datingNote,
    );
    final error = validatePregnancyInput(
      datingSource: candidate.datingSource,
      estimatedDueDate: candidate.estimatedDueDate,
      lmpDate: candidate.lmpDate,
      confirmationDate: candidate.confirmationDate,
      datingNote: candidate.datingNote,
    );
    if (error != null) throw ValidationError(error);
    // PATCH payload: only explicitly included fields travel; explicit null
    // clears server-side. Built imperatively to match house style.
    final patch = <String, dynamic>{};
    if (isActive != null) patch['is_active'] = isActive;
    if (!identical(datingSource, _unset)) patch['dating_source'] = datingSource;
    if (!identical(estimatedDueDate, _unset)) {
      patch['estimated_due_date'] = estimatedDueDate;
    }
    if (!identical(lmpDate, _unset)) patch['lmp_date'] = lmpDate;
    if (!identical(confirmationDate, _unset)) {
      patch['confirmation_date'] = confirmationDate;
    }
    if (!identical(datingNote, _unset)) patch['dating_note'] = datingNote;
    await _storePregnancy(userId, candidate, SyncState.pending);
    if (localOnly) return PendingSync(candidate);
    try {
      final remote = await api.patchPregnancy(userId, patch);
      await _storePregnancy(userId, remote, SyncState.synced);
      return Fresh(remote);
    } on ApiError catch (e) {
      if (e is AuthFailure) rethrow;
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storePregnancy(userId, candidate, SyncState.conflict);
        return ConflictState(candidate, e.message);
      }
      return PendingSync(candidate);
    }
  }

  /// Explicit deactivation (pause with history retained). Offline-capable:
  /// stored pending and pushed on the next pass.
  Future<DataState<PregnancyContext>> deactivatePregnancy(
    String userId, {
    bool localOnly = false,
  }) {
    return patchPregnancy(userId, isActive: false, localOnly: localOnly);
  }

  /// Erases the singleton row (explicit exit with erasure). Unlike every
  /// other write here this is online-first by design: erasure either fully
  /// happens (local + server agree it is gone) or clearly fails with the
  /// local row untouched for retry. Offline erasure is not silently queued
  /// because a queued erasure cannot be distinguished from "never entered"
  /// on the next sync pass.
  Future<void> deletePregnancy(String userId) async {
    await api.deletePregnancy();
    await (db.delete(
      db.localPregnancyContext,
    )..where((t) => t.userId.equals(userId))).go();
  }

  /// Pushes the pending singleton row, if any. PUT carries the full current
  /// basis, so a retry can never partially apply — including a pending
  /// deactivation, which rides the same full-replacement push.
  Future<void> syncPendingPregnancy(String userId) async {
    final local = await _pregnancyRow(userId);
    if (local == null || local.syncState != SyncState.pending) return;
    final view = _assemblePregnancy(local);
    try {
      final remote = await api.putPregnancy(
        userId,
        view.toPutJson(isActive: view.isActive),
      );
      await _storePregnancy(userId, remote, SyncState.synced);
    } on ApiError catch (e) {
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storePregnancy(userId, view, SyncState.conflict);
      }
      // retryLater/authError: row stays pending; pass ends here.
    }
  }

  // ---------------------------------------------------------- aging context

  Future<LocalAgingContextData?> _agingRow(String userId) {
    return (db.select(
      db.localAgingContext,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  AgingContext _assembleAging(LocalAgingContextData row) {
    return AgingContext(
      userId: row.userId,
      hasContext: row.notes != null,
      notes: row.notes,
    );
  }

  Future<void> _storeAging(String userId, AgingContext value, SyncState state) {
    return db
        .into(db.localAgingContext)
        .insertOnConflictUpdate(
          LocalAgingContextCompanion.insert(
            userId: userId,
            notes: Value(value.notes),
            syncState: Value(state),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<DataState<AgingContext?>> loadAging(String userId) async {
    final local = await _agingRow(userId);
    if (local == null) {
      try {
        final remote = await api.fetchAgingContext(userId);
        await _storeAging(userId, remote, SyncState.synced);
        return Fresh<AgingContext?>(remote);
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
    final view = _assembleAging(local);
    try {
      final remote = await api.fetchAgingContext(userId);
      await _storeAging(userId, remote, SyncState.synced);
      return Fresh<AgingContext?>(remote);
    } on ApiError {
      if (local.syncState == SyncState.conflict) {
        return ConflictState<AgingContext?>(view, 'This context needs review.');
      }
      if (local.syncState == SyncState.pending) {
        return PendingSync<AgingContext?>(view);
      }
      return Cached<AgingContext?>(view, local.updatedAt);
    }
  }

  /// Local-only read for offline tracking: serves the local singleton
  /// without any network attempt. No row is [NoData], never an error.
  Future<DataState<AgingContext?>> loadAgingLocal(String userId) async {
    final local = await _agingRow(userId);
    if (local == null) return const NoData();
    final view = _assembleAging(local);
    if (local.syncState == SyncState.conflict) {
      return ConflictState<AgingContext?>(view, 'This context needs review.');
    }
    if (local.syncState == SyncState.pending) {
      return PendingSync<AgingContext?>(view);
    }
    return Fresh<AgingContext?>(view);
  }

  /// Records or replaces aging context (PUT full replacement). Null notes
  /// clear the recorded context (the deactivation path).
  Future<DataState<AgingContext>> saveAging(
    String userId,
    String? notes, {
    bool localOnly = false,
  }) async {
    final clean = notes?.trim().isEmpty == true ? null : notes?.trim();
    final error = validateAgingNotes(clean);
    if (error != null) throw ValidationError(error);
    final value = AgingContext(
      userId: userId,
      hasContext: clean != null,
      notes: clean,
    );
    await _storeAging(userId, value, SyncState.pending);
    if (localOnly) return PendingSync(value);
    try {
      final remote = await api.putAgingContext(userId, value.toPutJson());
      await _storeAging(userId, remote, SyncState.synced);
      return Fresh(remote);
    } on ApiError catch (e) {
      if (e is AuthFailure) rethrow;
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storeAging(userId, value, SyncState.conflict);
        return ConflictState(value, e.message);
      }
      return PendingSync(value);
    }
  }

  /// Pushes the pending singleton row, if any. PUT carries the full current
  /// notes, so a retry can never partially apply.
  Future<void> syncPendingAging(String userId) async {
    final local = await _agingRow(userId);
    if (local == null || local.syncState != SyncState.pending) return;
    final view = _assembleAging(local);
    try {
      final remote = await api.putAgingContext(userId, view.toPutJson());
      await _storeAging(userId, remote, SyncState.synced);
    } on ApiError catch (e) {
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storeAging(userId, view, SyncState.conflict);
      }
      // retryLater/authError: row stays pending; pass ends here.
    }
  }

  // ---------------------------------------------------------- combined sync

  /// One sync pass over observations plus both singletons, oldest-first
  /// within observations. Continues past per-row conflicts; stops a kind's
  /// pass on network/5xx/auth failures. Never touches predictions.
  Future<void> syncPending(String userId) async {
    await syncPendingObservations(userId);
    await syncPendingPregnancy(userId);
    await syncPendingAging(userId);
  }
}

/// Client-side view filter for observation lists. Pure display filtering;
/// the repository always merges the full server list so sync stays correct.
List<FertilityObservation> filterObservations(
  List<FertilityObservation> all, {
  String? startDate,
  String? endDate,
  String? observationType,
  String? observationDate,
}) {
  return [
    for (final o in all)
      if ((observationDate == null || o.observationDate == observationDate) &&
          (startDate == null || o.observationDate.compareTo(startDate) >= 0) &&
          (endDate == null || o.observationDate.compareTo(endDate) <= 0) &&
          (observationType == null || o.observationType == observationType))
        o,
  ];
}

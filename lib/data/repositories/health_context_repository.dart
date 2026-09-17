import 'dart:math';

import 'package:drift/drift.dart';

import '../../models/health_context.dart';
import '../../services/api_service.dart';
import '../app_database.dart';
import '../sync_policy.dart';

LocalCondition? _conditionByLocalId(List<LocalCondition> rows, String localId) {
  for (final r in rows) {
    if (r.localId == localId) return r;
  }
  return null;
}

LocalMedication? _medicationByLocalId(
  List<LocalMedication> rows,
  String localId,
) {
  for (final r in rows) {
    if (r.localId == localId) return r;
  }
  return null;
}

String _newLocalId() {
  final r = Random.secure();
  return 'local_${DateTime.now().microsecondsSinceEpoch}_${r.nextInt(1 << 32)}';
}

/// Offline-capable V1 Health Context: singleton selections/notes plus
/// user-reported condition and medication rows.
///
/// Local-first like every other repository: reads serve local rows first
/// and refresh from remote when reachable; writes mutate locally (marked
/// pending) and push afterwards. Record-level `sync_state` is the only
/// queue — there is no separate outbox table.
///
/// Safety boundaries (mirroring the backend contract):
/// - Values are stored and returned verbatim. Nothing here diagnoses,
///   infers conditions (from symptoms or medications), or touches
///   prediction inputs. In particular this repository never calls
///   prediction endpoints and never triggers prediction refreshes.
/// - Deletes apply locally immediately and are pushed as DELETE via an
///   `isDeleted` tombstone, so offline deletes survive and never resurrect
///   on the next list fetch. DELETE is idempotent: a 404 means the row is
///   already gone, which is the desired end state.
class HealthContextRepository {
  final AppDatabase db;
  final ApiService api;

  HealthContextRepository(this.db, this.api);

  // ---------------------------------------------------------- singleton

  Future<LocalHealthContextData?> _contextRow(String userId) {
    return (db.select(
      db.localHealthContext,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  HealthContext _assembleContext(LocalHealthContextData row) {
    return HealthContext(
      userId: row.userId,
      contraceptionMethod: row.contraceptionMethod,
      contraceptionNote: row.contraceptionNote,
      pregnancyContext: row.pregnancyContext,
      healthNotes: row.healthNotes,
    );
  }

  /// Stores health context values under the local tracking id [userId].
  /// The key always comes from the caller — never from a server echo, which
  /// carries the backend's user identity, not the local row key.
  Future<void> _storeContext(
    String userId,
    HealthContext context,
    SyncState state,
  ) {
    return db
        .into(db.localHealthContext)
        .insertOnConflictUpdate(
          LocalHealthContextCompanion.insert(
            userId: userId,
            contraceptionMethod: Value(context.contraceptionMethod),
            contraceptionNote: Value(context.contraceptionNote),
            pregnancyContext: Value(context.pregnancyContext),
            healthNotes: Value(context.healthNotes),
            syncState: Value(state),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<DataState<HealthContext?>> loadHealthContext(String userId) async {
    final local = await _contextRow(userId);
    if (local == null) {
      try {
        final remote = await api.fetchHealthContext(userId);
        await _storeContext(userId, remote, SyncState.synced);
        return Fresh<HealthContext?>(remote);
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
    final view = _assembleContext(local);
    try {
      final remote = await api.fetchHealthContext(userId);
      await _storeContext(userId, remote, SyncState.synced);
      return Fresh<HealthContext?>(remote);
    } on ApiError {
      if (local.syncState == SyncState.conflict) {
        return ConflictState<HealthContext?>(
          view,
          'Health details need review.',
        );
      }
      if (local.syncState == SyncState.pending) {
        return PendingSync<HealthContext?>(view);
      }
      return Cached<HealthContext?>(view, local.updatedAt);
    }
  }

  /// Local-only read for offline tracking: serves the local singleton
  /// without any network attempt. No row is [NoData], never an error.
  Future<DataState<HealthContext?>> loadHealthContextLocal(
    String userId,
  ) async {
    final local = await _contextRow(userId);
    if (local == null) return const NoData();
    final view = _assembleContext(local);
    if (local.syncState == SyncState.conflict) {
      return ConflictState<HealthContext?>(view, 'Health details need review.');
    }
    if (local.syncState == SyncState.pending) {
      return PendingSync<HealthContext?>(view);
    }
    return Fresh<HealthContext?>(view);
  }

  /// Stores the complete form object locally (pending), then PUTs it.
  /// Callers always assemble the full object from form state — including
  /// explicit nulls for cleared fields — because PUT is full-replacement
  /// server-side. Pushing the exact stored row keeps both sides identical
  /// without ever guessing at partial semantics.
  Future<DataState<HealthContext>> saveHealthContext(
    String userId,
    HealthContext value, {
    bool localOnly = false,
  }) async {
    final merged = HealthContext(
      userId: userId,
      contraceptionMethod: value.contraceptionMethod,
      contraceptionNote: value.contraceptionNote,
      pregnancyContext: value.pregnancyContext,
      healthNotes: value.healthNotes,
    );
    await _storeContext(userId, merged, SyncState.pending);
    if (localOnly) return PendingSync(merged);
    try {
      final remote = await api.putHealthContext(userId, merged.toJson());
      await _storeContext(userId, remote, SyncState.synced);
      return Fresh(remote);
    } on ApiError catch (e) {
      if (e is AuthFailure) rethrow;
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storeContext(userId, merged, SyncState.conflict);
        return ConflictState(merged, e.message);
      }
      return PendingSync(merged);
    }
  }

  /// Pushes the pending singleton row, if any. PUT carries the full merged
  /// object, so a retry can never partially apply.
  Future<void> syncPendingContext(String userId) async {
    final local = await _contextRow(userId);
    if (local == null || local.syncState != SyncState.pending) return;
    final view = _assembleContext(local);
    try {
      final remote = await api.putHealthContext(userId, view.toJson());
      await _storeContext(userId, remote, SyncState.synced);
    } on ApiError catch (e) {
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _storeContext(userId, view, SyncState.conflict);
      }
      // retryLater/authError: row stays pending; pass ends here.
    }
  }

  // ---------------------------------------------------------- conditions

  Future<List<LocalCondition>> _conditionRows(String userId) {
    return (db.select(db.localConditions)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  List<HealthCondition> _assembleConditions(List<LocalCondition> rows) {
    return [
      for (final r in rows.where((r) => !r.isDeleted))
        HealthCondition(
          id: r.serverId,
          localId: r.localId,
          userId: r.userId,
          code: r.code,
          customLabel: r.customLabel,
          note: r.note,
          isActive: r.isActive,
        ),
    ];
  }

  bool _rowsConflict(List<LocalCondition> rows) =>
      rows.any((r) => r.syncState == SyncState.conflict);
  bool _rowsPending(List<LocalCondition> rows) =>
      rows.any((r) => r.syncState == SyncState.pending);

  DataState<List<HealthCondition>> _conditionState(List<LocalCondition> rows) {
    final view = _assembleConditions(rows);
    if (view.isEmpty && rows.where((r) => !r.isDeleted).isEmpty) {
      // Only tombstones (or nothing) stored: nothing to show, but pending
      // deletes are still real unsynced work.
      if (_rowsConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_rowsPending(rows)) return PendingSync(view);
      return const NoData();
    }
    if (_rowsConflict(rows)) {
      return ConflictState(view, 'One entry needs review.');
    }
    if (_rowsPending(rows)) return PendingSync(view);
    return Fresh(view);
  }

  /// Merges a server condition list into local rows. Synced rows adopt
  /// server values; pending/conflict rows (including delete tombstones)
  /// are left untouched so no local edit is silently discarded. Server-side
  /// removals propagate by dropping local synced rows absent remotely.
  Future<void> _mergeServerConditions(
    String userId,
    List<HealthCondition> server,
  ) async {
    final rows = await _conditionRows(userId);
    final byServerId = <int, HealthCondition>{};
    for (final s in server) {
      if (s.id != null) byServerId[s.id!] = s;
    }
    await db.transaction(() async {
      for (final s in server) {
        LocalCondition? match;
        for (final r in rows) {
          if (r.serverId != null && r.serverId == s.id) {
            match = r;
            break;
          }
        }
        if (match == null) {
          await db
              .into(db.localConditions)
              .insert(
                LocalConditionsCompanion.insert(
                  localId: _newLocalId(),
                  userId: userId,
                  serverId: Value(s.id),
                  code: s.code,
                  customLabel: Value(s.customLabel),
                  note: Value(s.note),
                  isActive: Value(s.isActive),
                  syncState: const Value(SyncState.synced),
                ),
              );
        } else if (match.syncState == SyncState.synced) {
          await (db.update(
            db.localConditions,
          )..where((t) => t.id.equals(match!.id))).write(
            LocalConditionsCompanion(
              code: Value(s.code),
              customLabel: Value(s.customLabel),
              note: Value(s.note),
              isActive: Value(s.isActive),
            ),
          );
        }
        // Pending/conflict rows keep local values for the sync push.
      }
      // Drop local synced rows the server no longer lists (deleted on
      // another device). Pending/conflict/tombstone rows always survive.
      for (final r in rows) {
        if (r.syncState == SyncState.synced &&
            r.serverId != null &&
            !byServerId.containsKey(r.serverId)) {
          await (db.delete(
            db.localConditions,
          )..where((t) => t.id.equals(r.id))).go();
        }
      }
    });
  }

  Future<DataState<List<HealthCondition>>> loadConditions(String userId) async {
    var rows = await _conditionRows(userId);
    final visible = rows.where((r) => !r.isDeleted).toList();
    if (visible.isEmpty) {
      try {
        await _mergeServerConditions(userId, await api.fetchConditions());
        rows = await _conditionRows(userId);
        if (rows.where((r) => !r.isDeleted).isEmpty) {
          return const NoData();
        }
        return _conditionState(rows);
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
      await _mergeServerConditions(userId, await api.fetchConditions());
    } on ApiError {
      ok = false;
    }
    rows = await _conditionRows(userId);
    final view = _assembleConditions(rows);
    if (!ok) {
      if (_rowsConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_rowsPending(rows)) return PendingSync(view);
      if (view.isEmpty) return const NoData();
      return Cached(view, _latestUpdate(rows));
    }
    return _conditionState(rows);
  }

  /// Local-only read for offline tracking: no network attempt, empty is
  /// [NoData].
  Future<DataState<List<HealthCondition>>> loadConditionsLocal(
    String userId,
  ) async {
    return _conditionState(await _conditionRows(userId));
  }

  DateTime _latestUpdate(List<LocalCondition> rows) {
    DateTime latest = rows.first.updatedAt;
    for (final r in rows.skip(1)) {
      if (r.updatedAt.isAfter(latest)) latest = r.updatedAt;
    }
    return latest;
  }

  /// Records a user-reported condition locally first (pending), then POSTs
  /// unless [localOnly]. Client-enforces the backend other-label contract
  /// so a 422 can never come from a malformed local write.
  Future<DataState<HealthCondition>> addCondition(
    String userId, {
    required String code,
    String? customLabel,
    String? note,
    bool localOnly = false,
  }) async {
    final error = validateConditionInput(code, customLabel);
    if (error != null) throw ValidationError(error);
    final label = code == HealthConditionCodes.other
        ? customLabel!.trim()
        : null;
    final localId = _newLocalId();
    await db
        .into(db.localConditions)
        .insert(
          LocalConditionsCompanion.insert(
            localId: localId,
            userId: userId,
            code: code,
            customLabel: Value(label),
            note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
            syncState: const Value(SyncState.pending),
          ),
        );
    if (localOnly) {
      return PendingSync(
        HealthCondition(
          localId: localId,
          userId: userId,
          code: code,
          customLabel: label,
          note: note,
        ),
      );
    }
    await syncPendingConditions(userId);
    final rows = await _conditionRows(userId);
    final match = rows.firstWhere((r) => r.localId == localId);
    final view = HealthCondition(
      id: match.serverId,
      localId: match.localId,
      userId: userId,
      code: match.code,
      customLabel: match.customLabel,
      note: match.note,
      isActive: match.isActive,
    );
    if (match.syncState == SyncState.conflict) {
      return ConflictState(view, 'This entry needs review.');
    }
    if (match.syncState == SyncState.pending) return PendingSync(view);
    return Fresh(view);
  }

  /// Edits a condition locally first (pending). A row without a server id
  /// has never left the device, so the edit simply rides the next POST;
  /// otherwise the next push PATCHes the full current values.
  Future<DataState<HealthCondition>> updateCondition(
    String userId,
    String localId, {
    String? code,
    String? customLabel,
    String? note,
    bool? isActive,
    bool clearNote = false,
    bool localOnly = false,
  }) async {
    final rows = await _conditionRows(userId);
    final match = _conditionByLocalId(rows, localId);
    if (match == null || match.isDeleted) {
      throw const Conflict('This entry no longer exists.');
    }
    final newCode = code ?? match.code;
    // Label contract re-validated on every edit: switching to `other`
    // without a label, or keeping a label on a curated code, is rejected
    // locally instead of surfacing a raw 422.
    final labelForValidation = code != null
        ? customLabel
        : (newCode == HealthConditionCodes.other
              ? (customLabel ?? match.customLabel)
              : customLabel);
    final error = validateConditionInput(newCode, labelForValidation);
    if (error != null) throw ValidationError(error);
    final newLabel = newCode == HealthConditionCodes.other
        ? labelForValidation!.trim()
        : null;
    final newNote = clearNote
        ? null
        : (note ?? match.note)?.trim().isEmpty == true
        ? null
        : (note ?? match.note)?.trim();
    await (db.update(
      db.localConditions,
    )..where((t) => t.id.equals(match.id))).write(
      LocalConditionsCompanion(
        code: Value(newCode),
        customLabel: Value(newLabel),
        note: Value(newNote),
        isActive: isActive == null ? const Value.absent() : Value(isActive),
        syncState: const Value(SyncState.pending),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (!localOnly) await syncPendingConditions(userId);
    final fresh = (await _conditionRows(userId))
        .firstWhere((r) => r.localId == localId);
    final view = HealthCondition(
      id: fresh.serverId,
      localId: fresh.localId,
      userId: userId,
      code: fresh.code,
      customLabel: fresh.customLabel,
      note: fresh.note,
      isActive: fresh.isActive,
    );
    if (fresh.syncState == SyncState.conflict) {
      return ConflictState(view, 'This entry needs review.');
    }
    if (fresh.syncState == SyncState.pending) return PendingSync(view);
    return Fresh(view);
  }

  /// Removes a condition: rows that never reached the server disappear
  /// immediately; synced rows become delete tombstones flushed as DELETE
  /// on the next push, so offline deletes never resurrect on refetch.
  Future<void> deleteCondition(
    String userId,
    String localId, {
    bool localOnly = false,
  }) async {
    final rows = await _conditionRows(userId);
    final match = _conditionByLocalId(rows, localId);
    if (match == null) return;
    if (match.serverId == null) {
      await (db.delete(
        db.localConditions,
      )..where((t) => t.id.equals(match.id))).go();
      return;
    }
    await (db.update(
      db.localConditions,
    )..where((t) => t.id.equals(match.id))).write(
      const LocalConditionsCompanion(
        isDeleted: Value(true),
        syncState: Value(SyncState.pending),
      ),
    );
    if (!localOnly) {
      try {
        await syncPendingConditions(userId);
      } on AuthFailure {
        rethrow;
      } on ApiError {
        // Row stays a pending tombstone; the pass retries later.
      }
    }
  }

  /// Pushes pending condition rows oldest-first: tombstones DELETE (a 404
  /// means already gone — desired end state), new rows POST, edited rows
  /// PATCH with full current values. Continues past conflicts; stops the
  /// pass on network/5xx/auth failures.
  Future<void> syncPendingConditions(String userId) async {
    final pending =
        await (db.select(db.localConditions)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.syncState.equals(SyncState.pending.index),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    for (final row in pending) {
      ApiError? failure;
      HealthCondition? created;
      try {
        if (row.isDeleted && row.serverId != null) {
          await api.deleteCondition(row.serverId!);
        } else if (row.isDeleted) {
          // Never reached the server: dropping the local row is the sync.
        } else if (row.serverId == null) {
          created = await api.createCondition({
            'condition_code': row.code,
            if (row.customLabel != null) 'custom_label': row.customLabel,
            if (row.note != null) 'note': row.note,
            'is_active': row.isActive,
          });
        } else {
          created = await api.patchCondition(row.serverId!, {
            'condition_code': row.code,
            'custom_label': row.customLabel,
            'note': row.note,
            'is_active': row.isActive,
          });
        }
      } on ApiError catch (e) {
        failure = e;
      }
      if (failure == null) {
        if (row.isDeleted || created == null) {
          await (db.delete(
            db.localConditions,
          )..where((t) => t.id.equals(row.id))).go();
        } else {
          await (db.update(
            db.localConditions,
          )..where((t) => t.id.equals(row.id))).write(
            LocalConditionsCompanion(
              serverId: Value(created.id),
              code: Value(created.code),
              customLabel: Value(created.customLabel),
              note: Value(created.note),
              isActive: Value(created.isActive),
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
          db.localConditions,
        )..where((t) => t.id.equals(row.id))).write(
          const LocalConditionsCompanion(syncState: Value(SyncState.conflict)),
        );
        continue;
      }
      // Network error, 5xx, or auth failure: stop this pass.
      return;
    }
  }

  // ---------------------------------------------------------- medications

  Future<List<LocalMedication>> _medicationRows(String userId) {
    return (db.select(db.localMedications)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  List<Medication> _assembleMedications(List<LocalMedication> rows) {
    return [
      for (final r in rows.where((r) => !r.isDeleted))
        Medication(
          id: r.serverId,
          localId: r.localId,
          userId: r.userId,
          name: r.name,
          note: r.note,
          isActive: r.isActive,
        ),
    ];
  }

  bool _medsConflict(List<LocalMedication> rows) =>
      rows.any((r) => r.syncState == SyncState.conflict);
  bool _medsPending(List<LocalMedication> rows) =>
      rows.any((r) => r.syncState == SyncState.pending);

  DataState<List<Medication>> _medicationState(List<LocalMedication> rows) {
    final view = _assembleMedications(rows);
    if (view.isEmpty && rows.where((r) => !r.isDeleted).isEmpty) {
      if (_medsConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_medsPending(rows)) return PendingSync(view);
      return const NoData();
    }
    if (_medsConflict(rows)) {
      return ConflictState(view, 'One entry needs review.');
    }
    if (_medsPending(rows)) return PendingSync(view);
    return Fresh(view);
  }

  Future<void> _mergeServerMedications(
    String userId,
    List<Medication> server,
  ) async {
    final rows = await _medicationRows(userId);
    final byServerId = <int, Medication>{};
    for (final s in server) {
      if (s.id != null) byServerId[s.id!] = s;
    }
    await db.transaction(() async {
      for (final s in server) {
        LocalMedication? match;
        for (final r in rows) {
          if (r.serverId != null && r.serverId == s.id) {
            match = r;
            break;
          }
        }
        if (match == null) {
          await db
              .into(db.localMedications)
              .insert(
                LocalMedicationsCompanion.insert(
                  localId: _newLocalId(),
                  userId: userId,
                  serverId: Value(s.id),
                  name: s.name,
                  note: Value(s.note),
                  isActive: Value(s.isActive),
                  syncState: const Value(SyncState.synced),
                ),
              );
        } else if (match.syncState == SyncState.synced) {
          await (db.update(
            db.localMedications,
          )..where((t) => t.id.equals(match!.id))).write(
            LocalMedicationsCompanion(
              name: Value(s.name),
              note: Value(s.note),
              isActive: Value(s.isActive),
            ),
          );
        }
      }
      for (final r in rows) {
        if (r.syncState == SyncState.synced &&
            r.serverId != null &&
            !byServerId.containsKey(r.serverId)) {
          await (db.delete(
            db.localMedications,
          )..where((t) => t.id.equals(r.id))).go();
        }
      }
    });
  }

  Future<DataState<List<Medication>>> loadMedications(String userId) async {
    var rows = await _medicationRows(userId);
    if (rows.where((r) => !r.isDeleted).isEmpty) {
      try {
        await _mergeServerMedications(userId, await api.fetchMedications());
        rows = await _medicationRows(userId);
        if (rows.where((r) => !r.isDeleted).isEmpty) {
          return const NoData();
        }
        return _medicationState(rows);
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
      await _mergeServerMedications(userId, await api.fetchMedications());
    } on ApiError {
      ok = false;
    }
    rows = await _medicationRows(userId);
    final view = _assembleMedications(rows);
    if (!ok) {
      if (_medsConflict(rows)) {
        return ConflictState(view, 'One entry needs review.');
      }
      if (_medsPending(rows)) return PendingSync(view);
      if (view.isEmpty) return const NoData();
      return Cached(view, _latestMedUpdate(rows));
    }
    return _medicationState(rows);
  }

  /// Local-only read for offline tracking: no network attempt, empty is
  /// [NoData].
  Future<DataState<List<Medication>>> loadMedicationsLocal(
    String userId,
  ) async {
    return _medicationState(await _medicationRows(userId));
  }

  DateTime _latestMedUpdate(List<LocalMedication> rows) {
    DateTime latest = rows.first.updatedAt;
    for (final r in rows) {
      if (r.updatedAt.isAfter(latest)) latest = r.updatedAt;
    }
    return latest;
  }

  /// Records a medication locally first (pending), then POSTs unless
  /// [localOnly]. Names are free text and duplicates are allowed, so no
  /// dedupe is attempted; blank names are rejected locally instead of
  /// surfacing a raw 422.
  Future<DataState<Medication>> addMedication(
    String userId, {
    required String name,
    String? note,
    bool isActive = true,
    bool localOnly = false,
  }) async {
    final error = validateMedicationName(name);
    if (error != null) throw ValidationError(error);
    final cleanName = name.trim();
    final cleanNote = note?.trim().isEmpty == true ? null : note?.trim();
    final localId = _newLocalId();
    await db
        .into(db.localMedications)
        .insert(
          LocalMedicationsCompanion.insert(
            localId: localId,
            userId: userId,
            name: cleanName,
            note: Value(cleanNote),
            isActive: Value(isActive),
            syncState: const Value(SyncState.pending),
          ),
        );
    if (localOnly) {
      return PendingSync(
        Medication(
          localId: localId,
          userId: userId,
          name: cleanName,
          note: cleanNote,
          isActive: isActive,
        ),
      );
    }
    await syncPendingMedications(userId);
    final rows = await _medicationRows(userId);
    final match = rows.firstWhere((r) => r.localId == localId);
    final view = Medication(
      id: match.serverId,
      localId: match.localId,
      userId: userId,
      name: match.name,
      note: match.note,
      isActive: match.isActive,
    );
    if (match.syncState == SyncState.conflict) {
      return ConflictState(view, 'This entry needs review.');
    }
    if (match.syncState == SyncState.pending) return PendingSync(view);
    return Fresh(view);
  }

  /// Edits a medication locally first (pending). Name edits re-validate;
  /// clearing the note uses [clearNote] (explicit null clears server-side).
  Future<DataState<Medication>> updateMedication(
    String userId,
    String localId, {
    String? name,
    String? note,
    bool? isActive,
    bool clearNote = false,
    bool localOnly = false,
  }) async {
    final rows = await _medicationRows(userId);
    final match = _medicationByLocalId(rows, localId);
    if (match == null || match.isDeleted) {
      throw const Conflict('This entry no longer exists.');
    }
    final newName = (name ?? match.name).trim();
    final error = validateMedicationName(newName);
    if (error != null) throw ValidationError(error);
    final newNote = clearNote
        ? null
        : (note ?? match.note)?.trim().isEmpty == true
        ? null
        : (note ?? match.note)?.trim();
    await (db.update(
      db.localMedications,
    )..where((t) => t.id.equals(match.id))).write(
      LocalMedicationsCompanion(
        name: Value(newName),
        note: Value(newNote),
        isActive: isActive == null ? const Value.absent() : Value(isActive),
        syncState: const Value(SyncState.pending),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (!localOnly) await syncPendingMedications(userId);
    final fresh = (await _medicationRows(userId))
        .firstWhere((r) => r.localId == localId);
    final view = Medication(
      id: fresh.serverId,
      localId: fresh.localId,
      userId: userId,
      name: fresh.name,
      note: fresh.note,
      isActive: fresh.isActive,
    );
    if (fresh.syncState == SyncState.conflict) {
      return ConflictState(view, 'This entry needs review.');
    }
    if (fresh.syncState == SyncState.pending) return PendingSync(view);
    return Fresh(view);
  }

  /// Removes a medication: rows that never reached the server disappear
  /// immediately; synced rows become delete tombstones flushed as DELETE
  /// on the next push, so offline deletes never resurrect on refetch.
  Future<void> deleteMedication(
    String userId,
    String localId, {
    bool localOnly = false,
  }) async {
    final rows = await _medicationRows(userId);
    final match = _medicationByLocalId(rows, localId);
    if (match == null) return;
    if (match.serverId == null) {
      await (db.delete(
        db.localMedications,
      )..where((t) => t.id.equals(match.id))).go();
      return;
    }
    await (db.update(
      db.localMedications,
    )..where((t) => t.id.equals(match.id))).write(
      const LocalMedicationsCompanion(
        isDeleted: Value(true),
        syncState: Value(SyncState.pending),
      ),
    );
    if (!localOnly) {
      try {
        await syncPendingMedications(userId);
      } on AuthFailure {
        rethrow;
      } on ApiError {
        // Row stays a pending tombstone; the pass retries later.
      }
    }
  }

  /// Pushes pending medication rows oldest-first with the same
  /// tombstone/POST/PATCH/conflict semantics as conditions.
  Future<void> syncPendingMedications(String userId) async {
    final pending =
        await (db.select(db.localMedications)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.syncState.equals(SyncState.pending.index),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    for (final row in pending) {
      ApiError? failure;
      Medication? created;
      try {
        if (row.isDeleted && row.serverId != null) {
          await api.deleteMedication(row.serverId!);
        } else if (row.isDeleted) {
          // Never reached the server: dropping the local row is the sync.
        } else if (row.serverId == null) {
          created = await api.createMedication({
            'name': row.name,
            if (row.note != null) 'note': row.note,
            'is_active': row.isActive,
          });
        } else {
          created = await api.patchMedication(row.serverId!, {
            'name': row.name,
            'note': row.note,
            'is_active': row.isActive,
          });
        }
      } on ApiError catch (e) {
        failure = e;
      }
      if (failure == null) {
        if (row.isDeleted || created == null) {
          await (db.delete(
            db.localMedications,
          )..where((t) => t.id.equals(row.id))).go();
        } else {
          await (db.update(
            db.localMedications,
          )..where((t) => t.id.equals(row.id))).write(
            LocalMedicationsCompanion(
              serverId: Value(created.id),
              name: Value(created.name),
              note: Value(created.note),
              isActive: Value(created.isActive),
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
          db.localMedications,
        )..where((t) => t.id.equals(row.id))).write(
          const LocalMedicationsCompanion(syncState: Value(SyncState.conflict)),
        );
        continue;
      }
      // Network error, 5xx, or auth failure: stop this pass.
      return;
    }
  }

  /// One sync pass over the singleton plus both row kinds, oldest-first
  /// within each kind. Continues past per-row conflicts; stops a kind's
  /// pass on network/5xx/auth failures. Never touches predictions.
  Future<void> syncPending(String userId) async {
    await syncPendingContext(userId);
    await syncPendingConditions(userId);
    await syncPendingMedications(userId);
  }
}

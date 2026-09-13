import 'package:drift/drift.dart';

import '../../core/device_timezone.dart';
import '../../models/profile.dart';
import '../../services/api_service.dart';
import '../app_database.dart';
import '../sync_policy.dart';

/// Offline-capable profile/preferences. Reads serve the local row first;
/// writes apply locally (pending) immediately and PATCH remotely when
/// reachable. Explicit nulls in the payload are preserved end-to-end,
/// matching the backend's clear semantics.
class ProfileRepository {
  final AppDatabase db;
  final ApiService api;

  ProfileRepository(this.db, this.api);

  Future<LocalProfile?> _localRow(String userId) {
    return (db.select(db.localProfiles)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Profile _assemble(LocalProfile row) {
    return Profile(
      userId: row.userId,
      name: row.name,
      usualCycleDays: row.usualCycleDays,
      usualPeriodDays: row.usualPeriodDays,
      theme: row.theme,
      units: row.units,
      timezone: row.timezone,
    );
  }

  Future<void> _store(Profile profile, SyncState state) {
    return db.into(db.localProfiles).insertOnConflictUpdate(
          LocalProfilesCompanion.insert(
            userId: profile.userId,
            name: Value(profile.name),
            usualCycleDays: Value(profile.usualCycleDays),
            usualPeriodDays: Value(profile.usualPeriodDays),
            theme: Value(profile.theme),
            units: Value(profile.units),
            timezone: Value(profile.timezone),
            syncState: Value(state),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<DataState<Profile?>> loadProfile(String userId) async {
    final local = await _localRow(userId);
    if (local == null) {
      try {
        final remote = await api.fetchProfile();
        await _store(remote, SyncState.synced);
        return Fresh<Profile?>(remote);
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
    final view = _assemble(local);
    try {
      final remote = await api.fetchProfile();
      await _store(remote, SyncState.synced);
      return Fresh<Profile?>(remote);
    } on ApiError {
      if (local.syncState == SyncState.conflict) {
        return ConflictState<Profile?>(view, 'Profile needs review.');
      }
      if (local.syncState == SyncState.pending) {
        return PendingSync<Profile?>(view);
      }
      return Cached<Profile?>(view, local.updatedAt);
    }
  }

  /// Applies [payload] locally first (keys present with null clear the
  /// field), then PATCHes remotely. Stays pending while offline.
  Future<DataState<Profile>> saveProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final local = await _localRow(userId);
    final merged = _applyPayload(
      userId,
      local == null ? null : _assemble(local),
      payload,
    );
    await _store(merged, SyncState.pending);
    try {
      final remote = await api.patchProfile(payload);
      await _store(remote, SyncState.synced);
      return Fresh(remote);
    } on ApiError catch (e) {
      if (e is AuthFailure) rethrow;
      if (classifySyncError(e) == SyncOutcome.conflict) {
        await _store(merged, SyncState.conflict);
        return ConflictState(merged, e.message);
      }
      return PendingSync(merged);
    }
  }

  Profile _applyPayload(
    String userId,
    Profile? base,
    Map<String, dynamic> payload,
  ) {
    dynamic pick(String key, dynamic current) =>
        payload.containsKey(key) ? payload[key] : current;
    int? asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
    return Profile(
      userId: userId,
      name: pick('name', base?.name) as String?,
      usualCycleDays: asInt(pick('usual_cycle_days', base?.usualCycleDays)),
      usualPeriodDays:
          asInt(pick('usual_period_days', base?.usualPeriodDays)),
      theme: pick('theme', base?.theme) as String?,
      units: pick('units', base?.units) as String?,
      timezone: pick('timezone', base?.timezone) as String?,
    );
  }

  /// Ensures the server profile carries the current device IANA timezone.
  ///
  /// Compares the device zone against the local row; when they differ (or
  /// the row is missing the zone), stores the device value locally as
  /// pending — the existing [syncPending] machinery PATCHes it upstream,
  /// so this works offline and survives travel. Unknown device zone is a
  /// silent no-op (keeps the stored value; retried next session). Never
  /// throws: timezone sync must never break profile loading or syncing.
  Future<void> refreshDeviceTimezone(String userId) async {
    try {
      final deviceTz = await deviceTimeZoneId();
      if (deviceTz == null || deviceTz.isEmpty) return;
      final local = await _localRow(userId);
      if (local?.timezone == deviceTz) return;
      final merged = _applyPayload(
        userId,
        local == null ? null : _assemble(local),
        {'timezone': deviceTz},
      );
      await _store(merged, SyncState.pending);
      await syncPending(userId);
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Pushes the single pending profile row, if any. A null timezone is
  /// omitted (never cleared remotely): the client only ever sets the zone
  /// from the device and must not wipe a value stored by another device.
  Future<void> syncPending(String userId) async {
    final local = await _localRow(userId);
    if (local == null || local.syncState != SyncState.pending) return;
    final view = _assemble(local);
    final payload = <String, dynamic>{
      'name': view.name,
      'usual_cycle_days': view.usualCycleDays,
      'usual_period_days': view.usualPeriodDays,
      'theme': view.theme,
      'units': view.units,
    };
    if (view.timezone != null) {
      payload['timezone'] = view.timezone;
    }
    try {
      final remote = await api.patchProfile(payload);
      await _store(remote, SyncState.synced);
    } on ApiError catch (e) {
      final outcome = classifySyncError(e);
      if (outcome == SyncOutcome.conflict) {
        await _store(view, SyncState.conflict);
      }
      // retryLater/authError: row stays pending; pass ends here.
    }
  }
}

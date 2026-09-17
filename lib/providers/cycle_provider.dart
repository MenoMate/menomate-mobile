import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_database.dart' show OfflineAdoptionCounts;
import '../data/sync_policy.dart';
import '../models/cycle.dart';
import '../models/summary.dart';
import 'care_session_provider.dart';
import 'data_providers.dart';
import 'health_providers.dart';
import 'offline_mode_provider.dart';
import 'profile_provider.dart';

/// Local-first cycle providers. Names and granularity are unchanged from
/// the network-only implementation; only the value type is now [DataState]
/// so UI can distinguish fresh / cached / pending / unavailable / conflict
/// instead of conflating network failure with no-data.
/// True while serving local-only tracking rows. Read once per provider
/// evaluation so auth and offline paths stay explicit at every call site.
bool _isOffline(Ref ref) => ref.watch(isOfflineTrackingProvider);

final currentCycleProvider = FutureProvider<DataState<CurrentCycleResponse?>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const NoData();
  final repo = ref.watch(cycleRepositoryProvider);
  if (_isOffline(ref)) return repo.loadCurrentLocal(userId);
  return repo.loadCurrent(userId);
});

final historySummaryProvider =
    FutureProvider<DataState<HistorySummaryResponse>>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) {
        return const Unavailable('Signed out.');
      }
      final repo = ref.watch(cycleRepositoryProvider);
      if (_isOffline(ref)) return repo.loadHistoryLocal(userId);
      return repo.loadHistory(userId);
    });

final cycleListProvider = FutureProvider<DataState<List<CycleResponse>>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Unavailable('Signed out.');
  final repo = ref.watch(cycleRepositoryProvider);
  if (_isOffline(ref)) return repo.loadCyclesLocal(userId);
  return repo.loadCycles(userId);
});

/// Offline-created tracking rows waiting for an explicit, consented move
/// into the signed-in account. Null when there is nothing to offer (no
/// session, nothing stored, or already declined for this account).
/// Health rows (conditions, medications, singleton context) ride the same
/// offer; the counts keep the confirmation honest about what will move.
final offlineAdoptionProvider = FutureProvider<OfflineAdoptionCounts?>((
  ref,
) async {
  final authId = ref.watch(authUserIdProvider);
  final notifier = ref.watch(offlineModeProvider.notifier);
  final db = ref.watch(appDatabaseProvider);
  if (authId == null) return null;
  if (await notifier.isAdoptionDeclined(authId)) return null;
  final counts = await db.offlineAdoptableCounts();
  if (counts.cycles == 0 && counts.logs == 0) return null;
  return counts;
});

/// Moves consented offline rows into the signed-in account and pushes them
/// through the normal per-row sync/conflict machinery. Never called
/// without the user explicitly asking (Settings offer card). Health rows
/// move under the same consent; the account profile stays authoritative.
Future<OfflineAdoptionCounts> adoptOfflineDataIntoAccount(WidgetRef ref) async {
  final authId = ref.read(authUserIdProvider);
  if (authId == null) {
    throw StateError('Cannot adopt offline data without a signed-in account.');
  }
  final counts = await ref.read(appDatabaseProvider).adoptOfflineData(authId);
  try {
    await ref.read(cycleRepositoryProvider).syncPending(authId);
    await ref.read(dailyLogRepositoryProvider).syncPending(authId);
    await ref.read(healthContextRepositoryProvider).syncPending(authId);
  } catch (_) {
    // Best-effort push; pending rows retry on the next sync pass.
  }
  refreshAllAppData(ref);
  ref.invalidate(offlineAdoptionProvider);
  return counts;
}

void refreshAllAppData(WidgetRef ref) {
  ref.invalidate(currentCycleProvider);
  ref.invalidate(historySummaryProvider);
  ref.invalidate(cycleListProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(healthContextProvider);
  ref.invalidate(conditionsProvider);
  ref.invalidate(medicationsProvider);
}

/// Same invalidation set for non-widget provider contexts.
void refreshProviders(Ref ref) {
  ref.invalidate(currentCycleProvider);
  ref.invalidate(historySummaryProvider);
  ref.invalidate(cycleListProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(healthContextProvider);
  ref.invalidate(conditionsProvider);
  ref.invalidate(medicationsProvider);
}

bool _syncInFlight = false;

/// Runs one sync pass over all three repositories, then refreshes UI.
/// Triggered on reconnect and on app start. Not a background engine:
/// single pass per trigger, oldest-first inside each repository.
Future<void> syncAllPending(Ref ref) async {
  if (_syncInFlight) return;
  _syncInFlight = true;
  try {
    // Auth-only on purpose: local-only tracking rows are never pushed
    // without the explicit, consented adoption in Settings.
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;
    final cycleRepo = ref.read(cycleRepositoryProvider);
    final logRepo = ref.read(dailyLogRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final healthRepo = ref.read(healthContextRepositoryProvider);
    // Device timezone first: any change is staged as pending here and
    // flushed by profileRepo.syncPending below, in the same pass.
    await profileRepo.refreshDeviceTimezone(userId);
    await cycleRepo.syncPending(userId);
    await logRepo.syncPending(userId);
    await profileRepo.syncPending(userId);
    // Health context rides the same auth-gated pass. It only ever pushes
    // user-provided values; it never reads predictions and never triggers
    // a prediction refresh.
    await healthRepo.syncPending(userId);
    refreshProviders(ref);
  } catch (_) {
    // Sync is best-effort; local data remains usable. Errors surface
    // through DataState on the next provider load.
  } finally {
    _syncInFlight = false;
  }
}

/// Observes connectivity (hint only — API outcome stays authoritative) and
/// runs [syncAllPending] on reconnect and once at startup.
final connectivitySyncProvider = Provider<void>((ref) {
  Future.microtask(() => syncAllPending(ref));
  final sub = Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((r) => r != ConnectivityResult.none)) {
      syncAllPending(ref);
    }
  });
  ref.onDispose(() => sub.cancel());
});

/// Signs out and wipes every user-scoped local row + cached prediction so
/// the next user on this device can never see previous local data.
Future<void> signOutAndClearLocalData(WidgetRef ref) async {
  try {
    await ref.read(appDatabaseProvider).clearAllUserData();
  } catch (_) {
    // Wipe is best-effort; sign-out still proceeds.
  }
  // Active Care session is in-memory only, but must still be dropped so
  // the next user never inherits conversation context.
  try {
    ref.invalidate(careSessionProvider);
  } catch (_) {
    // Provider may be uninitialized in some scopes; sign-out proceeds.
  }
  // A wiped device returns to the undecided path choice, never to a stale
  // offline session whose rows no longer exist.
  try {
    await ref.read(offlineModeProvider.notifier).disable();
  } catch (_) {
    // Flag persistence is best-effort; sign-out still proceeds.
  }
  await Supabase.instance.client.auth.signOut();
  refreshAllAppData(ref);
}

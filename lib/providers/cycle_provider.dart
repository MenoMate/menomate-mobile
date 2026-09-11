import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sync_policy.dart';
import '../models/cycle.dart';
import '../models/summary.dart';
import 'data_providers.dart';
import 'profile_provider.dart';

/// Local-first cycle providers. Names and granularity are unchanged from
/// the network-only implementation; only the value type is now [DataState]
/// so UI can distinguish fresh / cached / pending / unavailable / conflict
/// instead of conflating network failure with no-data.
final currentCycleProvider =
    FutureProvider<DataState<CurrentCycleResponse?>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const NoData();
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.loadCurrent(userId);
});

final historySummaryProvider =
    FutureProvider<DataState<HistorySummaryResponse>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Unavailable('Signed out.');
  }
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.loadHistory(userId);
});

final cycleListProvider =
    FutureProvider<DataState<List<CycleResponse>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Unavailable('Signed out.');
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.loadCycles(userId);
});

void refreshAllAppData(WidgetRef ref) {
  ref.invalidate(currentCycleProvider);
  ref.invalidate(historySummaryProvider);
  ref.invalidate(cycleListProvider);
  ref.invalidate(profileProvider);
}

/// Same invalidation set for non-widget provider contexts.
void refreshProviders(Ref ref) {
  ref.invalidate(currentCycleProvider);
  ref.invalidate(historySummaryProvider);
  ref.invalidate(cycleListProvider);
  ref.invalidate(profileProvider);
}

bool _syncInFlight = false;

/// Runs one sync pass over all three repositories, then refreshes UI.
/// Triggered on reconnect and on app start. Not a background engine:
/// single pass per trigger, oldest-first inside each repository.
Future<void> syncAllPending(Ref ref) async {
  if (_syncInFlight) return;
  _syncInFlight = true;
  try {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final cycleRepo = ref.read(cycleRepositoryProvider);
    final logRepo = ref.read(dailyLogRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    await cycleRepo.syncPending(userId);
    await logRepo.syncPending(userId);
    await profileRepo.syncPending(userId);
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
  await Supabase.instance.client.auth.signOut();
  refreshAllAppData(ref);
}

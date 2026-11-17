import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_policy.dart';
import '../models/reproductive.dart';
import 'data_providers.dart';
import 'offline_mode_provider.dart';

/// Phase 5 reproductive-health providers.
///
/// Local-first, mirroring the cycle and health providers: the effective
/// tracking id selects the rows, and the offline branch serves strictly
/// local reads so opening reproductive surfaces never triggers a network
/// call while offline. Writes use the repositories' `localOnly` paths
/// while offline.
///
/// Estimate boundary: [fertilityEstimateProvider] exposes the
/// server-computed estimate verbatim. Estimates are never cached locally
/// (a stale fertile window must never display as current), so the offline
/// branch is [Unavailable] with guidance — while logged signs stay
/// available through [observationsProvider].
///
/// Suppression boundary: when pregnancy mode is active, the backend answers
/// estimates as SUPPRESSED with null dates. This layer passes that through
/// untouched; UI hides fertile dates for every non-AVAILABLE state.
bool _isOffline(Ref ref) => ref.watch(isOfflineTrackingProvider);

final observationsProvider =
    FutureProvider<DataState<List<FertilityObservation>>>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) {
        return const Unavailable('Signed out.');
      }
      final repo = ref.watch(reproductiveRepositoryProvider);
      if (_isOffline(ref)) return repo.loadObservationsLocal(userId);
      return repo.loadObservations(userId);
    });

final fertilityEstimateProvider = FutureProvider<DataState<FertilityEstimate?>>(
  (ref) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const NoData();
    final repo = ref.watch(reproductiveRepositoryProvider);
    if (_isOffline(ref)) return repo.loadEstimateLocal();
    return repo.loadEstimate();
  },
);

final pregnancyProvider = FutureProvider<DataState<PregnancyContext?>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const NoData();
  final repo = ref.watch(reproductiveRepositoryProvider);
  if (_isOffline(ref)) return repo.loadPregnancyLocal(userId);
  return repo.loadPregnancy(userId);
});

final agingProvider = FutureProvider<DataState<AgingContext?>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const NoData();
  final repo = ref.watch(reproductiveRepositoryProvider);
  if (_isOffline(ref)) return repo.loadAgingLocal(userId);
  return repo.loadAging(userId);
});

/// Refreshes only the reproductive providers. Reproductive writes never
/// touch cycle, history, prediction, or health-context state — targeted
/// invalidation keeps that boundary visible at every call site.
void refreshReproductiveData(WidgetRef ref) {
  ref.invalidate(observationsProvider);
  ref.invalidate(fertilityEstimateProvider);
  ref.invalidate(pregnancyProvider);
  ref.invalidate(agingProvider);
}

/// Same invalidation set for non-widget provider contexts.
void refreshReproductiveProviders(Ref ref) {
  ref.invalidate(observationsProvider);
  ref.invalidate(fertilityEstimateProvider);
  ref.invalidate(pregnancyProvider);
  ref.invalidate(agingProvider);
}

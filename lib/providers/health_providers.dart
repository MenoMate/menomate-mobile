import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_policy.dart';
import '../models/health_context.dart';
import 'data_providers.dart';
import 'offline_mode_provider.dart';

/// V1 Health Context foundation providers.
///
/// Local-first, mirroring the cycle providers: the effective tracking id
/// selects the rows, and the offline branch serves strictly local reads so
/// opening Health Context never triggers a Supabase call or an auth
/// prompt. Writes use the repositories' `localOnly` paths while offline.
///
/// Personalization boundary: these providers expose user-provided context
/// for future consumers (insights, education, Care). They never feed
/// prediction inputs, never alter confidence or phase, and no prediction
/// code watches them.
bool _isOffline(Ref ref) => ref.watch(isOfflineTrackingProvider);

final healthContextProvider = FutureProvider<DataState<HealthContext?>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const NoData();
  final repo = ref.watch(healthContextRepositoryProvider);
  if (_isOffline(ref)) return repo.loadHealthContextLocal(userId);
  return repo.loadHealthContext(userId);
});

final conditionsProvider = FutureProvider<DataState<List<HealthCondition>>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Unavailable('Signed out.');
  }
  final repo = ref.watch(healthContextRepositoryProvider);
  if (_isOffline(ref)) return repo.loadConditionsLocal(userId);
  return repo.loadConditions(userId);
});

final medicationsProvider = FutureProvider<DataState<List<Medication>>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Unavailable('Signed out.');
  }
  final repo = ref.watch(healthContextRepositoryProvider);
  if (_isOffline(ref)) return repo.loadMedicationsLocal(userId);
  return repo.loadMedications(userId);
});

/// Refreshes only the health providers. Health writes never touch cycle,
/// history, or prediction state — targeted invalidation keeps that
/// boundary visible at every call site.
void refreshHealthData(WidgetRef ref) {
  ref.invalidate(healthContextProvider);
  ref.invalidate(conditionsProvider);
  ref.invalidate(medicationsProvider);
}

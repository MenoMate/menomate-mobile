import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/repositories/daily_log_repository.dart';
import '../data/repositories/health_context_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/reproductive_repository.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'offline_mode_provider.dart';

/// Dependency root for the local-first data layer. The database instance
/// is provided by `main()` (file-backed) and overridden with an in-memory
/// database in tests.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError(
    'AppDatabase not initialized. Provide appDatabaseProvider override.',
  );
});

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  return CycleRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiServiceProvider),
  );
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiServiceProvider),
  );
});

final healthContextRepositoryProvider = Provider<HealthContextRepository>((
  ref,
) {
  return HealthContextRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiServiceProvider),
  );
});

/// Phase 5 reproductive repository: fertility observations (offline-first
/// rows), read-only fertility estimates, explicit pregnancy mode, and
/// user-declared aging context. Same local-first contract as the other
/// repositories; never touches predictions.
final reproductiveRepositoryProvider = Provider<ReproductiveRepository>((ref) {
  return ReproductiveRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiServiceProvider),
  );
});

/// Supabase user id, or null without a session. Auth-only: used to gate
/// server sync, which must never run for local-only tracking rows.
final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.id;
});

/// Effective tracking identity for local reads/writes: the Supabase id
/// when signed in, otherwise the stable local id while using MenoMate
/// offline, otherwise null (no path chosen yet). Local rows are always
/// keyed by this id; no schema change was needed for offline tracking.
final currentUserIdProvider = Provider<String?>((ref) {
  final authId = ref.watch(authStateProvider).value?.id;
  if (authId != null) return authId;
  final offline = ref.watch(offlineModeProvider).value ?? false;
  return offline ? kOfflineUserId : null;
});

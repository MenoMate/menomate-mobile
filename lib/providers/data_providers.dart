import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/repositories/daily_log_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

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

/// Current authenticated user id, or null when signed out.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.id;
});

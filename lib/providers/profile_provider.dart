import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_policy.dart';
import '../models/profile.dart';
import 'auth_provider.dart';
import 'data_providers.dart';

/// Local-first profile state. Same provider name as before; the value is
/// now [DataState] so callers (router, splash) can tell cached profile
/// from "needs onboarding" from genuine unavailability.
class ProfileNotifier extends AsyncNotifier<DataState<Profile?>> {
  @override
  Future<DataState<Profile?>> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const NoData();
    }

    final repo = ref.watch(profileRepositoryProvider);
    return await repo.loadProfile(user.id);
  }

  void setProfile(Profile profile) {
    state = AsyncData(Fresh<Profile?>(profile));
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return const NoData<Profile?>();
      final repo = ref.read(profileRepositoryProvider);
      return await repo.loadProfile(userId);
    });
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, DataState<Profile?>>(
        ProfileNotifier.new);

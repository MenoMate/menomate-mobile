import 'dart:async';

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
    final state = await repo.loadProfile(user.id);
    // Fire-and-forget: keep the server profile's canonical timezone in
    // step with this device (covers login, travel, and legacy users with
    // no zone yet). Never blocks or breaks profile loading.
    unawaited(repo.refreshDeviceTimezone(user.id));
    return state;
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
      final loaded = await repo.loadProfile(userId);
      unawaited(repo.refreshDeviceTimezone(userId));
      return loaded;
    });
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, DataState<Profile?>>(
        ProfileNotifier.new);

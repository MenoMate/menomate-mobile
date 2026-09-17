import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart' show kOfflineUserId;
import '../data/sync_policy.dart';
import '../models/profile.dart';
import 'auth_provider.dart';
import 'data_providers.dart';
import 'offline_mode_provider.dart';

/// Local-first profile state. Same provider name as before; the value is
/// now [DataState] so callers (router, splash) can tell cached profile
/// from "needs onboarding" from genuine unavailability.
class ProfileNotifier extends AsyncNotifier<DataState<Profile?>> {
  @override
  Future<DataState<Profile?>> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      // Local-only tracking serves the offline profile without any network
      // attempt; no local row is NoData (onboarding not done), never an
      // auth prompt. Undecided users (no offline choice) stay NoData too.
      final offline = ref.watch(offlineModeProvider).value ?? false;
      if (!offline) return const NoData();
      final repo = ref.watch(profileRepositoryProvider);
      return repo.loadProfileLocal(kOfflineUserId);
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
      ProfileNotifier.new,
    );

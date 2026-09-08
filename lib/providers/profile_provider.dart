import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return null;
    }

    final apiService = ref.watch(apiServiceProvider);
    return await apiService.getProfile();
  }

  void setProfile(Profile profile) {
    state = AsyncData(profile);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getProfile();
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

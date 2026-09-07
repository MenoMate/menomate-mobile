import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return null; // Not authenticated
  }

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getProfile();
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import 'data_providers.dart';

/// Explicit onboarding-completion flag, per tracking identity.
///
/// ROOT-CAUSE FIX: the router previously derived "onboarded" solely from
/// `profile.name != null && non-empty`. That single derived gate cannot
/// distinguish a genuinely new user from:
/// - a fresh install whose local DB was wiped but whose server row exists,
/// - a transient backend response with an empty name that overwrote a good
///   local row,
/// - an offline-local id vs authenticated id split.
///
/// This provider persists an explicit boolean per userId:
/// `menomate.onboarding_completed.<userId>`. It is set only after a
/// successful onboarding submission (online or offline) and cleared only on
/// explicit sign-out wipe. The router treats a user as onboarded when
/// EITHER the profile has a non-empty name OR this flag is true, so a
/// transient empty-name payload can never bounce an existing user back
/// into onboarding.
///
/// The flag is local-only and never sent to the backend (no backend field
/// exists for it). It complements — never replaces — the server profile.
class OnboardingStatusNotifier extends AsyncNotifier<bool> {
  static String prefsKey(String userId) =>
      'menomate.onboarding_completed.$userId';

  @override
  Future<bool> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('prefs'),
      );
      return prefs.getBool(prefsKey(userId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding complete for the current identity. Best-effort
  /// persistence: in-memory state wins for this session.
  Future<void> markCompleted() async {
    state = const AsyncData(true);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('prefs'),
      );
      await prefs
          .setBool(prefsKey(userId), true)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
    } catch (_) {
      // In-memory state still applies.
    }
  }

  /// Clear the flag (used on explicit sign-out wipe / test reset).
  Future<void> clear() async {
    state = const AsyncData(false);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('prefs'),
      );
      await prefs
          .remove(prefsKey(userId))
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
    } catch (_) {
      // Best-effort only.
    }
  }
}

final onboardingStatusProvider =
    AsyncNotifierProvider<OnboardingStatusNotifier, bool>(
      OnboardingStatusNotifier.new,
    );

/// Canonical onboarded test shared by router and UI.
///
/// A user is onboarded when the profile carries a non-empty name OR the
/// explicit local completion flag is set. The flag covers the case where a
/// transient empty-name payload arrives for an existing user; the name
/// covers fresh installs where the flag was never set but the server row
/// already has a name (existing account sign-in on a new device).
bool isProfileOnboarded(Profile? profile, bool completedFlag) {
  if (completedFlag) return true;
  return profile != null &&
      profile.name != null &&
      profile.name!.trim().isNotEmpty;
}

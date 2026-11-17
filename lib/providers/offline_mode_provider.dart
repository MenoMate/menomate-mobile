import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

const _kOfflineModeKey = 'menomate.offline_mode';
const _kAdoptionDeclinedPrefix = 'menomate.adoption_declined.';
const _kIntroDismissedPrefix = 'menomate.intro_dismissed.';

/// Whether the user chose "Continue Offline" (local-only tracking).
///
/// Persisted in SharedPreferences so the choice survives app restarts
/// without internet or an account. Any persistence failure degrades to
/// in-memory state (notably widget tests without a plugin mock); the
/// setters still update [state] so the UI remains consistent.
///
/// This file never touches Supabase Auth: enabling offline mode must not
/// create an anonymous session, a fake UUID, or any credential.
///
/// Timing invariant: the router shows splash while this provider loads, and
/// [enable] sets synchronously, so every tracking screen observes a settled
/// value. Event handlers may therefore use sync reads of
/// [isOfflineTrackingProvider]; tests must first settle the provider
/// (e.g. `await container.read(offlineModeProvider.future)`).
class OfflineModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOfflineModeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist(bool value) async {
    state = AsyncData(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOfflineModeKey, value);
    } catch (_) {
      // Persistence unavailable; in-memory state still applies.
    }
  }

  /// Enter local-only tracking. Creates no account and no session.
  Future<void> enable() => _persist(true);

  /// Leave local-only tracking (e.g. after signing in). Rows already
  /// stored under [kOfflineUserId] are left untouched; see
  /// `AppDatabase.adoptOfflineData` for the explicit, consented move.
  Future<void> disable() => _persist(false);

  /// Records that [authUserId] declined moving offline data into their
  /// account, so the offer is not repeated.
  Future<void> declineAdoption(String authUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_kAdoptionDeclinedPrefix$authUserId', true);
    } catch (_) {
      // Best-effort only; the offer may repeat next launch.
    }
  }

  /// Records that the first-use intro for [feature] was seen for the
  /// tracking identity [userId] (authenticated id or [kOfflineUserId]).
  /// Per-identity keys keep one device user's dismissal from hiding the
  /// intro from another.
  Future<void> dismissFeature(String feature, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_kIntroDismissedPrefix$feature.$userId', true);
    } catch (_) {
      // Best-effort only; the intro may repeat next launch.
    }
  }

  /// Whether the first-use intro for [feature] was dismissed for [userId].
  /// Unknown on failure (treated as "not dismissed": showing an extra
  /// skippable intro is always the safe direction).
  Future<bool> isFeatureDismissed(String feature, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_kIntroDismissedPrefix$feature.$userId') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether [authUserId] already declined the offline-data offer.
  /// Unknown on failure (treated as "not declined" by callers that can
  /// re-check cheaply).
  Future<bool> isAdoptionDeclined(String authUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_kAdoptionDeclinedPrefix$authUserId') ?? false;
    } catch (_) {
      return false;
    }
  }
}

final offlineModeProvider = AsyncNotifierProvider<OfflineModeNotifier, bool>(
  OfflineModeNotifier.new,
);

/// True while tracking locally with no Supabase session: the offline user
/// is a legitimate tracker, never a signed-out or expired state.
final isOfflineTrackingProvider = Provider<bool>((ref) {
  final authId = ref.watch(authStateProvider).value?.id;
  if (authId != null) return false;
  return ref.watch(offlineModeProvider).value ?? false;
});

/// Clears a stale offline flag once a real session exists. Supabase Auth
/// is authoritative: an authenticated user is never in offline mode, even
/// if the flag was set before signing in.
final offlineFlagJanitorProvider = Provider<void>((ref) {
  final authId = ref.watch(authStateProvider).value?.id;
  final offline = ref.watch(offlineModeProvider).value ?? false;
  if (authId != null && offline) {
    Future.microtask(() => ref.read(offlineModeProvider.notifier).disable());
  }
});

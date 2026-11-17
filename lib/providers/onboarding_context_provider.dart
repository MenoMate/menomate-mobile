import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_providers.dart';

/// A lightweight, explicitly optional age-range answer.
///
/// This is onboarding *context*, not identity: it never replaces birth
/// month/year (Profile/Settings), is never sent to any backend (no
/// backend field exists for it), and never drives predictions, phases,
/// or diagnoses. It exists so future content relevance (e.g. which
/// educational topics to surface) has a clean, consented signal to read —
/// but no such consumption exists yet, and none may assume what a range
/// means about any individual (55+ is context, never a menopause label).
class AgeRange {
  final String key;
  final String label;

  const AgeRange(this.key, this.label);
}

/// Display order. Keys are the persisted wire values; labels are UI-only.
const List<AgeRange> kAgeRanges = [
  AgeRange('under_18', 'Under 18'),
  AgeRange('18_24', '18–24'),
  AgeRange('25_34', '25–34'),
  AgeRange('35_44', '35–44'),
  AgeRange('45_54', '45–54'),
  AgeRange('55_plus', '55+'),
  AgeRange('prefer_not_to_say', 'Prefer not to say'),
];

/// Human label for a stored key, or null when unset/unknown. Display-only.
String? ageRangeLabel(String? key) {
  if (key == null) return null;
  for (final range in kAgeRanges) {
    if (range.key == key) return range.label;
  }
  return null;
}

/// Local-only age-range store, keyed by tracking identity (authenticated
/// id or offline local id) so one device user's answer never leaks into
/// another's. Mirrors the OfflineModeNotifier persistence pattern:
/// SharedPreferences, best-effort, in-memory state always wins for the
/// running session. Never touches the network or Supabase.
class AgeRangeNotifier extends AsyncNotifier<String?> {
  static String _prefsKey(String userId) => 'menomate.age_range.$userId';

  @override
  Future<String?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey(userId));
      // Only honor known keys; stale/foreign values read as unset.
      return ageRangeLabel(stored) == null && stored != null ? null : stored;
    } catch (_) {
      return null;
    }
  }

  /// Persist [key] (or clear with null). Best-effort: state updates even
  /// if storage is unavailable, and callers must never fail onboarding
  /// or profile saves over this write.
  Future<void> setAgeRange(String? key) async {
    state = AsyncData(key);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key == null) {
        await prefs.remove(_prefsKey(userId));
      } else {
        await prefs.setString(_prefsKey(userId), key);
      }
    } catch (_) {
      // Persistence unavailable; in-memory state still applies.
    }
  }
}

final ageRangeProvider = AsyncNotifierProvider<AgeRangeNotifier, String?>(
  AgeRangeNotifier.new,
);

/// Local-only onboarding context for fields with NO backend support yet.
///
/// BACKEND GAP (see docs/backend_gaps.md): height, weight, goal, and period
/// regularity have no backend column/endpoint. These values are collected in
/// the one-question-per-screen onboarding for UX completeness, stored ONLY
/// on this device per tracking identity, and NEVER sent to any API, NEVER
/// used for predictions/phases/diagnoses. When backend fields land, this
/// provider is the single migration point.
class OnboardingContext {
  final int? heightCm;
  final int? weightKg;
  final String? goalKey;
  final String? regularityKey;

  const OnboardingContext({
    this.heightCm,
    this.weightKg,
    this.goalKey,
    this.regularityKey,
  });

  OnboardingContext copyWith({
    int? heightCm,
    int? weightKg,
    String? goalKey,
    String? regularityKey,
    bool clearHeight = false,
    bool clearWeight = false,
    bool clearGoal = false,
    bool clearRegularity = false,
  }) {
    return OnboardingContext(
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      goalKey: clearGoal ? null : (goalKey ?? this.goalKey),
      regularityKey: clearRegularity
          ? null
          : (regularityKey ?? this.regularityKey),
    );
  }
}

/// Goal options shown in onboarding. Only `track_cycle` and
/// `understand_body` map to functionality the current backend supports
/// (cycle tracking + educational insights). The rest are explicitly marked
/// in UI as "coming with backend support" and never change app behaviour.
class OnboardingGoal {
  final String key;
  final String label;
  final String description;
  final bool supportedNow;

  const OnboardingGoal(
    this.key,
    this.label,
    this.description,
    this.supportedNow,
  );
}

const List<OnboardingGoal> kOnboardingGoals = [
  OnboardingGoal(
    'track_cycle',
    'Track my cycle',
    'Log periods and symptoms.',
    true,
  ),
  OnboardingGoal(
    'understand_body',
    'Understand my body better',
    'Learn patterns from your logs.',
    true,
  ),
  OnboardingGoal(
    'plan_pregnancy',
    'Plan for pregnancy',
    'Requires backend support — tracked as preference only for now.',
    false,
  ),
  OnboardingGoal(
    'track_pregnancy',
    'Track pregnancy',
    'Requires backend support — tracked as preference only for now.',
    false,
  ),
  OnboardingGoal(
    'perimenopause',
    'Understand perimenopause',
    'Requires backend support — tracked as preference only for now.',
    false,
  ),
];

String? onboardingGoalLabel(String? key) {
  if (key == null) return null;
  for (final g in kOnboardingGoals) {
    if (g.key == key) return g.label;
  }
  return null;
}

const List<(String, String)> kPeriodRegularityOptions = [
  ('yes', 'Yes, fairly regular'),
  ('no', 'No, it varies'),
  ('unsure', 'I\u2019m not sure'),
];

String? periodRegularityLabel(String? key) {
  if (key == null) return null;
  for (final o in kPeriodRegularityOptions) {
    if (o.$1 == key) return o.$2;
  }
  return null;
}

class OnboardingContextNotifier extends AsyncNotifier<OnboardingContext> {
  static String _prefsKey(String userId, String field) =>
      'menomate.onboarding_ctx.$field.$userId';

  @override
  Future<OnboardingContext> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const OnboardingContext();
    try {
      final prefs = await SharedPreferences.getInstance();
      return OnboardingContext(
        heightCm: prefs.getInt(_prefsKey(userId, 'height_cm')),
        weightKg: prefs.getInt(_prefsKey(userId, 'weight_kg')),
        goalKey: prefs.getString(_prefsKey(userId, 'goal')),
        regularityKey: prefs.getString(_prefsKey(userId, 'regularity')),
      );
    } catch (_) {
      return const OnboardingContext();
    }
  }

  Future<void> _save(String field, Object? value) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKey(userId, field);
      if (value == null) {
        await prefs.remove(key);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> setHeightCm(int? cm) async {
    final cur = state.value ?? const OnboardingContext();
    state = AsyncData(cur.copyWith(heightCm: cm, clearHeight: cm == null));
    await _save('height_cm', cm);
  }

  Future<void> setWeightKg(int? kg) async {
    final cur = state.value ?? const OnboardingContext();
    state = AsyncData(cur.copyWith(weightKg: kg, clearWeight: kg == null));
    await _save('weight_kg', kg);
  }

  Future<void> setGoal(String? key) async {
    final cur = state.value ?? const OnboardingContext();
    state = AsyncData(cur.copyWith(goalKey: key, clearGoal: key == null));
    await _save('goal', key);
  }

  Future<void> setRegularity(String? key) async {
    final cur = state.value ?? const OnboardingContext();
    state = AsyncData(
      cur.copyWith(regularityKey: key, clearRegularity: key == null),
    );
    await _save('regularity', key);
  }
}

final onboardingContextProvider =
    AsyncNotifierProvider<OnboardingContextNotifier, OnboardingContext>(
      OnboardingContextNotifier.new,
    );

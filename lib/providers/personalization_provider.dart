import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/interests.dart';
import 'data_providers.dart';

/// Local-only personalization store (Phase 1 adaptive onboarding).
///
/// Same architecture as the other local-only onboarding context
/// ([onboardingContextProvider], [ageRangeProvider]): SharedPreferences
/// keyed by tracking identity (authenticated id or offline local id),
/// best-effort persistence, in-memory state always wins for the running
/// session. Never touches the network or Supabase.
///
/// BACKEND GAP (see `docs/backend_gaps.md`): the onboarding/profile
/// contract has no interests/mode fields, so this data lives ONLY on this
/// device and is NEVER sent to any API. When backend fields land, this
/// provider is the single migration point. Interests never drive
/// predictions, phases, estimates, or diagnoses.
class PersonalizationNotifier extends AsyncNotifier<Personalization> {
  static String _prefsKey(String userId, String field) =>
      'menomate.personalization.$field.$userId';

  @override
  Future<Personalization> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Personalization();
    try {
      final prefs = await SharedPreferences.getInstance();
      final interests =
          prefs.getStringList(_prefsKey(userId, 'interests')) ?? const [];
      final modeRaw = prefs.getString(_prefsKey(userId, 'mode'));
      final areas =
          prefs.getStringList(_prefsKey(userId, 'symptom_areas')) ?? const [];
      final fertility =
          prefs.getStringList(_prefsKey(userId, 'fertility')) ?? const [];
      final categories =
          prefs.getStringList(_prefsKey(userId, 'categories')) ?? const [];
      final concerns =
          prefs.getStringList(_prefsKey(userId, 'concerns')) ?? const [];
      return Personalization(
        interests: interests.toSet(),
        mode: modeRaw == TrackingMode.pregnancy.name
            ? TrackingMode.pregnancy
            : TrackingMode.cycle,
        symptomAreas: areas.toSet(),
        fertilityPrefs: fertility.toSet(),
        trackingCategories: categories.toSet(),
        healthConcerns: concerns.toSet(),
        tracksElsewhere: prefs.getBool(_prefsKey(userId, 'elsewhere')) ?? false,
        isActuallyPregnant: prefs.getBool(_prefsKey(userId, 'pregnant')),
      );
    } catch (_) {
      return Personalization();
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
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Replace the whole interest set (multi-select UI commits on Continue).
  Future<void> setInterests(Set<String> interests) async {
    final cur = state.value ?? Personalization();
    final clean = interests.where(UserInterests.all.contains).toSet();
    state = AsyncData(cur.copyWith(interests: clean));
    await _save('interests', clean.toList());
  }

  /// Explicit tracking-state change. Pregnancy mode is set ONLY through
  /// this path (explicit actual-pregnancy answer) — never inferred.
  Future<void> setMode(TrackingMode mode) async {
    final cur = state.value ?? Personalization();
    state = AsyncData(cur.copyWith(mode: mode));
    await _save('mode', mode.name);
  }

  Future<void> setSymptomAreas(Set<String> areas) async {
    final cur = state.value ?? Personalization();
    final clean = areas.where(SymptomAreas.all.contains).toSet();
    state = AsyncData(cur.copyWith(symptomAreas: clean));
    await _save('symptom_areas', clean.toList());
  }

  Future<void> setFertilityPrefs(Set<String> prefs) async {
    final cur = state.value ?? Personalization();
    final clean = prefs.where(FertilityPrefs.all.contains).toSet();
    state = AsyncData(cur.copyWith(fertilityPrefs: clean));
    await _save('fertility', clean.toList());
  }

  /// Log categories the user wants to track. Display hints only.
  Future<void> setTrackingCategories(Set<String> categories) async {
    final cur = state.value ?? Personalization();
    final clean = categories.where(TrackingCategories.all.contains).toSet();
    state = AsyncData(cur.copyWith(trackingCategories: clean));
    await _save('categories', clean.toList());
  }

  /// Health concerns for personalization. Stored verbatim as concern
  /// flags — never interpreted as diagnoses, never sent anywhere.
  Future<void> setHealthConcerns(Set<String> concerns) async {
    final cur = state.value ?? Personalization();
    final clean = concerns.where(HealthConcerns.all.contains).toSet();
    state = AsyncData(cur.copyWith(healthConcerns: clean));
    await _save('concerns', clean.toList());
  }

  /// Whether the user already tracks periods elsewhere (migration hint).
  Future<void> setTracksElsewhere(bool value) async {
    final cur = state.value ?? Personalization();
    state = AsyncData(cur.copyWith(tracksElsewhere: value));
    await _save('elsewhere', value);
  }

  Future<void> setIsActuallyPregnant(bool? value) async {
    final cur = state.value ?? Personalization();
    state = AsyncData(
      cur.copyWith(
        isActuallyPregnant: value,
        clearPregnancyAnswer: value == null,
      ),
    );
    await _save('pregnant', value);
  }
}

final personalizationProvider =
    AsyncNotifierProvider<PersonalizationNotifier, Personalization>(
      PersonalizationNotifier.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:menomate_mobile/models/interests.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/onboarding_status_provider.dart';
import 'package:menomate_mobile/providers/personalization_provider.dart';

/// Phase 1 adaptive-onboarding foundation contract.
///
/// Covers the multi-select interest model, conditional follow-up
/// derivation, local-only persistence, pregnancy-mode separation, the
/// onboarding completion gate, and the backend-contract boundary (interests
/// are never part of the onboarding API payload).
void main() {
  group('interest vocabulary', () {
    test('all seven canonical ids exist with labels', () {
      expect(UserInterests.all, hasLength(7));
      expect(
        UserInterests.all.toSet(),
        {
          'cycle_tracking',
          'body_awareness',
          'reproductive_learning',
          'fertility_awareness',
          'trying_to_conceive',
          'pregnancy',
          'wellness',
        },
      );
      for (final id in UserInterests.all) {
        expect(userInterestLabel(id), isNotNull, reason: id);
      }
      expect(kUserInterests, hasLength(7));
    });
  });

  group('multi-select behavior', () {
    test('multiple interests coexist; deselect removes one', () {
      var p = Personalization(
        interests: {
          UserInterests.cycleTracking,
          UserInterests.bodyAwareness,
        },
      );
      expect(p.interests, hasLength(2));

      final removed = Set<String>.from(p.interests)
        ..remove(UserInterests.bodyAwareness);
      p = p.copyWith(interests: removed);
      expect(p.interests, {UserInterests.cycleTracking});
    });

    test('empty means skipped, not "none"', () {
      final p = Personalization();
      expect(p.interests, isEmpty);
      expect(p.wantsSymptomAreas, isFalse);
      expect(p.wantsFertilityPrefs, isFalse);
      expect(p.wantsPregnancyState, isFalse);
    });

    test('unknown/stale keys are filtered, never honored', () {
      final p = Personalization(
        interests: {'cycle_tracking', 'stale_future_key'},
      );
      expect(p.interests, {'cycle_tracking'});
    });
  });

  group('conditional follow-ups', () {
    test('cycle tracking asks no personalization follow-up', () {
      final p = Personalization(
        interests: {UserInterests.cycleTracking},
      );
      expect(p.wantsSymptomAreas, isFalse);
      expect(p.wantsFertilityPrefs, isFalse);
      expect(p.wantsPregnancyState, isFalse);
    });

    test('body awareness gates symptom areas only', () {
      final p = Personalization(
        interests: {UserInterests.bodyAwareness},
      );
      expect(p.wantsSymptomAreas, isTrue);
      expect(p.wantsFertilityPrefs, isFalse);
      expect(p.wantsPregnancyState, isFalse);
    });

    test('fertility awareness or TTC gates fertility prefs', () {
      expect(
        Personalization(
          interests: {UserInterests.fertilityAwareness},
        ).wantsFertilityPrefs,
        isTrue,
      );
      expect(
        Personalization(
          interests: {UserInterests.tryingToConceive},
        ).wantsFertilityPrefs,
        isTrue,
      );
      expect(
        Personalization(
          interests: {UserInterests.wellness},
        ).wantsFertilityPrefs,
        isFalse,
      );
    });

    test('pregnancy interest gates the state question only', () {
      final p = Personalization(
        interests: {UserInterests.pregnancy},
      );
      expect(p.wantsPregnancyState, isTrue);
      expect(p.wantsSymptomAreas, isFalse);
    });

    test('learning/wellness ask no follow-ups (future Learn)', () {
      final p = Personalization(
        interests: {
          UserInterests.reproductiveLearning,
          UserInterests.wellness,
        },
      );
      expect(p.wantsSymptomAreas, isFalse);
      expect(p.wantsFertilityPrefs, isFalse);
      expect(p.wantsPregnancyState, isFalse);
    });
  });

  group('pregnancy-mode separation', () {
    test('interest alone never activates pregnancy mode', () {
      final p = Personalization(
        interests: {UserInterests.pregnancy},
      );
      expect(p.mode, TrackingMode.cycle);
      expect(p.isActuallyPregnant, isNull);
    });

    test('only an explicit answer records pregnancy state', () {
      var p = Personalization(interests: {UserInterests.pregnancy});
      p = p.copyWith(isActuallyPregnant: true);
      expect(p.isActuallyPregnant, isTrue);
      // The mode switch itself stays an explicit act, never implied.
      p = p.copyWith(mode: TrackingMode.pregnancy);
      expect(p.mode, TrackingMode.pregnancy);

      final cleared = p.copyWith(clearPregnancyAnswer: true);
      expect(cleared.isActuallyPregnant, isNull);
    });
  });

  group('personalization persists locally, never via API', () {
    test('round-trips per tracking identity', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue('user-a')],
      );
      addTearDown(container.dispose);

      await container.read(personalizationProvider.future);
      final notifier = container.read(personalizationProvider.notifier);
      await notifier.setInterests({
        UserInterests.cycleTracking,
        UserInterests.bodyAwareness,
      });
      await notifier.setSymptomAreas({SymptomAreas.mood, SymptomAreas.sleep});
      await notifier.setFertilityPrefs({FertilityPrefs.bbt});
      await notifier.setIsActuallyPregnant(false);

      final p = container.read(personalizationProvider).value!;
      expect(p.interests, hasLength(2));
      expect(p.symptomAreas, {SymptomAreas.mood, SymptomAreas.sleep});
      expect(p.fertilityPrefs, {FertilityPrefs.bbt});
      expect(p.isActuallyPregnant, isFalse);
      expect(p.mode, TrackingMode.cycle);
    });

    test('unknown stored keys read back as unset', () async {
      SharedPreferences.setMockInitialValues({
        'menomate.personalization.interests.user-a': ['migrated_key'],
      });
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue('user-a')],
      );
      addTearDown(container.dispose);
      final p = await container.read(personalizationProvider.future);
      expect(p.interests, isEmpty);
    });
  });

  group('onboarding completion gate (navigation decisions)', () {
    test('new user without name or flag needs onboarding', () {
      expect(isProfileOnboarded(null, false), isFalse);
      expect(
        isProfileOnboarded(Profile(userId: 'u', name: '  '), false),
        isFalse,
      );
    });

    test('named profile counts as onboarded (existing account)', () {
      expect(
        isProfileOnboarded(Profile(userId: 'u', name: 'Ama'), false),
        isTrue,
      );
    });

    test('explicit flag covers transient empty-name payloads', () {
      expect(
        isProfileOnboarded(Profile(userId: 'u', name: ''), true),
        isTrue,
      );
      expect(isProfileOnboarded(null, true), isTrue);
    });
  });
}

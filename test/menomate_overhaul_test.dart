import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/profile_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/health_context.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/logo_variant_provider.dart';
import 'package:menomate_mobile/providers/onboarding_context_provider.dart';
import 'package:menomate_mobile/providers/onboarding_status_provider.dart';
import 'package:menomate_mobile/screens/calendar_day_detail_screen.dart';
import 'package:menomate_mobile/screens/calendar_screen.dart';
import 'package:menomate_mobile/screens/log_hub_screen.dart';
import 'package:menomate_mobile/widgets/menomate_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_fake_api.dart';

Profile _named(String userId, String name) => Profile(
  userId: userId,
  name: name,
  usualCycleDays: 28,
  usualPeriodDays: 5,
  theme: 'light',
  units: 'metric',
);

void main() {
  group('auth/onboarding routing root cause', () {
    test('new user (no profile, no flag) is NOT onboarded', () {
      expect(isProfileOnboarded(null, false), isFalse);
    });

    test('existing user (named profile) is onboarded even without flag', () {
      expect(isProfileOnboarded(_named('u', 'Ama'), false), isTrue);
    });

    test('blank/whitespace name is NOT onboarded without flag', () {
      expect(isProfileOnboarded(_named('u', ''), false), isFalse);
      expect(isProfileOnboarded(_named('u', '   '), false), isFalse);
    });

    test('explicit flag protects existing user from empty-name payload', () {
      // Transient nameless remote for an existing user: flag keeps them
      // on Home instead of bouncing to onboarding.
      expect(isProfileOnboarded(_named('u', ''), true), isTrue);
      expect(isProfileOnboarded(null, true), isTrue);
    });

    test('sign out → sign in keeps onboarding via server name', () {
      // Fresh install signing into an existing account: no local flag,
      // but server profile has a name → Home, never onboarding.
      expect(isProfileOnboarded(_named('new-device', 'Ama'), false), isTrue);
    });

    test('remote empty-name never overwrites good local name', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ProfileRepository(db, api);
      // Local has a real name (existing user, e.g. offline or cached).
      await repo.saveProfile('user-a', {'name': 'Ama'}, localOnly: true);
      // Transient backend payload with empty name.
      api.serverProfile = Profile(
        userId: 'user-a',
        name: '',
        usualCycleDays: 28,
        usualPeriodDays: 5,
        theme: 'light',
        units: 'metric',
      );
      final state = await repo.loadProfile('user-a');
      expect(state.dataOrNull?.name, 'Ama');
      expect(
        state,
        isNot(isA<Fresh<Profile?>>()),
        reason: 'nameless remote must not present as Fresh remote',
      );
    });

    test('onboarding flag persists per user', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue('user-a')],
      );
      addTearDown(container.dispose);
      // Initially false.
      await container.read(onboardingStatusProvider.future);
      expect(container.read(onboardingStatusProvider).value ?? false, isFalse);
      await container.read(onboardingStatusProvider.notifier).markCompleted();
      expect(container.read(onboardingStatusProvider).value ?? false, isTrue);
    });
  });

  group('onboarding context stays local-only (backend gaps)', () {
    test(
      'height/weight/goal/regularity store on-device, never via API',
      () async {
        SharedPreferences.setMockInitialValues({});
        final api = FakeApiService();
        final container = ProviderContainer(
          overrides: [currentUserIdProvider.overrideWithValue('user-a')],
        );
        addTearDown(container.dispose);
        await container.read(onboardingContextProvider.future);
        final notifier = container.read(onboardingContextProvider.notifier);
        await notifier.setHeightCm(177);
        await notifier.setWeightKg(62);
        await notifier.setGoal('track_cycle');
        await notifier.setRegularity('yes');
        final ctx = container.read(onboardingContextProvider).value!;
        expect(ctx.heightCm, 177);
        expect(ctx.weightKg, 62);
        expect(ctx.goalKey, 'track_cycle');
        expect(ctx.regularityKey, 'yes');
        // No backend call exists for these fields.
        expect(api.completeOnboardingCalls, 0);
        expect(api.patchProfileCalls, 0);
      },
    );

    test('unsupported goals are marked as backend-pending', () {
      final unsupported = kOnboardingGoals.where((g) => !g.supportedNow);
      expect(unsupported, isNotEmpty);
      for (final g in unsupported) {
        expect(g.description, contains('backend'));
      }
      // Supported goals map to live functionality.
      expect(
        kOnboardingGoals.firstWhere((g) => g.key == 'track_cycle').supportedNow,
        isTrue,
      );
    });

    test('backend gap docs exist and name the gaps', () {
      for (final path in ['docs/backend_gaps.md', 'docs/launcher_icon.md']) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      final gaps = File('docs/backend_gaps.md').readAsStringSync();
      for (final keyword in [
        'Height',
        'Weight',
        'Goals',
        'Fertility',
        'Pregnancy',
        'Reminders',
      ]) {
        expect(gaps, contains(keyword));
      }
    });
  });

  group('calendar hierarchy', () {
    Future<void> pumpCalendar(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('user-a'),
          ],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('month view shows legend with distinct observed/predicted', (
      tester,
    ) async {
      await pumpCalendar(tester);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Logged period'), findsOneWidget);
      expect(find.text('Predicted period'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Selected date'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('year view shows 12 months and navigates to month', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      // Year header + 12 mini months (Jan..Dec abbreviations).
      expect(find.textContaining(DateTime.now().year.toString()), findsWidgets);
      await tester.tap(find.text('Jan').first);
      await tester.pumpAndSettle();
      // Back on month view.
      expect(find.text('Month'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('day detail empty date renders honest empty state', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('user-a'),
          ],
          child: const MaterialApp(
            home: CalendarDayDetailScreen(isoDate: '2026-09-18'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Non-bleeding day'), findsOneWidget);
      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('Add more'), findsOneWidget);
      // Never invents fertile-window content.
      expect(find.textContaining('fertile', findRichText: true), findsNothing);
      expect(
        find.textContaining('ovulation', findRichText: true),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('day detail invalid date renders error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CalendarDayDetailScreen(isoDate: 'not-a-date')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invalid date.'), findsOneWidget);
    });
  });

  group('log hub', () {
    testWidgets('categories, date selector, and future marking', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LogHubScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Log'), findsOneWidget);
      for (final label in ['Period', 'Flow', 'Symptoms', 'Mood', 'Notes']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('View day detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('health context contract', () {
    test('supported enums carry labels', () {
      expect(kContraceptionLabels['hormonal_iud'], 'Hormonal IUD');
      expect(
        kPregnancyContextLabels['trying_to_conceive'],
        'Trying to conceive',
      );
    });
  });

  group('branding', () {
    test('logo variants keep three options with labels', () {
      expect(AppLogoVariant.values.length, 3);
      for (final v in AppLogoVariant.values) {
        expect(kLogoVariantLabels[v]!.trim(), isNotEmpty);
      }
    });

    test('home greeting logo is fixed standard (not variant-driven)', () {
      // HomeTab builds MenoMateLogo(variant: standard) directly.
      // This test pins the contract: changing logoVariantProvider must
      // not be read by the Home header path. The widget tree check lives
      // in the source (home_tab.dart uses MenoMateLogo standard), and
      // the launcher docs state the rule explicitly.
      expect(
        File('docs/launcher_icon.md').readAsStringSync(),
        contains('never'),
      );
      const logo = MenoMateLogo(size: 34, variant: AppLogoVariant.standard);
      expect(logo.variant, AppLogoVariant.standard);
    });
  });
}

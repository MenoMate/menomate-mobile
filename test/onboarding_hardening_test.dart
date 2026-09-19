import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/repositories/profile_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/onboarding.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/onboarding_screen.dart';
import 'package:menomate_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_fake_api.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  group('name validation (§4.1–4.2)', () {
    test('blank name is rejected', () {
      final errors = validateOnboardingInput(
        name: '',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 3))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors['name'], isNotNull);
    });

    test('whitespace-only name is rejected', () {
      final errors = validateOnboardingInput(
        name: '   ',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 3))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors['name'], isNotNull);
    });

    test('non-blank name passes', () {
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 3))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors, isEmpty);
    });
  });

  group('date validation (§4.3–4.5, §4.8)', () {
    test('future start is prevented', () {
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(DateTime.now().add(const Duration(days: 1))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors['start'], isNotNull);
    });

    test('future end is prevented', () {
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 3))),
        status: PeriodStatus.ended,
        periodEnd: _day(DateTime.now().add(const Duration(days: 1))),
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors['end'], isNotNull);
    });

    test('end before start is prevented', () {
      final now = DateTime.now();
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(now.subtract(const Duration(days: 2))),
        status: PeriodStatus.ended,
        periodEnd: _day(now.subtract(const Duration(days: 5))),
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: now,
      );
      expect(errors['end'], isNotNull);
    });

    test('Ended requires an end date', () {
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 5))),
        status: PeriodStatus.ended,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors['end'], isNotNull);
    });

    test('valid completed and ongoing inputs pass', () {
      final now = DateTime.now();
      final completed = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(now.subtract(const Duration(days: 6))),
        status: PeriodStatus.ended,
        periodEnd: _day(now.subtract(const Duration(days: 2))),
        usualCycle: const ParsedUsualDays.valid(28),
        usualPeriod: const ParsedUsualDays.valid(5),
        today: now,
      );
      expect(completed, isEmpty);

      final ongoing = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(now.subtract(const Duration(days: 2))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: now,
      );
      expect(ongoing, isEmpty);
    });
  });

  group('period status (§4.6–4.7)', () {
    test('Ongoing resolves to null end', () {
      expect(resolvePeriodEndIso(PeriodStatus.ongoing, '2026-09-01'), isNull);
      expect(resolvePeriodEndIso(PeriodStatus.ongoing, null), isNull);
    });

    test('Ended keeps the chosen end date', () {
      expect(
        resolvePeriodEndIso(PeriodStatus.ended, '2026-09-01'),
        '2026-09-01',
      );
    });

    test('Ongoing never requires an end date', () {
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 2))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: const ParsedUsualDays.unset(),
        usualPeriod: const ParsedUsualDays.unset(),
        today: DateTime.now(),
      );
      expect(errors.containsKey('end'), isFalse);
    });
  });

  group('numeric semantics (§4.9–4.12)', () {
    test('valid integers parse', () {
      expect(parseUsualCycleDays('28').isValid, isTrue);
      expect(parseUsualCycleDays('28').value, 28);
      expect(parseUsualPeriodDays('5').isValid, isTrue);
      expect(parseUsualPeriodDays('12').isValid, isTrue);
    });

    test('whitespace-wrapped integers parse', () {
      expect(parseUsualCycleDays(' 28 ').isValid, isTrue);
      expect(parseUsualCycleDays(' 28 ').value, 28);
    });

    test('malformed input is an error, never silent null', () {
      for (final bad in ['28 days', '28.5', 'abc', '-', '28d', '2 8']) {
        expect(parseUsualCycleDays(bad).isInvalid, isTrue, reason: bad);
        expect(parseUsualPeriodDays(bad).isInvalid, isTrue, reason: bad);
      }
      // Out of backend range is also invalid, not unset.
      expect(parseUsualCycleDays('19').isInvalid, isTrue);
      expect(parseUsualCycleDays('46').isInvalid, isTrue);
      expect(parseUsualPeriodDays('0').isInvalid, isTrue);
      expect(parseUsualPeriodDays('13').isInvalid, isTrue);
    });

    test('skipped fields stay unset (not sure)', () {
      expect(parseUsualCycleDays('').isUnset, isTrue);
      expect(parseUsualCycleDays('   ').isUnset, isTrue);
      expect(parseUsualPeriodDays('').isUnset, isTrue);
    });

    test('invalid numerics fail validation with guidance', () {
      final errors = validateOnboardingInput(
        name: 'Maya',
        periodStart: _day(DateTime.now().subtract(const Duration(days: 3))),
        status: PeriodStatus.ongoing,
        periodEnd: null,
        usualCycle: parseUsualCycleDays('28 days'),
        usualPeriod: parseUsualPeriodDays('abc'),
        today: DateTime.now(),
      );
      expect(errors['cycle'], contains('not sure'));
      expect(errors['period'], contains('not sure'));
    });
  });

  group('error typing (§4.15–4.16)', () {
    test('HTTP 422 maps to ValidationError', () {
      final err = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/onboarding/complete'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/onboarding/complete'),
            statusCode: 422,
            data: {'detail': 'name must not be blank'},
          ),
        ),
      );
      expect(err, isA<ValidationError>());
      expect(err.message, contains('name must not be blank'));
    });

    test('HTTP 409 maps to Conflict', () {
      final err = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/onboarding/complete'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/onboarding/complete'),
            statusCode: 409,
            data: {'detail': 'already been completed'},
          ),
        ),
      );
      expect(err, isA<Conflict>());
    });

    test('offline completeOnboarding throws NetworkUnavailable', () async {
      final api = FakeApiService()..offline = true;
      await expectLater(
        api.completeOnboarding(
          OnboardingRequest(name: 'Maya', lastPeriodStart: '2026-09-01'),
        ),
        throwsA(isA<NetworkUnavailable>()),
      );
    });

    test('ValidationError classifies as conflict (no blind retry)', () {
      expect(
        classifySyncError(const ValidationError('bad')),
        SyncOutcome.conflict,
      );
    });
  });

  group('local-first persistence (§4.13–4.14)', () {
    test(
      'successful onboarding persists profile + first cycle as synced',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final api = FakeApiService();
        final profileRepo = ProfileRepository(db, api);
        final cycleRepo = CycleRepository(db, api);

        final result = await api.completeOnboarding(
          OnboardingRequest(
            name: 'Maya',
            lastPeriodStart: '2026-09-01',
            lastPeriodEnd: '2026-09-05',
            usualCycleDays: 28,
            usualPeriodDays: 5,
          ),
        );
        await profileRepo.storeOnboardedProfile(result.profile);
        await cycleRepo.storeOnboardedCycle(
          'user-a',
          serverId: result.periodId,
          periodStart: result.periodStart,
          periodEnd: result.periodEnd,
        );

        final profileRow = await (db.select(
          db.localProfiles,
        )..where((t) => t.userId.equals('user-a'))).getSingle();
        expect(profileRow.name, 'Maya');
        expect(profileRow.syncState, SyncState.synced);

        final cycleRows = await (db.select(
          db.localCycles,
        )..where((t) => t.userId.equals('user-a'))).get();
        expect(cycleRows, hasLength(1));
        expect(cycleRows.single.periodStart, '2026-09-01');
        expect(cycleRows.single.periodEnd, '2026-09-05');
        expect(cycleRows.single.syncState, SyncState.synced);
      },
    );

    test(
      'profile + first cycle survive offline (new repo instances)',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final api = FakeApiService();
        final profileRepo = ProfileRepository(db, api);
        final cycleRepo = CycleRepository(db, api);

        final result = await api.completeOnboarding(
          OnboardingRequest(name: 'Maya', lastPeriodStart: '2026-09-01'),
        );
        await profileRepo.storeOnboardedProfile(result.profile);
        await cycleRepo.storeOnboardedCycle(
          'user-a',
          serverId: result.periodId,
          periodStart: result.periodStart,
          periodEnd: result.periodEnd,
        );

        // "Restart": fresh repository instances over the same database,
        // backend now unreachable.
        api.offline = true;
        final freshProfileRepo = ProfileRepository(db, api);
        final freshCycleRepo = CycleRepository(db, api);

        final profileState = await freshProfileRepo.loadProfile('user-a');
        expect(profileState.dataOrNull?.name, 'Maya');
        expect(profileState, isNot(isA<Unavailable<Profile?>>()));

        final cyclesState = await freshCycleRepo.loadCycles('user-a');
        expect(cyclesState.dataOrNull, hasLength(1));
        expect(cyclesState, isNot(isA<Unavailable<List<dynamic>>>()));
      },
    );

    test('storing the same onboarded cycle twice never duplicates', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final cycleRepo = CycleRepository(db, api);

      await cycleRepo.storeOnboardedCycle(
        'user-a',
        serverId: 100,
        periodStart: '2026-09-01',
        periodEnd: null,
      );
      await cycleRepo.storeOnboardedCycle(
        'user-a',
        serverId: 100,
        periodStart: '2026-09-01',
        periodEnd: null,
      );

      final rows = await db.select(db.localCycles).get();
      expect(rows, hasLength(1));
    });
  });

  group('onboarding wizard (one-question-per-screen)', () {
    Future<void> pumpOnboarding(
      WidgetTester tester, {
      required FakeApiService api,
      required AppDatabase db,
      required _RecordingProfileNotifier profileNotifier,
      Size? viewport,
    }) async {
      // Wizard is paged: a normal phone viewport suffices. The narrow
      // test below overrides this.
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = viewport ?? const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(api),
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('user-a'),
            profileProvider.overrideWith(() => profileNotifier),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapContinue(WidgetTester tester) async {
      await tester.tap(find.text('Continue').last);
      await tester.pumpAndSettle();
    }

    /// Tap Skip when present else Continue, until [target] appears
    /// (max 15 steps). Robust against step-index drift.
    Future<void> advanceTo(WidgetTester tester, String target) async {
      for (var i = 0; i < 15; i++) {
        if (find.text(target).evaluate().isNotEmpty) return;
        final skip = find.text('Skip');
        if (skip.evaluate().isNotEmpty) {
          await tester.tap(skip.first);
        } else {
          final cont = find.text('Continue');
          if (cont.evaluate().isEmpty) return;
          await tester.tap(cont.last);
        }
        await tester.pumpAndSettle();
      }
    }

    Future<void> tapLetsGetStarted(WidgetTester tester) async {
      await tester.tap(find.text('Let\u2019s get started'));
      await tester.pumpAndSettle();
    }

    /// Advance from welcome to the name step.
    Future<void> goToName(WidgetTester tester) async {
      expect(find.text('Welcome to MenoMate'), findsOneWidget);
      await tapLetsGetStarted(tester);
      expect(find.text('What should we call you?'), findsWidgets);
    }

    testWidgets('blank name shows inline error and never calls the API', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      await goToName(tester);
      // Continue with empty name blocks on the name step.
      await tapContinue(tester);

      expect(find.text('Please enter your name.'), findsOneWidget);
      expect(api.completeOnboardingCalls, 0);
    });

    testWidgets('Ended without end date blocks; Ongoing submits cleanly', (
      tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('menomate/timezone'),
            (call) async => 'Asia/Kolkata',
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('menomate/timezone'),
              null,
            ),
      );
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      final profileNotifier = _RecordingProfileNotifier();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: profileNotifier,
      );

      // Welcome -> name.
      await goToName(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Widget User',
      );
      await tapContinue(tester); // -> age
      await advanceTo(tester, 'When did your last period start?');
      // Now on last-period start step.
      expect(find.text('When did your last period start?'), findsOneWidget);
      await tester.tap(
        find.text('I don\u2019t remember — use today (approximate)'),
      );
      await tester.pumpAndSettle();
      await tapContinue(tester); // -> status step

      expect(find.text('Has your last period ended?'), findsOneWidget);
      // Default Ended with no end date -> inline error, no API call.
      await tapContinue(tester);
      expect(
        find.text('Please choose when it ended, or select Ongoing.'),
        findsOneWidget,
      );
      expect(api.completeOnboardingCalls, 0);

      // Switch to Ongoing and continue -> proceeds past validation.
      await tester.tap(find.text('Ongoing'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please choose when it ended, or select Ongoing.'),
        findsNothing,
      );
      await tapContinue(tester); // -> reproductive
      // Skip reproductive + birth (birth Skip triggers submit).
      var skip = find.text('Skip');
      expect(skip, findsOneWidget);
      await tester.tap(skip.first); // skip reproductive
      await tester.pumpAndSettle();
      skip = find.text('Skip');
      // Birth step: Skip submits (last content step).
      await tester.tap(skip.first);
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((await db.select(db.localCycles).get()).isNotEmpty) break;
      }

      expect(api.completeOnboardingCalls, 1);
      // Device zone rode along atomically with onboarding.
      expect(api.lastOnboardingRequest?.timezone, 'Asia/Kolkata');
      expect(profileNotifier.lastSet?.name, 'Widget User');
      final profileRow = await (db.select(
        db.localProfiles,
      )..where((t) => t.userId.equals('user-a'))).getSingle();
      expect(profileRow.name, 'Widget User');
      final cycleRows = await db.select(db.localCycles).get();
      expect(cycleRows, hasLength(1));
      // No error snackbar and no navigation away (§4.18).
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('cycle and period default to Not sure and advance cleanly', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      await goToName(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Maya',
      );
      await tapContinue(tester);
      await advanceTo(tester, 'Usual cycle length?');
      expect(find.text('Usual cycle length?'), findsOneWidget);
      // Default is Not sure — Continue advances with no API call yet.
      await tapContinue(tester);
      expect(find.text('Usual period length?'), findsOneWidget);
      await tapContinue(tester);
      expect(find.text('When did your last period start?'), findsOneWidget);
      expect(api.completeOnboardingCalls, 0);
    });

    testWidgets('wizard is one-question-per-screen with no legacy form', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      // Progress + single-question structure.
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(find.text('Welcome to MenoMate'), findsOneWidget);
      // Old scrolling form is gone.
      expect(find.text('To get started'), findsNothing);
      expect(find.text('Nice to have — optional'), findsNothing);
      // No temperature question anywhere (no temp input, no degree unit).
      expect(find.textContaining('emperature?'), findsNothing);
      expect(find.textContaining('°C'), findsNothing);
      expect(find.textContaining('°F'), findsNothing);
      // Optional age step offers Skip.
      await tapLetsGetStarted(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Maya',
      );
      await tapContinue(tester);
      expect(find.text('What\u2019s your age range?'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    Future<void> completeToBirth(
      WidgetTester tester, {
      String name = 'Widget User',
      bool ongoing = true,
    }) async {
      await goToName(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        name,
      );
      await tapContinue(tester);
      for (var i = 0; i < 7; i++) {
        final skip = find.text('Skip');
        if (skip.evaluate().isNotEmpty) {
          await tester.tap(skip.first);
        } else {
          await tapContinue(tester);
          continue;
        }
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.text('I don\u2019t remember — use today (approximate)'),
      );
      await tester.pumpAndSettle();
      await tapContinue(tester);
      if (ongoing) {
        await tester.tap(find.text('Ongoing'));
        await tester.pumpAndSettle();
      }
      await tapContinue(tester); // -> reproductive
      final skip = find.text('Skip');
      await tester.tap(skip.first);
      await tester.pumpAndSettle();
      expect(find.text('Birth month & year?'), findsOneWidget);
    }

    testWidgets('optional DOB left blank submits without complaint', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      await completeToBirth(tester);
      // Skip birth (blank pair) submits.
      await tester.tap(find.text('Skip').first);
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((await db.select(db.localCycles).get()).isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 500));

      expect(api.completeOnboardingCalls, 1);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('You\u2019re all set!'), findsOneWidget);
    });

    testWidgets('DOB month without year blocks with guidance', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      await completeToBirth(tester);
      // Open month dropdown and pick May, leave year blank.
      await tester.tap(find.byType(DropdownButtonFormField<int?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('May').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete onboarding'));
      await tester.pumpAndSettle();

      expect(find.textContaining('both birth month and year'), findsOneWidget);
      expect(api.completeOnboardingCalls, 0);
    });

    testWidgets('DOB persists through onboarding submit', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      await completeToBirth(tester);
      await tester.tap(find.byType(DropdownButtonFormField<int?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('May').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Year'), '1992');
      await tester.tap(find.text('Complete onboarding'));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((await db.select(db.localCycles).get()).isNotEmpty) break;
      }

      expect(api.completeOnboardingCalls, 1);
      expect(api.serverProfile.birthYear, 1992);
      expect(api.serverProfile.birthMonth, 5);
    });

    testWidgets('narrow dark theme renders without overflow; CTA reachable', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(api),
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('user-a'),
            profileProvider.overrideWith(() => _RecordingProfileNotifier()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Wizard CTA stays reachable on a short screen.
      expect(find.text('Let\u2019s get started'), findsOneWidget);
      await tester.tap(find.text('Let\u2019s get started'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('What should we call you?'), findsWidgets);
    });
  });
}

class _RecordingProfileNotifier extends ProfileNotifier {
  Profile? lastSet;

  @override
  Future<DataState<Profile?>> build() async => const NoData<Profile?>();

  @override
  void setProfile(Profile profile) {
    lastSet = profile;
    super.setProfile(profile);
  }
}

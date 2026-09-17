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

  group('onboarding screen (§4.17–4.18 + Part B)', () {
    Future<void> pumpOnboarding(
      WidgetTester tester, {
      required FakeApiService api,
      required AppDatabase db,
      required _RecordingProfileNotifier profileNotifier,
      Size? viewport,
    }) async {
      // Tall viewport by default (repo convention): the full form fits
      // without scrolling. The narrow test below overrides this.
      tester.view.physicalSize = viewport ?? const Size(800, 2000);
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

      await tester.tap(find.text('Complete onboarding'));
      await tester.pumpAndSettle();

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

      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Widget User',
      );
      // Pick a start date via the picker dialog (accepts initial = today).
      await tester.tap(find.text('Select start date'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // The picker must have committed a start date.
      expect(find.text('Select start date'), findsNothing);

      // Default status is Ended with no end date -> inline error, no call.
      await tester.tap(find.text('Complete onboarding'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please choose when it ended, or select Ongoing.'),
        findsOneWidget,
      );
      expect(api.completeOnboardingCalls, 0);

      // Switch to Ongoing and submit -> success, persisted, provider set.
      await tester.tap(find.text('Ongoing'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please choose when it ended, or select Ongoing.'),
        findsNothing,
      );
      await tester.tap(find.text('Complete onboarding'));
      // Explicit pumps (not pumpAndSettle): the loading spinner animates
      // while the fake API future resolves. Poll until the local cycle
      // row lands (Drift background isolate), bounded.
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((await db.select(db.localCycles).get()).isNotEmpty) break;
      }

      expect(api.completeOnboardingCalls, 1);
      // Device zone rode along atomically with onboarding (§2.2 wiring).
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

    testWidgets('malformed numerics show guidance, blank stays not-sure', (
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

      // The "leave blank" helper copy is always visible pre-submit (§8).
      expect(
        find.text('Days between periods. Leave blank if you\u2019re not sure.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Usual cycle length'),
        '28 days',
      );
      await tester.tap(find.text('Complete onboarding'));
      await tester.pumpAndSettle();

      // Malformed input surfaces guidance instead of submitting.
      expect(find.textContaining('eave blank'), findsWidgets);
      expect(api.completeOnboardingCalls, 0);
    });

    testWidgets('required vs optional groups are labeled', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpOnboarding(
        tester,
        api: api,
        db: db,
        profileNotifier: _RecordingProfileNotifier(),
      );

      expect(find.text('To get started'), findsOneWidget);
      expect(find.text('Nice to have — optional'), findsOneWidget);
      expect(
        find.textContaining('the rest is optional and can wait'),
        findsOneWidget,
      );
      expect(find.text('Birth month & year (optional)'), findsOneWidget);
    });

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

      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Widget User',
      );
      await tester.tap(find.text('Select start date'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ongoing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete onboarding'));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((await db.select(db.localCycles).get()).isNotEmpty) break;
      }

      expect(api.completeOnboardingCalls, 1);
      expect(find.byType(SnackBar), findsNothing);
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

      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Widget User',
      );
      // Month dropdown is the only DropdownButton on the screen.
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('May').last);
      await tester.pump();
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

      await tester.enterText(
        find.widgetWithText(TextField, 'What should we call you?'),
        'Widget User',
      );
      await tester.tap(find.text('Select start date'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ongoing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('May').last);
      await tester.pump();
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
      // The CTA is below the fold on a short screen but must stay
      // reachable via scroll (no clipping, no overflow).
      await tester.ensureVisible(find.text('Complete onboarding'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Complete onboarding'), findsOneWidget);
      expect(find.text('Has your last period ended?'), findsOneWidget);
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

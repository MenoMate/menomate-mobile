import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:menomate_mobile/core/router.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/repositories/daily_log_repository.dart';
import 'package:menomate_mobile/data/repositories/profile_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/daily_log.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/auth_provider.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/offline_mode_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/tabs/assistant_tab.dart';
import 'package:menomate_mobile/screens/tabs/settings_tab.dart';
import 'package:menomate_mobile/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_fake_api.dart';

const _authId = 'auth-user-1';

AppDatabase _memoryDb() => AppDatabase.memory();

class _FakeOffline extends OfflineModeNotifier {
  final bool flag;
  _FakeOffline(this.flag);

  @override
  Future<bool> build() async => flag;
}

class _FixedProfileNotifier extends ProfileNotifier {
  final DataState<Profile?> fixed;
  _FixedProfileNotifier(this.fixed);

  @override
  Future<DataState<Profile?>> build() async => fixed;
}

Profile _profile(String userId, {String? name = 'Ama'}) => Profile(
  userId: userId,
  name: name,
  usualCycleDays: 28,
  usualPeriodDays: 5,
  theme: 'light',
  units: 'metric',
  timezone: 'Asia/Kolkata',
);

Future<void> _seedOfflineRows(AppDatabase db) async {
  await db
      .into(db.localProfiles)
      .insert(
        LocalProfilesCompanion.insert(
          userId: kOfflineUserId,
          name: const Value('Offline Ama'),
          usualCycleDays: const Value(30),
          theme: const Value('dark'),
          syncState: const Value(SyncState.pending),
        ),
      );
  await db
      .into(db.localCycles)
      .insert(
        LocalCyclesCompanion.insert(
          localId: 'off-1',
          userId: kOfflineUserId,
          periodStart: '2026-06-01',
          periodEnd: const Value('2026-06-05'),
          syncState: const Value(SyncState.pending),
        ),
      );
  await db
      .into(db.localCycles)
      .insert(
        LocalCyclesCompanion.insert(
          localId: 'off-2',
          userId: kOfflineUserId,
          periodStart: '2026-07-02',
          syncState: const Value(SyncState.pending),
        ),
      );
  await db
      .into(db.localDailyLogs)
      .insert(
        LocalDailyLogsCompanion.insert(
          userId: kOfflineUserId,
          logDate: '2026-07-03',
          pain: const Value(4),
          syncState: const Value(SyncState.pending),
        ),
      );
  await db
      .into(db.localSymptoms)
      .insert(
        LocalSymptomsCompanion.insert(
          userId: kOfflineUserId,
          logDate: '2026-07-03',
          symptomType: 'cramps',
          severity: const Value(3),
        ),
      );
}

void main() {
  group('offline mode flag persists across restarts', () {
    test('enable survives provider rebuild via stored prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ProviderContainer();
      addTearDown(first.dispose);
      expect(await first.read(offlineModeProvider.future), isFalse);

      await first.read(offlineModeProvider.notifier).enable();
      expect(await first.read(offlineModeProvider.future), isTrue);

      // A fresh container (simulated restart) reads the stored choice.
      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(await second.read(offlineModeProvider.future), isTrue);

      await second.read(offlineModeProvider.notifier).disable();
      expect(await second.read(offlineModeProvider.future), isFalse);
    });
  });

  group('tracking identity', () {
    test('undecided user has no tracking id', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          offlineModeProvider.overrideWith(() => _FakeOffline(false)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(offlineModeProvider.future);
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(isOfflineTrackingProvider), isFalse);
    });

    test('offline user tracks under the stable local id', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          offlineModeProvider.overrideWith(() => _FakeOffline(true)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(offlineModeProvider.future);
      expect(container.read(currentUserIdProvider), kOfflineUserId);
      expect(container.read(isOfflineTrackingProvider), isTrue);
      // The local id is visibly not account-shaped (never UUID-like).
      expect(RegExp(r'^[0-9a-f]{8}-').hasMatch(kOfflineUserId), isFalse);
    });
  });

  group('offline onboarding stores local-only rows', () {
    test('profile + first period round-trip without any network', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final profiles = ProfileRepository(db, api);
      final cycles = CycleRepository(db, api);

      final saved = await profiles.saveProfile(kOfflineUserId, {
        'name': 'Offline Ama',
        'usual_cycle_days': 30,
        'usual_period_days': null,
        'theme': 'light',
        'units': 'metric',
        'timezone': 'Asia/Kolkata',
      }, localOnly: true);
      expect(saved, isA<PendingSync<Profile>>());
      await cycles.storeLocalCycle(
        kOfflineUserId,
        periodStart: '2026-08-01',
        periodEnd: '2026-08-05',
      );

      // Fresh repository instances (simulated restart) still serve them.
      final profiles2 = ProfileRepository(db, api);
      final cycles2 = CycleRepository(db, api);
      final loaded = await profiles2.loadProfileLocal(kOfflineUserId);
      expect(loaded, isA<PendingSync<Profile?>>());
      expect(loaded.dataOrNull!.name, 'Offline Ama');
      expect(loaded.dataOrNull!.usualCycleDays, 30);
      expect(loaded.dataOrNull!.timezone, 'Asia/Kolkata');
      final current = await cycles2.loadCurrentLocal(kOfflineUserId);
      expect(current, isA<PendingSync<CurrentCycleResponse?>>());
      expect(current.dataOrNull!.latestPeriodStart, DateTime(2026, 8, 1));

      // Nothing was ever sent anywhere: the fake backend stayed empty.
      expect(api.patchProfileCalls, 0);
      expect(api.createCycleCalls, 0);
    });

    test('daily log round-trips locally with symptoms', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final logs = DailyLogRepository(db, api);

      expect(
        await logs.loadLogLocal(kOfflineUserId, '2026-08-10'),
        isA<NoData<DailyLogResponse?>>(),
      );
      final saved = await logs.saveLog(
        kOfflineUserId,
        DailyLogCreate(
          logDate: '2026-08-10',
          pain: 2,
          symptoms: const [SymptomItem(symptomType: 'cramps', severity: 3)],
        ),
        localOnly: true,
      );
      expect(saved, isA<PendingSync<DailyLogResponse>>());
      final reloaded = await logs.loadLogLocal(kOfflineUserId, '2026-08-10');
      expect(reloaded.dataOrNull!.pain, 2);
      expect(reloaded.dataOrNull!.symptoms.single.symptomType, 'cramps');
      expect(api.upsertLogCalls, 0);
    });
  });

  group('offline to account adoption', () {
    test(
      'adopt moves rows, preserves dates, second adopt is a no-op',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        await _seedOfflineRows(db);
        // An authenticated row must never be touched by adoption.
        await db
            .into(db.localCycles)
            .insert(
              LocalCyclesCompanion.insert(
                localId: 'auth-1',
                userId: _authId,
                periodStart: '2026-05-01',
                periodEnd: const Value('2026-05-04'),
                syncState: const Value(SyncState.synced),
              ),
            );

        expect(await db.offlineAdoptableCounts(), (
          cycles: 2,
          logs: 1,
          conditions: 0,
          medications: 0,
          healthContext: false,
        ));

        final moved = await db.adoptOfflineData(_authId);
        expect(moved, (
          cycles: 2,
          logs: 1,
          conditions: 0,
          medications: 0,
          healthContext: false,
        ));

        final cycles = await (db.select(
          db.localCycles,
        )..where((t) => t.userId.equals(_authId))).get();
        expect(cycles.length, 3);
        final movedStarts = cycles.map((c) => c.periodStart).toSet();
        expect(
          movedStarts,
          containsAll(['2026-05-01', '2026-06-01', '2026-07-02']),
        );
        final june = cycles.firstWhere((c) => c.periodStart == '2026-06-01');
        expect(june.periodEnd, '2026-06-05');
        expect(june.syncState, SyncState.pending);
        expect(june.serverId, isNull);
        final symptoms = await (db.select(
          db.localSymptoms,
        )..where((t) => t.userId.equals(_authId))).get();
        expect(symptoms.length, 1);
        expect(symptoms.single.symptomType, 'cramps');
        // Offline identity rows are gone; nothing is stranded or double-owned.
        expect(
          await (db.select(
            db.localCycles,
          )..where((t) => t.userId.equals(kOfflineUserId))).get(),
          isEmpty,
        );
        expect(
          await (db.select(
            db.localProfiles,
          )..where((t) => t.userId.equals(kOfflineUserId))).get(),
          isEmpty,
        );

        expect(await db.adoptOfflineData(_authId), (
          cycles: 0,
          logs: 0,
          conditions: 0,
          medications: 0,
          healthContext: false,
        ));
        expect(await db.offlineAdoptableCounts(), (
          cycles: 0,
          logs: 0,
          conditions: 0,
          medications: 0,
          healthContext: false,
        ));
      },
    );

    test('adopted rows push through normal sync without duplicates', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await _seedOfflineRows(db);
      final api = FakeApiService();
      await db.adoptOfflineData(_authId);

      await CycleRepository(db, api).syncPending(_authId);
      await DailyLogRepository(db, api).syncPending(_authId);

      expect(api.serverCycles.length, 2);
      expect(api.serverLogs['2026-07-03']!.pain, 4);
      // Repeat sync converges: no duplicate server records.
      await CycleRepository(db, api).syncPending(_authId);
      await DailyLogRepository(db, api).syncPending(_authId);
      expect(api.serverCycles.length, 2);
      // Local rows reconciled with server identities.
      final rows = await (db.select(
        db.localCycles,
      )..where((t) => t.userId.equals(_authId))).get();
      expect(rows.every((r) => r.serverId != null), isTrue);
      expect(rows.every((r) => r.syncState == SyncState.synced), isTrue);
    });

    test('adoption offer can be declined per account', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineModeProvider.notifier);
      expect(await notifier.isAdoptionDeclined(_authId), isFalse);
      await notifier.declineAdoption(_authId);
      expect(await notifier.isAdoptionDeclined(_authId), isTrue);
      expect(await notifier.isAdoptionDeclined('other-user'), isFalse);
    });
  });

  group('welcome screen', () {
    testWidgets('offers both paths with no guest/demo wording', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineModeProvider.overrideWith(() => _FakeOffline(false)),
          ],
          child: const MaterialApp(home: WelcomeScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Continue Offline'), findsOneWidget);
      expect(find.text('Sign In / Create Account'), findsOneWidget);
      expect(find.textContaining('Guest'), findsNothing);
      expect(find.textContaining('demo'), findsNothing);
      expect(find.textContaining('Try MenoMate'), findsNothing);
      expect(find.textContaining('stays on this device'), findsOneWidget);
    });

    testWidgets('Continue Offline enables offline mode, no account needed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: WelcomeScreen());
            },
          ),
        ),
      );
      await tester.pump();

      // Settle the flag first, mirroring the router splash gate in prod
      // (tapping before the initial build resolves is not reachable in
      // the app, and the transient write may be superseded by it).
      await container.read(offlineModeProvider.future);
      // No Supabase session exists in tests; enabling must still work.
      await tester.tap(find.text('Continue Offline'));
      await tester.pump();
      expect(await container.read(offlineModeProvider.future), isTrue);
      expect(container.read(currentUserIdProvider), kOfflineUserId);
      addTearDown(container.dispose);
    });
  });

  group('router lets offline users reach login voluntarily', () {
    Future<GoRouter> pumpRouter(
      WidgetTester tester, {
      required bool offline,
      required DataState<Profile?> profile,
    }) async {
      late GoRouter router;
      final db = _memoryDb();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
            offlineModeProvider.overrideWith(() => _FakeOffline(offline)),
            profileProvider.overrideWith(() => _FixedProfileNotifier(profile)),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      return router;
    }

    testWidgets('undecided user lands on welcome', (tester) async {
      final router = await pumpRouter(
        tester,
        offline: false,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/welcome');
    });

    testWidgets('offline user without profile lands on onboarding', (
      tester,
    ) async {
      final router = await pumpRouter(
        tester,
        offline: true,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/onboarding');
    });

    testWidgets('offline onboarded user lands on home by default', (
      tester,
    ) async {
      final router = await pumpRouter(
        tester,
        offline: true,
        profile: Fresh<Profile?>(_profile(kOfflineUserId)),
      );
      expect(router.state.uri.toString(), '/home');
    });

    testWidgets(
      'offline onboarded user can open login (Settings sign-in path)',
      (tester) async {
        final router = await pumpRouter(
          tester,
          offline: true,
          profile: Fresh<Profile?>(_profile(kOfflineUserId)),
        );
        expect(router.state.uri.toString(), '/home');

        // The Settings "Sign In / Create Account" button pushes /login.
        // The router must let it through instead of bouncing back to
        // /home (which made the button look completely unresponsive).
        router.push('/login');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(router.state.uri.toString(), '/login');
        expect(find.text('Email Address'), findsOneWidget);
      },
    );

    testWidgets('offline user without profile can open login voluntarily', (
      tester,
    ) async {
      final router = await pumpRouter(
        tester,
        offline: true,
        profile: const NoData<Profile?>(),
      );
      expect(router.state.uri.toString(), '/onboarding');

      router.push('/login');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.state.uri.toString(), '/login');
    });
  });

  group('settings reflects offline state', () {
    testWidgets('offline settings shows sign-in path, no sign-out', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
            offlineModeProvider.overrideWith(() => _FakeOffline(true)),
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(
                Fresh<Profile?>(_profile(kOfflineUserId)),
              ),
            ),
            appDatabaseProvider.overrideWithValue(_memoryDb()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(0.6)),
              child: SettingsTab(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Using MenoMate offline'), findsOneWidget);
      expect(find.text('Sign In / Create Account'), findsOneWidget);
      expect(find.text('Sign Out'), findsNothing);
      expect(find.textContaining('only on this device'), findsOneWidget);
    });

    testWidgets('authed settings leads with account identity, no name dup', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authUserIdProvider.overrideWithValue(_authId),
            currentUserIdProvider.overrideWithValue(_authId),
            isOfflineTrackingProvider.overrideWithValue(false),
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(Fresh<Profile?>(_profile(_authId))),
            ),
            appDatabaseProvider.overrideWithValue(_memoryDb()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(0.6)),
              child: SettingsTab(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Identity first: avatar initial, name once, status, sign out nearby.
      expect(find.text('PROFILE · Account'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ama'), findsOneWidget);
      expect(find.text('Signed in — syncing across devices'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      // Name lives in Profile now — not duplicated as a settings field.
      expect(find.text('Your Name'), findsNothing);
      // Hub tile still routes to Profile & Health (header + tile share
      // the concept; header carries the PROFILE prefix).
      expect(find.text('PROFILE · Profile & Health'), findsOneWidget);
      expect(find.text('Profile & Health'), findsOneWidget);
    });
  });

  group('online-only features stay gated offline', () {
    testWidgets('Care explains the sign-in requirement', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
            offlineModeProvider.overrideWith(() => _FakeOffline(true)),
          ],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: AssistantTab());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Settle the flag first, mirroring the router splash gate in prod.
      await container.read(offlineModeProvider.future);
      addTearDown(container.dispose);

      await tester.tap(find.text('Help with my current pain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('using MenoMate offline'), findsWidgets);
      // The offline gate answered first: the old connectivity-only copy
      // (and any AI reply path) never ran.
      expect(
        find.textContaining('Care needs an internet connection'),
        findsNothing,
      );
      expect(find.text('MenoMate Care is thinking...'), findsNothing);
    });
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/health_context_repository.dart';
import 'package:menomate_mobile/data/repositories/profile_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/health_context.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/offline_mode_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/health_conditions_screen.dart';
import 'package:menomate_mobile/screens/health_context_screen.dart';
import 'package:menomate_mobile/screens/health_intro_screen.dart';
import 'package:menomate_mobile/screens/health_medications_screen.dart';
import 'package:menomate_mobile/screens/health_notes_screen.dart';
import 'package:menomate_mobile/screens/health_reproductive_screen.dart';
import 'package:menomate_mobile/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_fake_api.dart';

const _user = 'user-a';

AppDatabase _memoryDb() => AppDatabase.memory();

class _FixedProfileNotifier extends ProfileNotifier {
  final DataState<Profile?> fixed;
  _FixedProfileNotifier(this.fixed);

  @override
  Future<DataState<Profile?>> build() async => fixed;
}

Future<void> _seedSyncedCondition(
  AppDatabase db,
  String userId, {
  required int serverId,
  String code = 'migraine',
}) {
  return db
      .into(db.localConditions)
      .insert(
        LocalConditionsCompanion.insert(
          localId: 'seed-$serverId',
          userId: userId,
          serverId: Value(serverId),
          code: code,
          syncState: const Value(SyncState.synced),
        ),
      );
}

void main() {
  group('validation mirrors the backend contract', () {
    test('birth pair: both-or-neither, plausible range, no age invented', () {
      expect(validateBirthPair(null, null), isNull);
      expect(validateBirthPair(1990, 5), isNull);
      expect(
        validateBirthPair(1990, null),
        contains('both birth month and year'),
      );
      expect(validateBirthPair(null, 5), contains('both birth month and year'));
      expect(validateBirthPair(1899, 5), contains('1900'));
      expect(
        validateBirthPair(DateTime.now().year + 1, 5),
        contains('between 1900'),
      );
      expect(validateBirthPair(1990, 0), contains('1 and 12'));
      expect(validateBirthPair(1990, 13), contains('1 and 12'));
    });

    test('condition other-label contract', () {
      expect(validateConditionInput('pcos', null), isNull);
      expect(validateConditionInput('pcos', ''), isNull);
      expect(validateConditionInput('other', null), contains('own label'));
      expect(validateConditionInput('other', '   '), contains('own label'));
      expect(validateConditionInput('other', 'Fibromyalgia'), isNull);
      expect(
        validateConditionInput('pcos', 'something'),
        contains('only needed'),
      );
      expect(
        validateConditionInput('made_up', null),
        contains('from the list'),
      );
    });

    test('medication names must be non-blank', () {
      expect(validateMedicationName('Ibuprofen'), isNull);
      expect(validateMedicationName('  '), contains('name'));
      expect(validateMedicationName(''), contains('name'));
    });

    test('labels cover every backend enum value', () {
      for (final code in HealthConditionCodes.curated) {
        expect(kConditionLabels[code], isNotNull, reason: code);
      }
      // Backend ContraceptionMethodEnum values verbatim.
      for (final value in [
        'none',
        'combined_pill',
        'progestin_only_pill',
        'patch',
        'ring',
        'injection',
        'implant',
        'hormonal_iud',
        'copper_iud',
        'condoms',
        'sterilization',
        'fertility_awareness',
        'withdrawal',
        'other',
        'prefer_not_to_say',
      ]) {
        expect(kContraceptionLabels[value], isNotNull, reason: value);
      }
      for (final value in [
        'trying_to_conceive',
        'avoiding_pregnancy',
        'pregnant',
        'postpartum',
        'not_applicable',
        'prefer_not_to_say',
      ]) {
        expect(kPregnancyContextLabels[value], isNotNull, reason: value);
      }
      expect(conditionDisplayLabel('pcos', null), 'PCOS');
      expect(conditionDisplayLabel('other', 'Fibromyalgia'), 'Fibromyalgia');
      expect(conditionDisplayLabel('other', null), 'Other');
    });
  });

  group('offline health context (no account, no network)', () {
    test('condition CRUD stays local with localOnly', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);

      expect(
        await repo.loadConditionsLocal(_user),
        isA<NoData<List<HealthCondition>>>(),
      );
      final added = await repo.addCondition(
        _user,
        code: 'pcos',
        note: 'mild',
        localOnly: true,
      );
      expect(added, isA<PendingSync<HealthCondition>>());
      expect(added.dataOrNull!.code, 'pcos');
      expect(api.createConditionCalls, 0);

      // Duplicate curated codes are separate local rows pre-sync (the
      // backend decides 409 at push time, per-row, like cycles).
      await repo.addCondition(_user, code: 'pcos', localOnly: true);
      final listed = await repo.loadConditionsLocal(_user);
      expect(listed.dataOrNull!.length, 2);

      // Update note on the first row.
      final first = listed.dataOrNull!.first;
      final updated = await repo.updateCondition(
        _user,
        first.localId!,
        note: 'managed',
        localOnly: true,
      );
      expect(updated.dataOrNull!.note, 'managed');

      // Unsynced rows disappear immediately (never existed remotely).
      await repo.deleteCondition(_user, first.localId!, localOnly: true);
      final after = await repo.loadConditionsLocal(_user);
      expect(after.dataOrNull!.length, 1);
      expect(api.deleteConditionCalls, 0);
    });

    test('other without a label is rejected before any write', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);

      await expectLater(
        repo.addCondition(_user, code: 'other', localOnly: true),
        throwsA(isA<ValidationError>()),
      );
      expect(
        await repo.loadConditionsLocal(_user),
        isA<NoData<List<HealthCondition>>>(),
      );
      expect(api.createConditionCalls, 0);
    });

    test('synced-row deletes become tombstones, hidden but unsynced', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);
      await _seedSyncedCondition(db, _user, serverId: 42);

      await repo.deleteCondition(_user, 'seed-42', localOnly: true);

      // Hidden from reads...
      final listed = await repo.loadConditionsLocal(_user);
      expect(listed.dataOrNull, isEmpty);
      // ...but retained as pending delete work (logout guard sees it).
      expect(await db.hasUnsyncedData(), isTrue);
      final rows = await (db.select(
        db.localConditions,
      )..where((t) => t.userId.equals(_user))).get();
      expect(rows.single.isDeleted, isTrue);
      expect(rows.single.syncState, SyncState.pending);
    });

    test('medications allow duplicates and toggle active locally', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);

      await repo.addMedication(_user, name: 'Ibuprofen', localOnly: true);
      await repo.addMedication(
        _user,
        name: 'Ibuprofen',
        note: 'evening',
        localOnly: true,
      );
      var listed = await repo.loadMedicationsLocal(_user);
      expect(listed.dataOrNull!.length, 2);

      final first = listed.dataOrNull!.first;
      final toggled = await repo.updateMedication(
        _user,
        first.localId!,
        isActive: false,
        localOnly: true,
      );
      expect(toggled.dataOrNull!.isActive, isFalse);
      listed = await repo.loadMedicationsLocal(_user);
      expect(
        listed.dataOrNull!.firstWhere((m) => m.name == 'Ibuprofen').isActive,
        isFalse,
      );
      expect(api.createMedicationCalls, 0);

      await expectLater(
        repo.addMedication(_user, name: '   ', localOnly: true),
        throwsA(isA<ValidationError>()),
      );
    });

    test('singleton saves locally and clears explicitly', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);

      expect(
        await repo.loadHealthContextLocal(_user),
        isA<NoData<HealthContext?>>(),
      );
      final saved = await repo.saveHealthContext(
        _user,
        const HealthContext(
          userId: _user,
          contraceptionMethod: 'hormonal_iud',
          contraceptionNote: '2023',
          pregnancyContext: 'avoiding_pregnancy',
          healthNotes: 'Some notes.',
        ),
        localOnly: true,
      );
      expect(saved, isA<PendingSync<HealthContext>>());
      expect(api.putHealthContextCalls, 0);

      // Fresh instances (simulated restart) still serve the row.
      final repo2 = HealthContextRepository(db, api);
      final reloaded = await repo2.loadHealthContextLocal(_user);
      expect(reloaded.dataOrNull!.contraceptionMethod, 'hormonal_iud');
      expect(reloaded.dataOrNull!.healthNotes, 'Some notes.');

      // Explicit nulls clear fields (never ambiguous with "untouched").
      await repo2.saveHealthContext(
        _user,
        const HealthContext(userId: _user),
        localOnly: true,
      );
      final cleared = await repo2.loadHealthContextLocal(_user);
      expect(cleared.dataOrNull!.isEmpty, isTrue);
    });
  });

  group('authenticated health context (fake online backend)', () {
    test(
      'condition POST reconciles server id; duplicate 409s per-row',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        final api = FakeApiService();
        final repo = HealthContextRepository(db, api);

        final added = await repo.addCondition(_user, code: 'migraine');
        expect(added, isA<Fresh<HealthCondition>>());
        expect(added.dataOrNull!.id, isNotNull);
        expect(api.serverConditions.length, 1);

        // Same code again: backend 409 → conflict row, nothing lost.
        final dupe = await repo.addCondition(_user, code: 'migraine');
        expect(dupe, isA<ConflictState<HealthCondition>>());
        expect(api.serverConditions.length, 1);
        final listed = await repo.loadConditionsLocal(_user);
        expect(listed, isA<ConflictState<List<HealthCondition>>>());
        expect(listed.dataOrNull!.length, 2);
      },
    );

    test('condition PATCH and idempotent DELETE', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = HealthContextRepository(db, api);

      final added = await repo.addCondition(_user, code: 'anemia', note: 'a');
      final localId = added.dataOrNull!.localId!;

      final patched = await repo.updateCondition(_user, localId, note: 'b');
      expect(patched, isA<Fresh<HealthCondition>>());
      expect(patched.dataOrNull!.note, 'b');
      expect(api.serverConditions.single.note, 'b');

      await repo.deleteCondition(_user, localId);
      expect(
        await repo.loadConditionsLocal(_user),
        isA<NoData<List<HealthCondition>>>(),
      );
      expect(api.serverConditions, isEmpty);

      // Deleting an already-gone row succeeds silently (idempotent):
      // the fake has no server row 999, mirroring a backend 404.
      await _seedSyncedCondition(db, _user, serverId: 999, code: 'asthma');
      final rows = await (db.select(
        db.localConditions,
      )..where((t) => t.userId.equals(_user))).get();
      await repo.deleteCondition(_user, rows.single.localId);
      expect(
        await (db.select(
          db.localConditions,
        )..where((t) => t.userId.equals(_user))).get(),
        isEmpty,
      );
    });

    test('medication PATCH clears notes explicitly, DELETE removes', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = HealthContextRepository(db, api);

      final added = await repo.addMedication(
        _user,
        name: 'Vitamin D',
        note: 'morning',
      );
      expect(added, isA<Fresh<Medication>>());
      final localId = added.dataOrNull!.localId!;

      final cleared = await repo.updateMedication(
        _user,
        localId,
        clearNote: true,
      );
      expect(cleared.dataOrNull!.note, isNull);
      expect(api.serverMedications.single.note, isNull);

      await repo.deleteMedication(_user, localId);
      expect(
        await repo.loadMedicationsLocal(_user),
        isA<NoData<List<Medication>>>(),
      );
      expect(api.serverMedications, isEmpty);
    });

    test('singleton PUT round-trips and clears to null', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = HealthContextRepository(db, api);

      final saved = await repo.saveHealthContext(
        _user,
        const HealthContext(
          userId: _user,
          contraceptionMethod: 'copper_iud',
          pregnancyContext: 'not_applicable',
          healthNotes: 'Hello.',
        ),
      );
      expect(saved, isA<Fresh<HealthContext>>());
      expect(api.serverHealthContext!.contraceptionMethod, 'copper_iud');

      await repo.saveHealthContext(_user, HealthContext(userId: _user));
      expect(api.serverHealthContext!.contraceptionMethod, isNull);
      expect(api.serverHealthContext!.healthNotes, isNull);
    });

    test('birth pair persists through profile save + sync', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ProfileRepository(db, api);

      final saved = await repo.saveProfile(_user, {
        'name': 'Ama',
        'birth_year': 1992,
        'birth_month': 5,
      });
      expect(saved, isA<Fresh<Profile>>());
      expect(api.serverProfile.birthYear, 1992);
      expect(api.serverProfile.birthMonth, 5);

      // Clearing both halves propagates as an explicit clear.
      await repo.saveProfile(_user, {'birth_year': null, 'birth_month': null});
      expect(api.serverProfile.birthYear, isNull);
      expect(api.serverProfile.birthMonth, isNull);
    });

    test('health work never touches prediction endpoints', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = HealthContextRepository(db, api);

      await repo.saveHealthContext(
        _user,
        const HealthContext(userId: _user, healthNotes: 'x'),
      );
      await repo.addCondition(_user, code: 'asthma');
      await repo.addMedication(_user, name: 'Ventolin');
      await repo.loadConditions(_user);
      await repo.loadMedications(_user);
      await repo.loadHealthContext(_user);
      await repo.syncPending(_user);

      expect(api.fetchCurrentCycleCalls, 0);
    });
  });

  group('health adoption, wipe, and unsynced guard', () {
    Future<void> seedOfflineHealth(AppDatabase db) async {
      await db
          .into(db.localHealthContext)
          .insert(
            LocalHealthContextCompanion.insert(
              userId: kOfflineUserId,
              contraceptionMethod: const Value('hormonal_iud'),
              syncState: const Value(SyncState.pending),
            ),
          );
      await db
          .into(db.localConditions)
          .insert(
            LocalConditionsCompanion.insert(
              localId: 'hc-1',
              userId: kOfflineUserId,
              code: 'endometriosis',
              note: const Value('noted'),
              syncState: const Value(SyncState.pending),
            ),
          );
      await db
          .into(db.localMedications)
          .insert(
            LocalMedicationsCompanion.insert(
              localId: 'hm-1',
              userId: kOfflineUserId,
              name: 'Ibuprofen',
              syncState: const Value(SyncState.pending),
            ),
          );
    }

    test('counts include health rows; adopt moves and syncs them', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await seedOfflineHealth(db);

      expect(await db.offlineAdoptableCounts(), (
        cycles: 0,
        logs: 0,
        conditions: 1,
        medications: 1,
        healthContext: true,
      ));

      const authId = 'auth-user-1';
      final moved = await db.adoptOfflineData(authId);
      expect(moved.conditions, 1);
      expect(moved.medications, 1);
      expect(moved.healthContext, isTrue);

      // Values and states preserved under the new identity.
      final conditions = await (db.select(
        db.localConditions,
      )..where((t) => t.userId.equals(authId))).get();
      expect(conditions.single.code, 'endometriosis');
      expect(conditions.single.note, 'noted');
      expect(conditions.single.serverId, isNull);
      final context = await (db.select(
        db.localHealthContext,
      )..where((t) => t.userId.equals(authId))).getSingle();
      expect(context.contraceptionMethod, 'hormonal_iud');

      // Push through the normal machinery without duplicates on repeat.
      final api = FakeApiService();
      final repo = HealthContextRepository(db, api);
      await repo.syncPending(authId);
      expect(api.serverConditions.length, 1);
      expect(api.serverMedications.length, 1);
      expect(api.serverHealthContext!.contraceptionMethod, 'hormonal_iud');
      await repo.syncPending(authId);
      expect(api.serverConditions.length, 1);
      expect(api.serverMedications.length, 1);
      expect(api.putHealthContextCalls, 1);
    });

    test('second adopt is a no-op; unrelated rows untouched', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await seedOfflineHealth(db);
      const authId = 'auth-user-1';
      await db.adoptOfflineData(authId);
      expect(await db.adoptOfflineData(authId), (
        cycles: 0,
        logs: 0,
        conditions: 0,
        medications: 0,
        healthContext: false,
      ));
      expect(
        await (db.select(
          db.localConditions,
        )..where((t) => t.userId.equals(kOfflineUserId))).get(),
        isEmpty,
      );
    });

    test(
      'pending health rows trip the logout guard and wipe clears them',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        await seedOfflineHealth(db);
        expect(await db.hasUnsyncedData(), isTrue);

        await db.clearAllUserData();
        expect(await (db.select(db.localHealthContext)).get(), isEmpty);
        expect(await (db.select(db.localConditions)).get(), isEmpty);
        expect(await (db.select(db.localMedications)).get(), isEmpty);
        expect(await db.hasUnsyncedData(), isFalse);
      },
    );
  });

  group('health intro persistence and navigation', () {
    testWidgets('skip dismisses and returns; explore continues', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/health-intro'),
                  child: const Text('Open intro'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/health-intro',
            builder: (_, _) => const HealthIntroScreen(),
          ),
          GoRoute(
            path: '/profile/health',
            builder: (_, _) => const Scaffold(body: Text('HEALTH_HOME')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserIdProvider.overrideWithValue('user-a')],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open intro'));
      await tester.pumpAndSettle();
      expect(
        find.text('Help MenoMate understand your context'),
        findsOneWidget,
      );
      expect(find.text('Skip for now'), findsOneWidget);
      expect(find.text('Explore Health Context'), findsOneWidget);

      // Skip: persists dismissal and pops back.
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(find.text('Open intro'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('menomate.intro_dismissed.health_context.user-a'),
        isTrue,
      );

      // Explore: persists and replaces with the health screen.
      await tester.tap(find.text('Open intro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore Health Context'));
      await tester.pumpAndSettle();
      expect(find.text('HEALTH_HOME'), findsOneWidget);
    });
  });

  group('profile screen birth editing', () {
    Future<void> pumpProfile(
      WidgetTester tester, {
      required Profile profile,
      required AppDatabase db,
      required FakeApiService api,
    }) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(profile.userId),
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(Fresh<Profile?>(profile)),
            ),
            appDatabaseProvider.overrideWithValue(db),
            profileRepositoryProvider.overrideWith(
              (ref) => ProfileRepository(db, api),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(0.6)),
              child: ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('invalid birth input blocks save with guidance', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpProfile(
        tester,
        profile: Profile(userId: _user, name: 'Ama'),
        db: db,
        api: api,
      );

      await tester.enterText(find.widgetWithText(TextField, 'e.g. 1990'), '99');
      await tester.tap(find.text('Save Profile'));
      await tester.pump();
      expect(find.textContaining('1990'), findsOneWidget);
      expect(api.patchProfileCalls, 0);
    });

    testWidgets('valid month/year saves through the profile repo', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await pumpProfile(
        tester,
        profile: Profile(userId: _user, name: 'Ama'),
        db: db,
        api: api,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 1990'),
        '1992',
      );
      // Month dropdown is the only DropdownButton on the screen.
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('May').last);
      await tester.pump();
      await tester.tap(find.text('Save Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(api.serverProfile.birthYear, 1992);
      expect(api.serverProfile.birthMonth, 5);
    });
  });

  group('reproductive and notes screens preserve the singleton', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required AppDatabase db,
      required FakeApiService api,
      required Widget screen,
    }) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_user),
            isOfflineTrackingProvider.overrideWithValue(true),
            appDatabaseProvider.overrideWithValue(db),
            healthContextRepositoryProvider.overrideWith(
              (ref) => HealthContextRepository(db, api),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.6)),
            child: MaterialApp(home: screen),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('reproductive save keeps existing notes', (tester) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);
      await repo.saveHealthContext(
        _user,
        const HealthContext(userId: _user, healthNotes: 'Keep me'),
        localOnly: true,
      );
      await pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const HealthReproductiveScreen(),
      );

      await tester.tap(find.byType(DropdownButton<String?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hormonal IUD').last);
      await tester.pump();
      await tester.tap(find.text('Save reproductive health'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final reloaded = await repo.loadHealthContextLocal(_user);
      expect(reloaded.dataOrNull!.contraceptionMethod, 'hormonal_iud');
      // Untouched notes survive the full-replacement save.
      expect(reloaded.dataOrNull!.healthNotes, 'Keep me');
    });

    testWidgets('notes save keeps existing selections', (tester) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);
      await repo.saveHealthContext(
        _user,
        const HealthContext(
          userId: _user,
          contraceptionMethod: 'copper_iud',
          pregnancyContext: 'avoiding_pregnancy',
        ),
        localOnly: true,
      );
      await pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const HealthNotesScreen(),
      );

      await tester.enterText(find.byType(TextField), 'My note here');
      await tester.tap(find.text('Save notes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final reloaded = await repo.loadHealthContextLocal(_user);
      expect(reloaded.dataOrNull!.healthNotes, 'My note here');
      expect(reloaded.dataOrNull!.contraceptionMethod, 'copper_iud');
      expect(reloaded.dataOrNull!.pregnancyContext, 'avoiding_pregnancy');
    });

    testWidgets('hub summaries reflect stored data', (tester) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = HealthContextRepository(db, api);
      await repo.addCondition(_user, code: 'pcos', localOnly: true);
      await repo.saveHealthContext(
        _user,
        const HealthContext(userId: _user, contraceptionMethod: 'hormonal_iud'),
        localOnly: true,
      );
      await pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const HealthContextScreen(),
      );

      expect(find.text('1 condition'), findsOneWidget);
      expect(find.textContaining('Hormonal IUD'), findsOneWidget);
    });
  });

  group('health hub navigation and condition dialog', () {
    Future<void> pumpHealthHub(
      WidgetTester tester, {
      required AppDatabase db,
      required FakeApiService api,
    }) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: '/profile/health',
        routes: [
          GoRoute(
            path: '/profile/health',
            builder: (_, _) => const HealthContextScreen(),
          ),
          GoRoute(
            path: '/profile/health/conditions',
            builder: (_, _) => const HealthConditionsScreen(),
          ),
          GoRoute(
            path: '/profile/health/medications',
            builder: (_, _) => const HealthMedicationsScreen(),
          ),
          GoRoute(
            path: '/profile/health/reproductive',
            builder: (_, _) => const HealthReproductiveScreen(),
          ),
          GoRoute(
            path: '/profile/health/notes',
            builder: (_, _) => const HealthNotesScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_user),
            isOfflineTrackingProvider.overrideWithValue(true),
            appDatabaseProvider.overrideWithValue(db),
            healthContextRepositoryProvider.overrideWith(
              (ref) => HealthContextRepository(db, api),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.6)),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('hub shows all four categories with summaries', (tester) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      await pumpHealthHub(tester, db: db, api: api);

      expect(find.text('Health conditions'), findsOneWidget);
      expect(find.text('Medications & treatments'), findsOneWidget);
      expect(find.text('Reproductive health'), findsOneWidget);
      expect(find.text('Anything else'), findsOneWidget);
      // Empty-state summaries, no save button on the hub itself.
      expect(find.text('None added yet'), findsNWidgets(2));
      expect(find.text('Not set yet'), findsNWidgets(2));
      expect(find.text('Save health details'), findsNothing);
    });

    testWidgets('category card navigates to its focused screen', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      await pumpHealthHub(tester, db: db, api: api);

      await tester.tap(find.text('Health conditions'));
      await tester.pumpAndSettle();
      expect(find.text('Add condition'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medications & treatments'));
      await tester.pumpAndSettle();
      expect(find.text('Add medication'), findsOneWidget);
    });

    testWidgets('Other without a label is rejected; with label saves', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      await pumpHealthHub(tester, db: db, api: api);

      await tester.tap(find.text('Health conditions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add condition'));
      await tester.pumpAndSettle();
      // Curated radio list is rendered.
      expect(find.text('PCOS'), findsOneWidget);

      // Choose Other and try to save without a label.
      await tester.scrollUntilVisible(
        find.text('Other'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('condition_code_list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Other'));
      await tester.pump();
      await tester.tap(find.text('Add').last);
      await tester.pump();
      expect(find.textContaining('own label'), findsOneWidget);
      final repo = HealthContextRepository(db, api);
      expect(
        (await repo.loadConditionsLocal(_user)).dataOrNull,
        anyOf(isNull, isEmpty),
      );

      // Provide the label: saves and appears in the list.
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Fibromyalgia'),
        'Fibromyalgia',
      );
      await tester.tap(find.text('Add').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Fibromyalgia'), findsOneWidget);
    });
  });
}

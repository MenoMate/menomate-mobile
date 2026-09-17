import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/content/insight_library.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/care.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/providers/theme_provider.dart';
import 'package:menomate_mobile/screens/tabs/home_tab.dart';
import 'package:menomate_mobile/screens/tabs/settings_tab.dart';
import 'package:menomate_mobile/widgets/care_message_bubble.dart';
import 'package:menomate_mobile/widgets/daily_insight_card.dart';

import 'offline_fake_api.dart';

const _user = 'user-a';

AppDatabase _memoryDb() => AppDatabase.memory();

class _FixedProfileNotifier extends ProfileNotifier {
  final DataState<Profile?> fixed;
  _FixedProfileNotifier(this.fixed);

  @override
  Future<DataState<Profile?>> build() async => fixed;
}

class _FixedInsightNotifier extends DailyInsightNotifier {
  @override
  AsyncValue<InsightPair?> build() => AsyncData<InsightPair?>(
    selectInsightPair(
      const InsightInput(hasData: true, phase: 'menstrual', menstrualDay: 2),
    ),
  );
}

void main() {
  group('logout pending-data guard (hasUnsyncedData)', () {
    test('pending cycle row is detected', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await db
          .into(db.localCycles)
          .insert(
            LocalCyclesCompanion.insert(
              localId: 'pending-1',
              userId: _user,
              periodStart: '2026-08-01',
              syncState: const Value(SyncState.pending),
            ),
          );
      expect(await db.hasUnsyncedData(), isTrue);
    });

    test('conflict daily-log row is detected', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await db
          .into(db.localDailyLogs)
          .insert(
            LocalDailyLogsCompanion.insert(
              userId: _user,
              logDate: '2026-08-10',
              syncState: const Value(SyncState.conflict),
            ),
          );
      expect(await db.hasUnsyncedData(), isTrue);
    });

    test('pending profile row is detected', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await db
          .into(db.localProfiles)
          .insert(
            LocalProfilesCompanion.insert(
              userId: _user,
              theme: const Value('dark'),
              syncState: const Value(SyncState.pending),
            ),
          );
      expect(await db.hasUnsyncedData(), isTrue);
    });

    test('all-synced data reports no unsynced work', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await db
          .into(db.localProfiles)
          .insert(
            LocalProfilesCompanion.insert(
              userId: _user,
              syncState: const Value(SyncState.synced),
            ),
          );
      await db
          .into(db.localCycles)
          .insert(
            LocalCyclesCompanion.insert(
              localId: 'synced-1',
              userId: _user,
              periodStart: '2026-08-01',
              periodEnd: const Value('2026-08-05'),
              syncState: const Value(SyncState.synced),
            ),
          );
      expect(await db.hasUnsyncedData(), isFalse);
    });

    test('empty database reports no unsynced work', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      expect(await db.hasUnsyncedData(), isFalse);
    });
  });

  group('theme persist preserves unrelated profile fields', () {
    test('toggling theme keeps name, lengths, units, timezone', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      await db
          .into(db.localProfiles)
          .insert(
            LocalProfilesCompanion.insert(
              userId: _user,
              name: const Value('Ama'),
              usualCycleDays: const Value(30),
              usualPeriodDays: const Value(4),
              theme: const Value('light'),
              units: const Value('metric'),
              timezone: const Value('Asia/Kolkata'),
              syncState: const Value(SyncState.synced),
            ),
          );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          currentUserIdProvider.overrideWithValue(_user),
        ],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.read(themeModeProvider.notifier).toggleTheme(true);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final row = await (db.select(
        db.localProfiles,
      )..where((t) => t.userId.equals(_user))).getSingle();
      expect(row.theme, 'dark');
      expect(row.syncState, SyncState.pending);
      expect(row.name, 'Ama');
      expect(row.usualCycleDays, 30);
      expect(row.usualPeriodDays, 4);
      expect(row.units, 'metric');
      expect(row.timezone, 'Asia/Kolkata');
    });
  });

  group('Care disclaimer + source marker', () {
    Future<void> pumpBubble(
      WidgetTester tester,
      Map<String, dynamic> message,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CareMessageBubble(
              message: message,
              bleConnected: false,
              onAction: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('backend disclaimer and AI marker are shown', (tester) async {
      await pumpBubble(tester, {
        'isUser': false,
        'text': 'Rest may help.',
        'intent': 'pain_help',
        'tier': 'info',
        'actions': const <CareAction>[],
        'isAi': true,
        'disclaimer': 'Server limitation note.',
      });
      expect(find.textContaining('Server limitation note.'), findsOneWidget);
      expect(find.textContaining('AI-generated'), findsOneWidget);
    });

    testWidgets('empty disclaimer falls back to safe default', (tester) async {
      await pumpBubble(tester, {
        'isUser': false,
        'text': 'Rest may help.',
        'intent': 'pain_help',
        'tier': 'info',
        'actions': const <CareAction>[],
        'isAi': false,
        'disclaimer': '',
      });
      expect(find.textContaining('not medical advice'), findsOneWidget);
      expect(find.textContaining('MenoMate library'), findsOneWidget);
    });

    testWidgets('urgent card keeps disclaimer footer', (tester) async {
      await pumpBubble(tester, {
        'isUser': false,
        'text': 'Seek care promptly.',
        'intent': 'pain_help',
        'tier': 'urgent',
        'actions': const <CareAction>[],
        'isAi': true,
        'disclaimer': 'Server limitation note.',
      });
      expect(find.text('CLINICAL SAFETY ADVISORY'), findsOneWidget);
      expect(find.textContaining('Server limitation note.'), findsOneWidget);
    });
  });

  group('user-entered future date is not a prediction', () {
    test('future-only view carries no invented confidence', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final futureStart = toIsoDate(
        DateTime.now().add(const Duration(days: 10)),
      );
      await db
          .into(db.localCycles)
          .insert(
            LocalCyclesCompanion.insert(
              localId: 'future-1',
              userId: _user,
              periodStart: futureStart,
              syncState: const Value(SyncState.synced),
            ),
          );

      final state = await CycleRepository(db, api).loadCurrent(_user);
      final view = state.dataOrNull!;
      expect(view.predictionConfidence, 'None');
      expect(view.predictionStatus, 'user_logged');
      expect(view.predictedNextPeriod, isNull);
      expect(view.predictionSource, 'user_logged');
      expect(view.latestPeriodStart, isNotNull);
    });

    testWidgets('home shows recorded wording and unknown ring', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final futureStart = DateTime.now().add(const Duration(days: 10));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCycleProvider.overrideWith(
              (ref) => Future.value(
                Fresh<CurrentCycleResponse?>(
                  CurrentCycleResponse(
                    hasData: true,
                    phase: 'unknown',
                    isBleeding: false,
                    latestPeriodStart: futureStart,
                    daysUntilNextPeriod: 10,
                    predictionStatus: 'user_logged',
                    predictionConfidence: 'None',
                    predictionSource: 'user_logged',
                  ),
                ),
              ),
            ),
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(const NoData<Profile?>()),
            ),
            dailyInsightProvider.overrideWith(() => _FixedInsightNotifier()),
          ],
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Logged period starting'), findsOneWidget);
      expect(find.textContaining('None confidence'), findsNothing);
      expect(find.textContaining('high confidence'), findsNothing);
      expect(find.textContaining('Not enough data yet'), findsOneWidget);
    });
  });

  group('missing lengths stay unknown', () {
    testWidgets('settings shows empty fields for null lengths', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(
                Fresh<Profile?>(
                  Profile(
                    userId: _user,
                    name: 'Ama',
                    usualCycleDays: null,
                    usualPeriodDays: null,
                  ),
                ),
              ),
            ),
          ],
          // Shrink test-harness (Ahem) text so the pre-existing Units row
          // fits; this test only reads controller values, not pixels.
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

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      String textOf(String label) =>
          fields
              .firstWhere(
                (f) => (f.decoration?.labelText ?? '').contains(label),
              )
              .controller
              ?.text ??
          '<missing>';
      expect(textOf('Usual Cycle Length'), isEmpty);
      expect(textOf('Usual Period Length'), isEmpty);
    });
  });
}

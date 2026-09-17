import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/summary.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/screens/symptom_logger_screen.dart';
import 'package:menomate_mobile/screens/tabs/history_tab.dart';
import 'package:menomate_mobile/services/api_service.dart';

import 'offline_fake_api.dart';

const _userId = 'user-a';

String _todayIso() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// Tall viewport so the logger's Save button is hittable without scrolling.
void _tallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Logger form + History discoverability regression tests.
/// Provider override lists are written inline at each pumpWidget call so
/// Riverpod infers the override list type from the parameter context.
void main() {
  // Create -> explicit message + form resets to a new-log state.
  testWidgets('create daily log saves, announces, and resets the form',
      (tester) async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiServiceProvider.overrideWith((ref) => api),
          currentUserIdProvider.overrideWithValue(_userId),
        ],
        child: const MaterialApp(home: SymptomLoggerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('how are you feeling today?'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'mild headache');
    _tallViewport(tester);
    await tester.pump();
    // The structured-logging sections made the form taller: scroll the
    // action into view before tapping.
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Save Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Log'));
    await tester.pumpAndSettle();

    // Explicit online feedback...
    expect(find.text('Daily log saved'), findsOneWidget);
    // ...form reset to defaults (notes cleared) with the record now
    // existing, so the header reflects edit mode for the saved date...
    expect(find.text('mild headache'), findsNothing);
    expect(find.textContaining('editing saved log'), findsOneWidget);
    expect(find.textContaining('how are you feeling today?'), findsNothing);
    // ...and exactly one server record exists.
    expect(api.serverLogs.length, 1);
    expect(api.serverLogs[_todayIso()]!.notes, 'mild headache');
  });

  // Existing log opens in a clearly indicated edit mode.
  testWidgets('existing daily log opens as an edit, not a blank form',
      (tester) async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    await db.into(db.localDailyLogs).insert(
          LocalDailyLogsCompanion.insert(
            userId: _userId,
            logDate: _todayIso(),
            pain: const Value(6),
            notes: const Value('bad cramps'),
            syncState: const Value(SyncState.synced),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiServiceProvider.overrideWith((ref) => api),
          currentUserIdProvider.overrideWithValue(_userId),
        ],
        child: const MaterialApp(home: SymptomLoggerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('editing saved log'), findsOneWidget);
    expect(find.text('bad cramps'), findsOneWidget);
    expect(find.textContaining('how are you feeling today?'), findsNothing);
  });

  // Offline save says where the data went and shows not-synced state.
  testWidgets('offline save reports on-device storage with not-synced state',
      (tester) async {
    final db = AppDatabase.memory();
    final api = FakeApiService()..offline = true;
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiServiceProvider.overrideWith((ref) => api),
          currentUserIdProvider.overrideWithValue(_userId),
        ],
        child: const MaterialApp(home: SymptomLoggerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    _tallViewport(tester);
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Save Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Log'));
    await tester.pumpAndSettle();

    expect(find.text('Saved on this device'), findsOneWidget);
    expect(find.text('Not synced'), findsOneWidget);
    expect(api.serverLogs, isEmpty);
  });

  // History selected-day card navigates to the logger for that date.
  testWidgets('history day offers a path to view/edit the daily log',
      (tester) async {
    final db = AppDatabase.memory();
    final api = FakeApiService();
    addTearDown(db.close);
    final now = DateTime.now();
    final historyState = Fresh<HistorySummaryResponse>(
      HistorySummaryResponse(
        totalPeriodsLogged: 0,
        history: const [],
        symptomFrequencies: const {},
      ),
    );
    final cyclesState = Fresh<List<CycleResponse>>([
      CycleResponse(
        id: 1,
        userId: _userId,
        periodStart: now,
        periodEnd: now,
        periodLengthDays: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    const currentState = Fresh<CurrentCycleResponse?>(null);

    String? pushedDate;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HistoryTab()),
        GoRoute(
          path: '/logger',
          builder: (_, state) {
            pushedDate = state.uri.queryParameters['date'];
            return Text('logger:$pushedDate',
                textDirection: TextDirection.ltr);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiServiceProvider.overrideWith((ref) => api),
          currentUserIdProvider.overrideWithValue(_userId),
          historySummaryProvider
              .overrideWith((ref) => Future.value(historyState)),
          cycleListProvider
              .overrideWith((ref) => Future.value(cyclesState)),
          currentCycleProvider
              .overrideWith((ref) => Future.value(currentState)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View / edit wellness log'));
    await tester.pumpAndSettle();

    expect(pushedDate, _todayIso());
    expect(find.text('logger:${_todayIso()}'), findsOneWidget);
  });
}

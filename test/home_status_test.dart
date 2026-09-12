import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/tabs/home_tab.dart';
import 'package:menomate_mobile/widgets/daily_insight_card.dart';

class _FixedProfileNotifier extends ProfileNotifier {
  final DataState<Profile?> fixed;
  _FixedProfileNotifier(this.fixed);

  @override
  Future<DataState<Profile?>> build() async => fixed;
}

class _FixedInsightNotifier extends DailyInsightNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData<String?>('tip');
}

/// Home cycle card: tracked period/bleeding status is rendered separately
/// from the authoritative backend phase. The ring keeps Day N + verbatim
/// server phase; one secondary line reports ongoing vs ended from stored
/// start/end facts only. No phase logic is introduced here.
void main() {
  Future<void> pumpHome(
    WidgetTester tester,
    DataState<CurrentCycleResponse?> cycle,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentCycleProvider.overrideWith((ref) => Future.value(cycle)),
          profileProvider.overrideWith(
            () => _FixedProfileNotifier(const NoData<Profile?>()),
          ),
          dailyInsightProvider.overrideWith(() => _FixedInsightNotifier()),
        ],
        child: const MaterialApp(home: HomeTab()),
      ),
    );
    // Bounded pumps only (stable even with animations on screen).
    // Futures resolve on the first frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
  }

  // 1. Ongoing cycle: status, End action, verbatim phase.
  testWidgets('ongoing cycle shows period in progress', (tester) async {
    await pumpHome(
      tester,
      Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 3,
          phase: 'menstrual',
          isBleeding: true,
          isOngoing: true,
          latestPeriodStart: DateTime(2026, 8, 1),
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(find.text('Period in progress'), findsOneWidget);
    expect(find.text('Day 3'), findsOneWidget);
    expect(find.text('MENSTRUAL'), findsOneWidget);
    expect(find.text('Log Period Ended Today'), findsOneWidget);
  });

  // 2. Ended-today with menstrual phase: ended status, phase untouched.
  testWidgets('ended-today cycle keeps MENSTRUAL phase with ended status',
      (tester) async {
    final today = DateTime.now();
    final todayDay =
        DateTime(today.year, today.month, today.day);
    await pumpHome(
      tester,
      Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 1,
          phase: 'menstrual',
          isBleeding: false,
          isOngoing: false,
          latestPeriodStart: todayDay,
          latestPeriodEnd: todayDay,
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(
      find.text(
          'Period ended ${DateFormat('MMM d').format(todayDay)} · 1 day'),
      findsOneWidget,
    );
    // No Flutter-side conversion to FOLLICULAR occurred.
    expect(find.text('MENSTRUAL'), findsOneWidget);
    expect(find.text('FOLLICULAR'), findsNothing);
    expect(find.text('Log Period Started Today'), findsOneWidget);
  });

  // 3. Ended cycle with follicular server phase: both unchanged.
  testWidgets('ended cycle keeps FOLLICULAR phase with ended status',
      (tester) async {
    await pumpHome(
      tester,
      Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 7,
          phase: 'follicular',
          isBleeding: false,
          isOngoing: false,
          latestPeriodStart: DateTime(2026, 8, 1),
          latestPeriodEnd: DateTime(2026, 8, 5),
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(find.text('Period ended Aug 5 · 5 days'), findsOneWidget);
    expect(find.text('FOLLICULAR'), findsOneWidget);
  });

  // 4. Ended status and MENSTRUAL phase coexist explicitly.
  testWidgets('period-ended status and MENSTRUAL render simultaneously',
      (tester) async {
    await pumpHome(
      tester,
      Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 3,
          phase: 'menstrual',
          isBleeding: false,
          isOngoing: false,
          latestPeriodStart: DateTime(2026, 8, 1),
          latestPeriodEnd: DateTime(2026, 8, 3),
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(find.text('Period ended Aug 3 · 3 days'), findsOneWidget);
    expect(find.text('MENSTRUAL'), findsOneWidget);
  });

  // 5. Cached/offline ended state renders without network.
  testWidgets('cached ended state renders ended status verbatim',
      (tester) async {
    await pumpHome(
      tester,
      Cached<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 3,
          phase: 'menstrual',
          isBleeding: false,
          isOngoing: false,
          latestPeriodStart: DateTime(2026, 8, 1),
          latestPeriodEnd: DateTime(2026, 8, 3),
          predictionConfidence: 'low',
        ),
        DateTime(2026, 8, 2),
      ),
    );

    expect(find.text('Period ended Aug 3 · 3 days'), findsOneWidget);
    expect(find.text('MENSTRUAL'), findsOneWidget);
  });

  // 6. No-data state unchanged, with no invented status line.
  testWidgets('no cycle data keeps existing empty behavior', (tester) async {
    await pumpHome(tester, const NoData<CurrentCycleResponse?>());

    expect(
      find.text('No cycle data available. Log your period to begin.'),
      findsOneWidget,
    );
    expect(find.text('Period in progress'), findsNothing);
    expect(find.textContaining('Period ended'), findsNothing);
  });
}

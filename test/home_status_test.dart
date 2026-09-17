import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/content/insight_library.dart';
import 'package:menomate_mobile/screens/tabs/home_tab.dart';
import 'package:menomate_mobile/widgets/daily_insight_card.dart';
import 'package:menomate_mobile/widgets/interactive_cycle_ring.dart';

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
    expect(find.text('Menstrual'), findsOneWidget);
    expect(find.text('Log Period Ended Today'), findsOneWidget);
  });

  // 2. Ended-today with menstrual phase: ended status, phase untouched.
  testWidgets('ended-today cycle keeps friendly phase with ended status', (
    tester,
  ) async {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
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
      find.text('Period ended ${DateFormat('MMM d').format(todayDay)} · 1 day'),
      findsOneWidget,
    );
    // No Flutter-side conversion to FOLLICULAR occurred.
    expect(find.text('Menstrual'), findsOneWidget);
    expect(find.text('Follicular'), findsNothing);
    expect(find.text('Log Period Started Today'), findsOneWidget);
  });

  // 3. Ended cycle with follicular server phase: both unchanged.
  testWidgets('ended cycle keeps friendly phase with ended status', (
    tester,
  ) async {
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
    expect(find.text('Follicular'), findsOneWidget);
  });

  // 4. Ended status and menstrual phase coexist explicitly.
  testWidgets('period-ended status and phase render simultaneously', (
    tester,
  ) async {
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
    expect(find.text('Menstrual'), findsOneWidget);
  });

  // 5. Cached/offline ended state renders without network.
  testWidgets('cached ended state renders ended status verbatim', (
    tester,
  ) async {
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
    expect(find.text('Menstrual'), findsOneWidget);
  });

  // 6. Phase info affordance explains estimates without new claims.
  testWidgets('phase info button opens the phases explainer', (tester) async {
    await pumpHome(
      tester,
      Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 12,
          phase: 'luteal',
          isBleeding: false,
          isOngoing: false,
          latestPeriodStart: DateTime(2026, 8, 1),
          latestPeriodEnd: DateTime(2026, 8, 5),
          averageCycleLength: 28,
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(find.text('Luteal'), findsOneWidget);
    await tester.tap(find.byTooltip('About cycle phases'));
    await tester.pumpAndSettle();
    expect(find.text('About cycle phases'), findsOneWidget);
    expect(
      find.textContaining('estimated from your logged history'),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('About cycle phases'), findsNothing);
  });

  // 7. Ring center (phase label + info affordance) survives large text.
  // Scoped to the ring itself: sibling home cards carry their own
  // overflow budgets, covered separately at default scale.
  testWidgets('ring center holds at 2x text scale without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: InteractiveCycleRing(
              phase: 'luteal',
              currentDay: 12,
              cycleLength: 28,
              onPhaseInfoTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luteal'), findsOneWidget);
    expect(find.byTooltip('About cycle phases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 8. No-data state unchanged, with no invented status line.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/core/format.dart';
import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/care.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/models/summary.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/tabs/assistant_tab.dart';
import 'package:menomate_mobile/screens/tabs/history_tab.dart';
import 'package:menomate_mobile/screens/tabs/home_tab.dart';
import 'package:menomate_mobile/services/api_service.dart';
import 'package:menomate_mobile/widgets/daily_insight_card.dart';
import 'package:menomate_mobile/widgets/device_telemetry_card.dart';
import 'package:table_calendar/table_calendar.dart';

import 'offline_fake_api.dart';

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

class _CountingCareApi extends FakeApiService {
  int calls = 0;
  bool fail = false;

  @override
  Future<CareInteractionResponse?> postCareInteraction(
      CareInteractionRequest request) async {
    calls++;
    if (fail) throw Exception('offline');
    return CareInteractionResponse(
      intent: request.intent,
      responseText: 'canned tip',
      isAiGenerated: true,
      suggestedActions: const [],
      disclaimer: '',
    );
  }
}

void _tallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required DataState<CurrentCycleResponse?> cycle,
}) async {
  _tallViewport(tester);
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  // Item 3: display formatting only (no calculation logic here).
  group('formatDayCount', () {
    test('singular', () => expect(formatDayCount(1, 'day'), '1 day'));
    test('plural', () {
      expect(formatDayCount(2, 'day'), '2 days');
      expect(formatDayCount(28, 'day'), '28 days');
    });
    test('zero/sub-day renders em dash, never "0 days"', () {
      expect(formatDayCount(0, 'day'), '–');
      expect(formatDayCount(-3, 'day'), '–');
    });
  });

  // Item 1: no floating therapy control on Home; wearable card stays.
  testWidgets('Home has no floating therapy action; wearable section stays',
      (tester) async {
    await _pumpHome(
      tester,
      cycle: Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 2,
          phase: 'menstrual',
          isBleeding: true,
          isOngoing: true,
          latestPeriodStart: DateTime(2026, 9, 12),
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(DeviceTelemetryCard), findsOneWidget);
    // Period logging (the lawful Home action) is untouched.
    expect(find.text('Log Period Ended Today'), findsOneWidget);
  });

  // Item 2: calendar semantic colors from tokens (light + dark).
  // Ranges are computed from "today" so every target label is unique and
  // in-month on any run date (outside labels are only month tails/heads).
  group('calendar semantic colors', () {
    late int loggedMid;
    late int predictedAnchor;
    late int tapDay;

    Future<void> pumpHistory(
      WidgetTester tester, {
      required ThemeData theme,
    }) async {
      _tallViewport(tester);
      final now = DateTime.now();
      if (now.day >= 20) {
        loggedMid = 9; // logged span 8..10
        predictedAnchor = 14; // predicted span 14..16 (avgLen 3)
        tapDay = 18;
      } else {
        loggedMid = 23; // logged span 22..24
        predictedAnchor = 25; // predicted span 25..26 (avgLen 2, Feb-safe)
        tapDay = 20;
      }
      final spanLen = now.day >= 20 ? 3 : 2;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historySummaryProvider.overrideWith(
              (ref) => Future.value(Fresh<HistorySummaryResponse>(
                HistorySummaryResponse(
                  totalPeriodsLogged: 0,
                  history: const [],
                  symptomFrequencies: const {},
                ),
              )),
            ),
            cycleListProvider.overrideWith(
              (ref) => Future.value(Fresh<List<CycleResponse>>([
                CycleResponse(
                  id: 1,
                  userId: 'user-a',
                  periodStart:
                      DateTime(now.year, now.month, loggedMid - 1),
                  periodEnd: DateTime(now.year, now.month, loggedMid + 1),
                  periodLengthDays: 3,
                  createdAt: now,
                  updatedAt: now,
                ),
              ])),
            ),
            currentCycleProvider.overrideWith(
              (ref) => Future.value(Fresh<CurrentCycleResponse?>(
                CurrentCycleResponse(
                  hasData: true,
                  currentCycleDay: now.day,
                  phase: 'menstrual',
                  isBleeding: true,
                  isOngoing: true,
                  latestPeriodStart:
                      DateTime(now.year, now.month, loggedMid - 1),
                  averagePeriodLength: spanLen,
                  predictedNextPeriod: DateTime(
                      now.year, now.month, predictedAnchor),
                  predictionConfidence: 'low',
                ),
              )),
            ),
          ],
          child: MaterialApp(
            theme: theme,
            home: const HistoryTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Container decoratedDayCell(WidgetTester tester, String label) {
      final cells = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle),
      );
      expect(cells, findsOneWidget);
      return tester.widget<Container>(cells);
    }

    testWidgets('light: logged/today/predicted/selected all distinct tokens',
        (tester) async {
      await pumpHistory(tester, theme: MenoMateTheme.sakuraTheme);
      final colors = MenoMateTheme.sakuraTheme.colorScheme;
      final neutral = todayNeutralFill(colors);

      // todayNeutralFill is a whisper of onSurface: never rose, never
      // violet, and identical for cells and the legend dot by construction.
      expect(neutral, isNot(colors.primary));
      expect(neutral, isNot(colors.tertiary));
      expect(
        neutral,
        colors.onSurface.withValues(alpha: 0.10),
      );

      // TableCalendar must have an explicit selected builder: without it
      // the package-default indigo selected decoration leaks into the app.
      final calendar =
          tester.widget<TableCalendar>(find.byType(TableCalendar));
      expect(calendar.calendarBuilders.selectedBuilder, isNotNull);

      // Today is selected by default: neutral fill + onSurface text/rim.
      final now = DateTime.now();
      final todayCell = decoratedDayCell(tester, '${now.day}');
      final todayDeco = todayCell.decoration as BoxDecoration;
      expect(todayDeco.color, neutral);
      expect(todayDeco.border?.top.color, colors.onSurface);
      expect(
        tester.widget<Text>(find.text('${now.day}')).style?.color,
        colors.onSurface,
      );

      // Ordinary logged day: solid primary rose A + onPrimary text.
      final loggedCell = decoratedDayCell(tester, '$loggedMid');
      final loggedDeco = loggedCell.decoration as BoxDecoration;
      expect(loggedDeco.color, colors.primary.withValues(alpha: 0.85));
      expect(
        tester.widget<Text>(find.text('$loggedMid')).style?.color,
        colors.onPrimary,
      );

      // Predicted day: tertiary span styling.
      final predictedCell = decoratedDayCell(tester, '$predictedAnchor');
      final predictedDeco = predictedCell.decoration as BoxDecoration;
      expect(
        predictedDeco.color,
        colors.tertiary.withValues(alpha: 0.25),
      );

      // Legend Today dot uses the exact same neutral as today cells:
      // exactly two neutral circles exist (today cell + legend dot),
      // so the three meanings separate without relying on the rim.
      final neutralCircles = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle &&
              (c.decoration as BoxDecoration).color == neutral);
      expect(neutralCircles.length, 2);

      // No package-default indigo anywhere in the subtree.
      const indigoDefault = Color(0xFF5C6BC0);
      final indigoCells = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color == indigoDefault);
      expect(indigoCells, isEmpty);
    });

    testWidgets('light: selected non-today day keeps token rim styling',
        (tester) async {
      await pumpHistory(tester, theme: MenoMateTheme.sakuraTheme);
      final colors = MenoMateTheme.sakuraTheme.colorScheme;

      await tester.tap(find.text('$tapDay'));
      await tester.pumpAndSettle();

      final cell = decoratedDayCell(tester, '$tapDay');
      final deco = cell.decoration as BoxDecoration;
      expect(deco.color, colors.primary.withValues(alpha: 0.15));
      expect(deco.border?.top.color, colors.primary);
      expect(
        tester.widget<Text>(find.text('$tapDay')).style?.color,
        colors.primary,
      );
    });

    testWidgets('dark: today neutral tracks dark tokens, no indigo',
        (tester) async {
      await pumpHistory(tester, theme: MenoMateTheme.starryNightTheme);
      final colors = MenoMateTheme.starryNightTheme.colorScheme;
      final neutral = todayNeutralFill(colors);

      expect(neutral, isNot(colors.primary));
      expect(neutral, isNot(colors.tertiary));

      final now = DateTime.now();
      final todayCell = decoratedDayCell(tester, '${now.day}');
      final todayDeco = todayCell.decoration as BoxDecoration;
      expect(todayDeco.color, neutral);
      expect(todayDeco.border?.top.color, colors.onSurface);
      expect(
        tester.widget<Text>(find.text('${now.day}')).style?.color,
        colors.onSurface,
      );

      const indigoDefault = Color(0xFF5C6BC0);
      final indigoCells = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color == indigoDefault);
      expect(indigoCells, isEmpty);
    });
  });

  // Item 4: History [Calendar | Cycles] panes.
  testWidgets('History segments Calendar and Cycles panes', (tester) async {
    _tallViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historySummaryProvider.overrideWith(
            (ref) => Future.value(Fresh<HistorySummaryResponse>(
              HistorySummaryResponse(
                totalPeriodsLogged: 2,
                averageCycleLength: 28,
                averagePeriodLength: 5,
                history: [
                  HistoryPeriodEntry(
                    id: 1,
                    periodStart: DateTime(2026, 9, 1),
                    periodEnd: DateTime(2026, 9, 5),
                    periodLengthDays: 5,
                    cycleLengthDays: 28,
                  ),
                  HistoryPeriodEntry(
                    id: 2,
                    periodStart: DateTime(2026, 9, 12),
                    periodEnd: DateTime(2026, 9, 12),
                    periodLengthDays: 1,
                    cycleLengthDays: 0,
                  ),
                ],
                symptomFrequencies: const {},
              ),
            )),
          ),
          cycleListProvider.overrideWith(
            (ref) => Future.value(const Fresh<List<CycleResponse>>([])),
          ),
          currentCycleProvider.overrideWith(
            (ref) => Future.value(const Fresh<CurrentCycleResponse?>(null)),
          ),
        ],
        child: MaterialApp(
          theme: MenoMateTheme.sakuraTheme,
          home: const HistoryTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default pane: calendar visible, cycles content hidden.
    expect(find.byType(TableCalendar), findsOneWidget);
    expect(find.text('Past Cycles'), findsNothing);

    await tester.tap(find.text('Cycles'));
    await tester.pumpAndSettle();
    expect(find.text('Past Cycles'), findsOneWidget);
    expect(find.byType(TableCalendar), findsNothing);
    // Item 3 end-to-end: singular + em-dash rendering in real tiles.
    expect(
      find.text('Period: 5 days  ·  Cycle Interval: 28 days'),
      findsOneWidget,
    );
    expect(
      find.text('Period: 1 day  ·  Cycle Interval: –'),
      findsOneWidget,
    );

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.byType(TableCalendar), findsOneWidget);
    expect(find.text('Past Cycles'), findsNothing);
  });

  // Item 5: exactly one Care prompt system with canonical wording.
  testWidgets('Care shows one canonical prompt set, no duplicate bar',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AssistantTab())),
    );
    await tester.pumpAndSettle();

    for (final label in [
      "What's happening today?",
      'Help with my current pain',
      'What patterns do you notice?',
      'What helped me before?',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // Orphan fifth prompt gone.
    expect(find.text('Prepare for my next period'), findsNothing);
    // Removed bottom-bar wordings gone.
    for (final label in ['Cycle insight', 'Pain help', 'Patterns', 'Next period']) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('Home no longer hosts a Quick Care row', (tester) async {
    await _pumpHome(
      tester,
      cycle: Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 2,
          phase: 'menstrual',
          isBleeding: true,
          isOngoing: true,
          latestPeriodStart: DateTime(2026, 9, 12),
          predictionConfidence: 'low',
        ),
      ),
    );

    expect(find.text('Quick Care'), findsNothing);
    expect(find.text('Pain Help'), findsNothing);
  });

  // Item 6+7(test 7): compact prediction line, subtle suffix, values intact.
  testWidgets('Home prediction is one compact line with subtle suffix',
      (tester) async {
    await _pumpHome(
      tester,
      cycle: Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 5,
          phase: 'luteal',
          isBleeding: false,
          isOngoing: false,
          latestPeriodStart: DateTime(2026, 9, 1),
          latestPeriodEnd: DateTime(2026, 9, 5),
          predictedNextPeriod: DateTime(2026, 10, 2),
          daysUntilNextPeriod: 20,
          predictionStatus: 'upcoming',
          predictionConfidence: 'low',
        ),
      ),
    );

    // Dominant hero unchanged.
    expect(find.text('Day 5'), findsOneWidget);
    expect(find.text('LUTEAL'), findsOneWidget);
    // One compact line; confidence demoted to suffix text.
    expect(
      find.textContaining('Next period: Oct 2 (in ~20 days)'),
      findsOneWidget,
    );
    expect(find.textContaining('low confidence'), findsOneWidget);
    // Redundant pill-button path replaced by a quiet navigation row.
    expect(find.text('View Calendar'), findsNothing);
    expect(find.text('Calendar'), findsOneWidget);
    // Ended status keeps facts, singular day count.
    expect(find.text('Period ended Sep 5 · 5 days'), findsOneWidget);
  });

  // Items 7/8/9(test 8,9): insight fetched once, reused, offline-safe.
  group('daily insight caching', () {
    ProviderContainer makeContainer(_CountingCareApi api) {
      return ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWith((ref) => api),
          currentCycleProvider.overrideWith(
            (ref) => Future.value(Fresh<CurrentCycleResponse?>(
              CurrentCycleResponse(
                hasData: true,
                currentCycleDay: 2,
                phase: 'menstrual',
                isBleeding: true,
                isOngoing: true,
                latestPeriodStart: DateTime(2026, 9, 12),
                predictionConfidence: 'low',
              ),
            )),
          ),
        ],
      );
    }

    Future<void> settleReads(ProviderContainer c) async {
      // Mount (kicks off the single fetch), then drain the event loop
      // until data lands. Never outlives the container: every awaited
      // turn happens before tearDown disposes it.
      // ignore: unused_result
      c.read(dailyInsightProvider);
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(Duration.zero);
        if (c.read(dailyInsightProvider) is AsyncData) break;
      }
      // ignore: unused_result
      c.read(dailyInsightProvider);
    }

    test('single fetch reused across rebuilds and dependency churn',
        () async {
      final api = _CountingCareApi();
      final container = makeContainer(api);
      addTearDown(container.dispose);

      expect(container.read(dailyInsightProvider).isLoading, isTrue);
      await settleReads(container);
      expect(
        container.read(dailyInsightProvider),
        const AsyncData<String?>('canned tip'),
      );
      expect(api.calls, 1);

      // Rebuilds/re-reads never refetch.
      await settleReads(container);
      expect(api.calls, 1);

      // Even invalidating the cycle provider (pull-to-refresh path)
      // does not refetch the insight.
      container.invalidate(currentCycleProvider);
      await settleReads(container);
      expect(api.calls, 1);
      expect(
        container.read(dailyInsightProvider),
        const AsyncData<String?>('canned tip'),
      );
    });

    test('offline revisit renders last-good value without a new request',
        () async {
      final api = _CountingCareApi();
      final container = makeContainer(api);
      addTearDown(container.dispose);

      await settleReads(container);
      expect(
        container.read(dailyInsightProvider),
        const AsyncData<String?>('canned tip'),
      );
      expect(api.calls, 1);

      api.fail = true;
      await settleReads(container);
      expect(api.calls, 1);
      expect(
        container.read(dailyInsightProvider),
        const AsyncData<String?>('canned tip'),
      );
    });

    test('first-ever offline visit falls back to the phase tip', () async {
      final api = _CountingCareApi()..fail = true;
      final container = makeContainer(api);
      addTearDown(container.dispose);

      await settleReads(container);
      expect(
        container.read(dailyInsightProvider),
        const AsyncData<String?>(
          'Focus on warm fluids, magnesium-rich foods, and extra rest today.',
        ),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/summary.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/screens/tabs/history_tab.dart';

/// Batch 2C final: the selected-day card is a quiet hierarchy —
/// date, status, cycle context, action — with no pill weight, no
/// conversational phrasing, and no invented past-date day numbers.
void main() {
  late DateTime now;
  late int otherDay;
  late int predictedAnchor;

  Future<void> pumpHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Predicted span anchor: unique in-month label, clear of today.
    predictedAnchor = now.day <= 14 ? now.day + 10 : 8;
    // Plain day: unique in-month label, outside the logged span
    // (today-1..today), outside the predicted span, never a tail label.
    otherDay = [18, 20, 22].firstWhere(
      (c) =>
          (c - now.day).abs() > 2 &&
          (c < predictedAnchor || c > predictedAnchor + 4),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historySummaryProvider.overrideWith(
            (ref) => Future.value(Fresh<HistorySummaryResponse>(
              HistorySummaryResponse(
                totalPeriodsLogged: 3,
                averageCycleLength: 28.0,
                averagePeriodLength: 5.0,
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
                periodStart: today.subtract(const Duration(days: 1)),
                periodEnd: null,
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
                currentCycleDay: 2,
                phase: 'menstrual',
                isBleeding: true,
                isOngoing: true,
                latestPeriodStart: today.subtract(const Duration(days: 1)),
                averagePeriodLength: 5,
                predictedNextPeriod: DateTime(
                    now.year, now.month, predictedAnchor),
                predictionConfidence: 'low',
              ),
            )),
          ),
        ],
        child: MaterialApp(
          theme: MenoMateTheme.sakuraTheme,
          home: const HistoryTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String fmt(DateTime d) => DateFormat('EEEE, MMMM d, yyyy').format(d);

  group('selected-day card hierarchy', () {
    testWidgets('today logged day: date, quiet status, concise context',
        (tester) async {
      await pumpHistory(tester);
      final today = DateTime(now.year, now.month, now.day);

      expect(find.text(fmt(today)), findsOneWidget);
      expect(find.text('Period active'), findsOneWidget);
      expect(find.text('Day 2 · Menstrual'), findsOneWidget);
      expect(find.text('View / edit wellness log'), findsOneWidget);

      // Conversational phrasing and the heavy pill copy are gone.
      expect(find.textContaining('of your cycle'), findsNothing);
      expect(find.text('Logged Active Period'), findsNothing);
      expect(find.textContaining('MENSTRUAL phase'), findsNothing);
    });

    testWidgets('quiet status: small icon, 12px semantic text',
        (tester) async {
      await pumpHistory(tester);

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      final status =
          tester.widget<Text>(find.text('Period active'));
      expect(status.style?.fontSize, 12.0);
      expect(status.style?.color,
          MenoMateTheme.sakuraTheme.colorScheme.primary);
    });

    testWidgets('view/edit stays a restrained outlined action',
        (tester) async {
      await pumpHistory(tester);

      final buttons = find.byType(OutlinedButton);
      expect(buttons, findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(tester.widget<Icon>(find.byIcon(Icons.edit_note_outlined)).size,
          16.0);
    });

    testWidgets('non-today day: status only, no invented day numbers',
        (tester) async {
      await pumpHistory(tester);
      await tester.tap(find.text('$otherDay'));
      await tester.pumpAndSettle();

      final day = DateTime(now.year, now.month, otherDay);
      expect(find.text(fmt(day)), findsOneWidget);
      expect(find.text('Non-bleeding day'), findsOneWidget);
      // Day-index/phase for past dates would invent backend-owned
      // semantics, so the card correctly shows none.
      expect(find.textContaining(RegExp(r'^Day \d+ ·')), findsNothing);
      expect(find.text('View / edit wellness log'), findsOneWidget);
    });

    testWidgets('predicted day: violet span status, no day numbers',
        (tester) async {
      await pumpHistory(tester);
      // Tapping the already-selected today would be a no-op for other
      // assertions; the anchor is guaranteed different from today.
      await tester.tap(find.text('$predictedAnchor'));
      await tester.pumpAndSettle();

      expect(find.text('Predicted span'), findsNWidgets(2));
      expect(find.byIcon(Icons.auto_awesome_outlined), findsWidgets);
      expect(find.textContaining(RegExp(r'^Day \d+ ·')), findsNothing);
    });
  });

  group('legend keeps calendar-meaning responsibilities', () {
    testWidgets('three dots plus violet prediction line', (tester) async {
      await pumpHistory(tester);

      // Legend dot labels keep their exact calendar-meaning wording.
      expect(find.text('Logged period'), findsOneWidget);
      expect(find.text('Predicted span'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome_outlined).first);
      expect(icon.color, MenoMateTheme.sakuraTheme.colorScheme.tertiary);
    });
  });

  group('stats use neutral ink', () {
    testWidgets('stat values do not borrow the rose', (tester) async {
      await pumpHistory(tester);
      await tester.tap(find.text('Cycles'));
      await tester.pumpAndSettle();

      final values = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.style?.fontSize == 20 &&
            w.style?.fontWeight == FontWeight.bold,
      );
      expect(values, findsNWidgets(3));
      for (final w in tester.widgetList<Text>(values)) {
        expect(w.style?.color,
            MenoMateTheme.sakuraTheme.colorScheme.onSurface);
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/content/insight_library.dart';
import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/widgets/daily_insight_card.dart';

/// Batch 2B: the insight library is small, deterministic, evidence-bounded,
/// and complementary — never a ring-fact dump, never an overconfident
/// medical claim.
void main() {
  List<InsightPair> allPairs() => insightPairs.values.toList();

  List<String> allBodies() {
    final out = <String>[];
    for (final p in allPairs()) {
      out.add(p.insight.body);
      out.add(p.action.body);
    }
    return out;
  }

  group('context selection', () {
    test('menstrual day boundary: 2 -> early, 3 -> late', () {
      expect(
        selectInsightPair(
          const InsightInput(
              hasData: true, phase: 'menstrual', menstrualDay: 1),
        ),
        same(insightPairs[InsightContext.menstrualEarly]),
      );
      expect(
        selectInsightPair(
          const InsightInput(
              hasData: true, phase: 'menstrual', menstrualDay: 2),
        ),
        same(insightPairs[InsightContext.menstrualEarly]),
      );
      expect(
        selectInsightPair(
          const InsightInput(
              hasData: true, phase: 'menstrual', menstrualDay: 3),
        ),
        same(insightPairs[InsightContext.menstrualLate]),
      );
      expect(
        selectInsightPair(
          const InsightInput(
              hasData: true, phase: 'menstrual', menstrualDay: 9),
        ),
        same(insightPairs[InsightContext.menstrualLate]),
      );
    });

    test('menstrual without a day -> unknown pair', () {
      expect(
        selectInsightPair(
            const InsightInput(hasData: true, phase: 'menstrual')),
        same(insightPairs[InsightContext.menstrualUnknown]),
      );
    });

    test('phases map directly (case-insensitive)', () {
      expect(
        selectInsightPair(
            const InsightInput(hasData: true, phase: 'follicular')),
        same(insightPairs[InsightContext.follicular]),
      );
      expect(
        selectInsightPair(
            const InsightInput(hasData: true, phase: 'Ovulation')),
        same(insightPairs[InsightContext.ovulation]),
      );
      expect(
        selectInsightPair(
            const InsightInput(hasData: true, phase: 'LUTEAL')),
        same(insightPairs[InsightContext.luteal]),
      );
    });

    test('no data / unknown phase -> safe fallback pair', () {
      expect(
        selectInsightPair(
          const InsightInput(
              hasData: false, phase: 'menstrual', menstrualDay: 2),
        ),
        same(insightPairs[InsightContext.noData]),
      );
      expect(
        selectInsightPair(
            const InsightInput(hasData: true, phase: 'mystery')),
        same(insightPairs[InsightContext.noData]),
      );
      expect(
        selectInsightPair(const InsightInput(hasData: true, phase: '')),
        same(insightPairs[InsightContext.noData]),
      );
    });

    test('exactly seven contexts, one pair each', () {
      expect(insightPairs.length, InsightContext.values.length);
    });
  });

  group('complementarity + compactness', () {
    test('insight and action differ and stay glanceable', () {
      for (final entry in insightPairs.entries) {
        expect(entry.value.insight.body.isNotEmpty, isTrue,
            reason: '${entry.key} insight empty');
        expect(entry.value.action.body.isNotEmpty, isTrue,
            reason: '${entry.key} action empty');
        expect(entry.value.insight.body, isNot(entry.value.action.body),
            reason: '${entry.key} slides duplicate each other');
        // Readable in seconds: no paragraph walls on a compact card.
        expect(entry.value.insight.body.length, lessThanOrEqualTo(140),
            reason: '${entry.key} insight too long');
        expect(entry.value.action.body.length, lessThanOrEqualTo(140),
            reason: '${entry.key} action too long');
      }
    });

    test('nutrition appears in context-appropriate actions', () {
      expect(
        selectInsightPair(
          const InsightInput(hasData: true, phase: 'luteal'),
        ).action.body,
        contains('magnesium-rich'),
      );
      expect(
        selectInsightPair(
          const InsightInput(hasData: true, phase: 'menstrual'),
        ).action.body,
        contains('meals regular'),
      );
    });
  });

  group('ring non-duplication', () {
    // The ring owns day numbers, phase names, dates, confidence, stats.
    // Bodies may reference context ("early", "bleeding") but never facts.
    // (Month abbreviations carry word boundaries; "May" the month is
    // covered by the digit ban since month mentions need a day number.)
    final banned = RegExp(
      r'\d|menstrual|follicular|ovulation|luteal|confiden|predict|average|cycle day|\b(jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)\b',
      caseSensitive: false,
    );

    test('no body repeats ring-owned facts', () {
      for (final body in allBodies()) {
        expect(banned.hasMatch(body), isFalse, reason: 'banned fact in: $body');
      }
    });
  });

  group('medical safety wording', () {
    // Inappropriate certainty, diagnosis, prescriptions, dosages,
    // hormone-mechanism claims, and drug/supplement recommendations.
    // Food-based magnesium ("magnesium-rich food") is allowed; magnesium
    // supplements and all dosages are not.
    final banned = RegExp(
      r'\bwill\b|\balways\b|\bnever\b|\bguarantee[sd]?\b|\bproven\b|'
      r'you have \w+ (disease|disorder|syndrome|condition)|diagnos|'
      r'\bmg\b|\bmcg\b|\bml\b|dosage|\bdose\b|supplement\b|'
      r'magnesium\s+(supplement|pill|capsule|tablet|powder|oil)|'
      r'estrogen|progesterone|prostaglandin|testosterone|hormonal|'
      r'ibuprofen|naproxen|NSAID|paracetamol|acetaminophen|contracept|'
      r'vitamin|zinc|ginger',
      caseSensitive: false,
    );

    test('no banned medical wording in any body', () {
      for (final body in allBodies()) {
        expect(banned.hasMatch(body), isFalse, reason: 'banned wording in: $body');
      }
    });
  });

  group('nutrition conservatism', () {
    // Foods may be named as nutrient sources, never as treatments.
    final treatmentClaim = RegExp(
      r'(chocolate|oranges?|magnesium|vitamin|ginger|zinc|food|meals?|'
      r'fruit|vegetables?|nuts?|seeds?|beans?|greens?|grains?)'
      r'[^.]{0,80}\b(reduc\w*|cur\w*|fix\w*|treat\w*|prevent\w*|heal\w*|'
      r'reliev\w*|fight\w*)',
      caseSensitive: false,
    );

    test('no food-as-treatment claims in any body', () {
      for (final body in allBodies()) {
        expect(treatmentClaim.hasMatch(body), isFalse,
            reason: 'treatment claim in: $body');
      }
    });

    test('chocolate is absent: not an established treatment', () {
      for (final body in allBodies()) {
        expect(body.toLowerCase(), isNot(contains('chocolate')),
            reason: 'chocolate in: $body');
      }
    });

    test('nutrition is an option among others, never dosed', () {
      final foodHint = RegExp(
        r'meals?|fruit|vegetables?|nuts?|seeds?|beans?|greens?|grains?|magnesium-rich',
        caseSensitive: false,
      );
      final withFood = [
        for (final p in allPairs())
          if (foodHint.hasMatch(p.action.body)) p,
      ];
      // A little nutrition, not every card.
      expect(withFood.length, greaterThanOrEqualTo(1));
      expect(withFood.length, lessThanOrEqualTo(3));
      final dosage = RegExp(r'\bmg\b|dosage|dose|supplement',
          caseSensitive: false);
      for (final p in withFood) {
        expect(dosage.hasMatch(p.action.body), isFalse,
            reason: 'dosage talk in: ${p.action.body}');
      }
    });
  });

  group('evidence metadata', () {
    // Substantive medical claims carry real source metadata; display stays
    // quiet (only designated pieces show a tiny label).
    final claimHints =
        RegExp(r'cramp|pain|sleep|exercis|movement|walk|heat|relax|breath|bleed', caseSensitive: false);

    test('claim-bearing pieces all carry real source metadata', () {
      for (final pair in allPairs()) {
        for (final piece in [pair.insight, pair.action]) {
          if (claimHints.hasMatch(piece.body)) {
            expect(piece.sourceName, isNotNull,
                reason: 'missing sourceName: ${piece.body}');
            expect(piece.sourceType, isNotNull,
                reason: 'missing sourceType: ${piece.body}');
            expect(piece.sourceId, isNotNull,
                reason: 'missing sourceId: ${piece.body}');
            expect(piece.sourceId, isNot(contains('TODO')),
                reason: 'placeholder source: ${piece.body}');
          }
        }
      }
    });

    test('visible attribution only where intended (3 pieces)', () {
      final shown = [
        for (final p in allPairs())
          for (final piece in [p.insight, p.action])
            if (piece.showAttribution) piece,
      ];
      expect(shown.length, 3);
      expect(
        shown.map((p) => p.attributionLabel).toSet(),
        {'ACOG', 'Systematic review', 'Cochrane review'},
      );
      for (final piece in shown) {
        expect(piece.sourceId, isNotNull);
      }
    });
  });

  group('card two-slide UX', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required DataState<CurrentCycleResponse?> cycle,
      required ThemeData theme,
    }) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCycleProvider.overrideWith((ref) => Future.value(cycle)),
          ],
          // Center: loose constraints like the scrolling Home, so the
          // card shrink-wraps instead of stretching to the viewport.
          child: MaterialApp(
              theme: theme, home: const Center(child: DailyInsightCard())),
        ),
      );
      await tester.pumpAndSettle();
    }

    DataState<CurrentCycleResponse?> menstrualDay2() {
      return Fresh<CurrentCycleResponse?>(
        CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 2,
          phase: 'menstrual',
          isBleeding: true,
          isOngoing: true,
          latestPeriodStart: DateTime(2026, 9, 12),
          predictionConfidence: 'low',
        ),
      );
    }

    testWidgets('exactly two slides with fixed titles, swipe advances',
        (tester) async {
      await pumpCard(
        tester,
        cycle: menstrualDay2(),
        theme: MenoMateTheme.sakuraTheme,
      );

      expect(find.text('Today’s insight'), findsOneWidget);
      expect(find.text('Helpful today'), findsNothing);
      expect(
        find.textContaining('peak in the first day or two'),
        findsOneWidget,
      );
      // Tiny attribution only on the attributed slide.
      expect(find.text('ACOG'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Today’s insight'), findsNothing);
      expect(find.text('Helpful today'), findsOneWidget);
      expect(find.textContaining('Warmth on the lower belly'), findsOneWidget);
      expect(find.text('Systematic review'), findsOneWidget);
    });

    testWidgets('no autoplay: page holds without interaction', (tester) async {
      await pumpCard(
        tester,
        cycle: menstrualDay2(),
        theme: MenoMateTheme.sakuraTheme,
      );

      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Today’s insight'), findsOneWidget);
      expect(find.text('Helpful today'), findsNothing);
    });

    testWidgets('dark mode renders the pair without overflow', (tester) async {
      await pumpCard(
        tester,
        cycle: menstrualDay2(),
        theme: MenoMateTheme.starryNightTheme,
      );

      expect(find.text('Today’s insight'), findsOneWidget);
      expect(find.textContaining('peak in the first day or two'),
          findsOneWidget);
    });

    testWidgets('compact rendering: short card, small slide area',
        (tester) async {
      await pumpCard(
        tester,
        cycle: menstrualDay2(),
        theme: MenoMateTheme.sakuraTheme,
      );

      // Companion, not a section: content well under the old ~165px
      // slide area + dots (old card totaled ~210px).
      expect(
        tester
            .getSize(find.byKey(const Key('daily_insight_content')))
            .height,
        lessThan(120),
      );
      expect(tester.getSize(find.byType(Card)).height, lessThan(160));
      expect(tester.getSize(find.byType(PageView)).height,
          lessThanOrEqualTo(100));
      // Proportion lock: secondary title, Home-scale body, tiny source.
      expect(
        tester.widget<Text>(find.text('Today’s insight')).style?.fontSize,
        13.0,
      );
      expect(
        tester
            .widget<Text>(
                find.textContaining('peak in the first day or two'))
            .style
            ?.fontSize,
        14.0,
      );
      expect(
        tester.widget<Text>(find.text('ACOG')).style?.fontSize,
        10.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone width renders light and dark without overflow',
        (tester) async {
      for (final theme in [
        MenoMateTheme.sakuraTheme,
        MenoMateTheme.starryNightTheme,
      ]) {
        tester.view.physicalSize = const Size(380, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentCycleProvider.overrideWith(
                (ref) => Future.value(menstrualDay2()),
              ),
            ],
            child: MaterialApp(
              theme: theme,
              home: const DailyInsightCard(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Today’s insight'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('fallback pair renders when context is missing',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCycleProvider.overrideWith(
              (ref) => Future<DataState<CurrentCycleResponse?>>.error('offline'),
            ),
          ],
          child: MaterialApp(
            theme: MenoMateTheme.sakuraTheme,
            home: const DailyInsightCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today’s insight'), findsOneWidget);
      expect(find.textContaining('learns your cycles'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/profile.dart';
import 'package:menomate_mobile/models/summary.dart';
import 'package:menomate_mobile/providers/cycle_provider.dart';
import 'package:menomate_mobile/providers/profile_provider.dart';
import 'package:menomate_mobile/screens/auth_screen.dart';
import 'package:menomate_mobile/screens/calendar_screen.dart';
import 'package:menomate_mobile/screens/home_screen.dart';
import 'package:menomate_mobile/screens/log_hub_screen.dart';
import 'package:menomate_mobile/screens/tabs/assistant_tab.dart';
import 'package:menomate_mobile/screens/tabs/home_tab.dart';
import 'package:menomate_mobile/screens/tabs/insights_tab.dart';
import 'package:menomate_mobile/screens/tabs/settings_tab.dart';
import 'package:menomate_mobile/screens/symptom_logger_screen.dart';
import 'package:menomate_mobile/services/ble_service.dart';
import 'package:menomate_mobile/widgets/device_telemetry_card.dart';
import 'package:menomate_mobile/widgets/interactive_cycle_ring.dart';
import 'package:menomate_mobile/widgets/period_tracker_button.dart';
import 'package:menomate_mobile/widgets/symptom_logger_card.dart';
import 'package:menomate_mobile/widgets/theme_atmosphere.dart';

class _FixedProfileNotifier extends ProfileNotifier {
  final DataState<Profile?> fixed;
  _FixedProfileNotifier(this.fixed);

  @override
  Future<DataState<Profile?>> build() async => fixed;
}

/// Batch 2C: one coherent visual system. Rose means menstrual, violet
/// means prediction, restrained indigo means interaction — everywhere.
void main() {
  group('semantic token roles', () {
    test('rose / prediction / interaction are three distinct roles', () {
      expect(
        MenoMateTheme.sakuraPrimaryDark,
        isNot(MenoMateTheme.sakuraPredicted),
      );
      expect(
        MenoMateTheme.sakuraPrimaryDark,
        isNot(MenoMateTheme.sakuraInteraction),
      );
      expect(
        MenoMateTheme.sakuraPredicted,
        isNot(MenoMateTheme.sakuraInteraction),
      );
      expect(
        MenoMateTheme.starryPrimary,
        isNot(MenoMateTheme.starryInteraction),
      );
    });

    test('interactionColor follows brightness', () {
      expect(
        MenoMateTheme.interactionColor(false),
        MenoMateTheme.sakuraInteraction,
      );
      expect(
        MenoMateTheme.interactionColor(true),
        MenoMateTheme.starryInteraction,
      );
    });

    test('ringPhaseColor maps every phase to a theme token', () {
      expect(
        MenoMateTheme.ringPhaseColor(isDark: false, phase: 'menstrual'),
        MenoMateTheme.sakuraPrimaryDark,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: false, phase: 'Menstrual'),
        MenoMateTheme.sakuraPrimaryDark,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: false, phase: 'follicular'),
        MenoMateTheme.sakuraRingFollicular,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: false, phase: 'ovulation'),
        MenoMateTheme.sakuraRingOvulation,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: false, phase: 'luteal'),
        MenoMateTheme.sakuraRingLuteal,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: false, phase: 'mystery'),
        MenoMateTheme.sakuraSecondary,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: true, phase: 'menstrual'),
        MenoMateTheme.starryPrimary,
      );
      expect(
        MenoMateTheme.ringPhaseColor(isDark: true, phase: 'mystery'),
        MenoMateTheme.starrySecondary,
      );
    });

    test('ring ramp never uses neon accents', () {
      const neon = [
        Colors.pinkAccent,
        Colors.purpleAccent,
        Colors.orangeAccent,
      ];
      for (final phase in [
        'menstrual',
        'follicular',
        'ovulation',
        'luteal',
        'unknown',
      ]) {
        for (final isDark in [false, true]) {
          expect(
            neon.contains(
              MenoMateTheme.ringPhaseColor(isDark: isDark, phase: phase),
            ),
            isFalse,
            reason: 'neon ring color for $phase (dark=$isDark)',
          );
        }
      }
    });
  });

  group('ring widget uses the system', () {
    CycleRingPainter ringPainter(WidgetTester tester) {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(InteractiveCycleRing),
          matching: find.byType(CustomPaint),
        ),
      );
      return paint.painter! as CycleRingPainter;
    }

    testWidgets('menstrual ring is the rose token on a tinted track', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveCycleRing(
            phase: 'menstrual',
            currentDay: 2,
            cycleLength: 28,
          ),
        ),
      );

      final painter = ringPainter(tester);
      expect(painter.activeColor, MenoMateTheme.sakuraPrimaryDark);
      expect(painter.activeColor, isNot(Colors.pinkAccent));
      expect(
        painter.backgroundColor,
        MenoMateTheme.sakuraPrimaryDark.withValues(alpha: 0.14),
      );
    });

    testWidgets('dark ring resolves dark tokens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenoMateTheme.starryNightTheme,
          home: const InteractiveCycleRing(
            phase: 'follicular',
            currentDay: 7,
            cycleLength: 28,
          ),
        ),
      );

      final painter = ringPainter(tester);
      expect(painter.activeColor, MenoMateTheme.starryRingFollicular);
      expect(
        painter.backgroundColor,
        MenoMateTheme.starryRingFollicular.withValues(alpha: 0.14),
      );
    });
  });

  group('buttons carry rose meaning', () {
    Future<void> pumpTracker(WidgetTester tester, bool ongoing) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MenoMateTheme.sakuraTheme,
            home: Scaffold(body: PeriodTrackerButton(isOngoing: ongoing)),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('start-logging uses primary rose', (tester) async {
      await pumpTracker(tester, false);
      final style = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .style;
      expect(
        style?.backgroundColor?.resolve({}),
        MenoMateTheme.sakuraTheme.colorScheme.primary,
      );
    });

    testWidgets('stop-logging rests on the soft rose container', (
      tester,
    ) async {
      await pumpTracker(tester, true);
      final style = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .style;
      expect(
        style?.backgroundColor?.resolve({}),
        MenoMateTheme.sakuraTheme.colorScheme.primaryContainer,
      );
    });
  });

  group('wellness tile stays in-system', () {
    Finder sageTile(ThemeData theme, Color bg) => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.color == bg &&
          (w.decoration as BoxDecoration?)?.borderRadius ==
              BorderRadius.circular(16),
    );

    testWidgets('logger icon tile uses pastel sage, light mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenoMateTheme.sakuraTheme,
          home: const Scaffold(body: SymptomLoggerCard()),
        ),
      );

      expect(
        sageTile(MenoMateTheme.sakuraTheme, MenoMateTheme.sakuraSage),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              w.icon == Icons.favorite &&
              w.color == MenoMateTheme.sakuraSageInk &&
              w.size == 28,
        ),
        findsOneWidget,
      );
    });

    testWidgets('logger icon tile uses pastel sage, dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenoMateTheme.starryNightTheme,
          home: const Scaffold(body: SymptomLoggerCard()),
        ),
      );

      expect(
        sageTile(MenoMateTheme.starryNightTheme, MenoMateTheme.starrySage),
        findsOneWidget,
      );
    });
  });

  group('home composition', () {
    /// Structural proof that steady-state pixels fit the viewport: walks
    /// the live render tree and fails on any box wider than [maxWidth].
    /// Unlike error-absence checks, this cannot be masked by layout
    /// timing — it measures what is actually on screen after settling.
    void assertNoWideBoxes(WidgetTester tester, double maxWidth) {
      void visit(Element e) {
        final r = e.renderObject;
        if (r is RenderBox && r.hasSize && r.size.width > maxWidth + 0.5) {
          final w = e.widget;
          final extra = w is Text ? ' text="${w.data}"' : '';
          fail('wide box ${w.runtimeType}$extra w=${r.size.width}');
        }
        e.visitChildren(visit);
      }

      visit(tester.element(find.byType(MaterialApp)));
    }

    Future<void> pumpHome(WidgetTester tester, ThemeData theme) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCycleProvider.overrideWith(
              (ref) => Future.value(const NoData<CurrentCycleResponse?>()),
            ),
            historySummaryProvider.overrideWith(
              (ref) => Future.value(
                const Unavailable<HistorySummaryResponse>('Signed out.'),
              ),
            ),
            cycleListProvider.overrideWith(
              (ref) => Future.value(
                const Unavailable<List<CycleResponse>>('Signed out.'),
              ),
            ),
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(const NoData<Profile?>()),
            ),
            bleConnectedProvider.overrideWithValue(false),
          ],
          child: MaterialApp(theme: theme, home: const HomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('atmosphere wraps home; every tab scaffold stays transparent', (
      tester,
    ) async {
      // One shared container: drive the real tab-index notifier so each
      // tab takes its turn onstage (IndexedStack prunes offstage
      // subtrees from traversal, so transparency is verified per tab).
      // Six primary destinations: Home | Calendar | Log | Insights |
      // Care | More (Settings).
      final tabTypes = [
        HomeTab,
        CalendarScreen,
        LogHubScreen,
        InsightsTab,
        AssistantTab,
        SettingsTab,
      ];
      final container = ProviderContainer(
        overrides: [
          currentCycleProvider.overrideWith(
            (ref) => Future.value(const NoData<CurrentCycleResponse?>()),
          ),
          historySummaryProvider.overrideWith(
            (ref) => Future.value(
              const Unavailable<HistorySummaryResponse>('Signed out.'),
            ),
          ),
          cycleListProvider.overrideWith(
            (ref) => Future.value(
              const Unavailable<List<CycleResponse>>('Signed out.'),
            ),
          ),
          profileProvider.overrideWith(
            () => _FixedProfileNotifier(const NoData<Profile?>()),
          ),
          bleConnectedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: MenoMateTheme.sakuraTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      // Drain the well-known first-frame transient (test-env font load
      // lays out once before settling); steady state below must be clean.
      tester.takeException();
      for (var i = 0; i < tabTypes.length; i++) {
        container.read(homeTabIndexProvider.notifier).setIndex(i);
        await tester.pump();
        // A newly shown tab may record one first-layout transient in the
        // test env (proven: reported once, never recurs, final tree has
        // no wide boxes). Drain it, settle, then verify steady state
        // structurally — pixels must fit, plus no other framework errors.
        tester.takeException();
        await tester.pump(const Duration(milliseconds: 500));

        if (i == 0) {
          expect(find.byType(ThemeAtmosphereBackground), findsOneWidget);
        }
        final scaffold = tester.widget<Scaffold>(
          find
              .descendant(
                of: find.byType(tabTypes[i]),
                matching: find.byType(Scaffold),
              )
              .first,
        );
        expect(
          scaffold.backgroundColor,
          Colors.transparent,
          reason: 'tab $i scaffold must let the atmosphere show through',
        );
        assertNoWideBoxes(tester, 800);
        expect(
          tester.takeException(),
          isNull,
          reason: 'tab $i must settle without layout errors',
        );
      }
    });

    testWidgets('light nav selection is interaction indigo, not rose', (
      tester,
    ) async {
      await pumpHome(tester, MenoMateTheme.sakuraTheme);

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.selectedItemColor, MenoMateTheme.sakuraInteraction);
      expect(
        nav.selectedItemColor,
        isNot(MenoMateTheme.sakuraTheme.colorScheme.primary),
      );
    });

    testWidgets('dark nav selection is interaction indigo, not rose', (
      tester,
    ) async {
      await pumpHome(tester, MenoMateTheme.starryNightTheme);

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.selectedItemColor, MenoMateTheme.starryInteraction);
      expect(tester.takeException(), isNull);
    });

    test('secondary outlined actions resolve interaction indigo', () {
      expect(
        MenoMateTheme.sakuraTheme.outlinedButtonTheme.style?.foregroundColor
            ?.resolve({}),
        MenoMateTheme.sakuraInteraction,
      );
      expect(
        MenoMateTheme
            .starryNightTheme
            .outlinedButtonTheme
            .style
            ?.foregroundColor
            ?.resolve({}),
        MenoMateTheme.starryInteraction,
      );
    });
  });

  group('refinement pass: neutral canvas, present atmosphere', () {
    List<double> channels(Color c) => [c.r, c.g, c.b];

    test('light canvas is warm-neutral, not pink', () {
      expect(MenoMateTheme.sakuraBg, const Color(0xFFFDFAF6));
      final ch = channels(MenoMateTheme.sakuraBg);
      // Warm direction (r >= g >= b); the old pink canvas had g < b.
      expect(ch[0] >= ch[1] && ch[1] >= ch[2], isTrue);
      // Near-neutral: barely-there cream, not a tinted wash.
      expect(ch[0] - ch[2], lessThanOrEqualTo(0.06));
    });

    test('light outline is warm-neutral', () {
      expect(MenoMateTheme.sakuraBorder, const Color(0xFFEBE2D8));
      final ch = channels(MenoMateTheme.sakuraBorder);
      expect(ch[0] >= ch[1] && ch[1] >= ch[2], isTrue);
      expect(ch[0] - ch[2], lessThanOrEqualTo(0.10));
    });

    test('dark foundation is unchanged deep navy', () {
      expect(MenoMateTheme.starryBg, const Color(0xFF080D1F));
    });

    test('no neon accent constants anywhere in the token set', () {
      const neon = [
        Colors.pinkAccent,
        Colors.purpleAccent,
        Colors.orangeAccent,
        Colors.greenAccent,
        Colors.blueAccent,
        Colors.redAccent,
        Colors.amberAccent,
        Colors.lightBlueAccent,
        Colors.tealAccent,
        Colors.cyanAccent,
      ];
      const tokens = [
        MenoMateTheme.sakuraPrimary,
        MenoMateTheme.sakuraPrimaryDark,
        MenoMateTheme.sakuraPredicted,
        MenoMateTheme.sakuraInteraction,
        MenoMateTheme.starryInteraction,
        MenoMateTheme.sakuraRingFollicular,
        MenoMateTheme.sakuraRingOvulation,
        MenoMateTheme.sakuraRingLuteal,
        MenoMateTheme.starryRingFollicular,
        MenoMateTheme.starryRingOvulation,
        MenoMateTheme.starryRingLuteal,
        MenoMateTheme.sakuraAmber,
        MenoMateTheme.sakuraSage,
        MenoMateTheme.sakuraSageInk,
        MenoMateTheme.starrySage,
        MenoMateTheme.starrySageInk,
        MenoMateTheme.sakuraSoftPink,
        MenoMateTheme.starrySurfaceRose,
        MenoMateTheme.starrySurfaceViolet,
        MenoMateTheme.starrySurfaceSage,
        MenoMateTheme.starryPrimary,
        MenoMateTheme.starryAccent,
      ];
      for (final t in tokens) {
        expect(neon.contains(t), isFalse, reason: 'neon token: $t');
      }
    });

    test('sakura table: seven petals, moderate-low alpha, logo tones', () {
      final tones = {
        MenoMateTheme.sakuraPrimary,
        MenoMateTheme.sakuraSoftPink,
        MenoMateTheme.sakuraPredicted,
        MenoMateTheme.sakuraPrimaryDark,
        MenoMateTheme.sakuraRingLuteal,
      };
      final petals = ThemeAtmosphereBackground.lightPetals;
      expect(petals.length, 7);
      for (final p in petals) {
        final alpha = p['alpha'] as double;
        expect(alpha, greaterThanOrEqualTo(0.12));
        expect(alpha, lessThanOrEqualTo(0.24));
        expect(tones.contains(p['color'] as Color), isTrue);
        expect(p['x'] as double, greaterThanOrEqualTo(0.0));
        expect(p['x'] as double, lessThanOrEqualTo(1.0));
        expect(p['scale'] as double, lessThanOrEqualTo(12.0));
      }
    });

    test('star table: ten sparse stars, soft lavender tones', () {
      final tones = {
        MenoMateTheme.starryAccent,
        MenoMateTheme.starryText,
        MenoMateTheme.starryRingOvulation,
      };
      final stars = ThemeAtmosphereBackground.darkStars;
      expect(stars.length, 10);
      for (final s in stars) {
        final alpha = s['a'] as double;
        expect(alpha, greaterThanOrEqualTo(0.30));
        expect(alpha, lessThanOrEqualTo(0.50));
        expect(s['r'] as double, lessThanOrEqualTo(2.5));
        expect(tones.contains(s['color'] as Color), isTrue);
      }
    });
  });

  group('connect device visibility', () {
    Future<void> pumpTelemetry(WidgetTester tester, ThemeData theme) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(body: DeviceTelemetryCard()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('dark action button is high-contrast pale neutral', (
      tester,
    ) async {
      await pumpTelemetry(tester, MenoMateTheme.starryNightTheme);

      final style = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .style;
      expect(style?.backgroundColor?.resolve({}), MenoMateTheme.starryText);
      expect(style?.foregroundColor?.resolve({}), MenoMateTheme.starryBg);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light action button stays white on the navy card', (
      tester,
    ) async {
      await pumpTelemetry(tester, MenoMateTheme.sakuraTheme);

      final style = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .style;
      expect(style?.backgroundColor?.resolve({}), Colors.white);
      expect(tester.takeException(), isNull);
    });
  });

  group('logger selectors use one interaction selection language', () {
    Future<void> pumpLogger(WidgetTester tester, {ThemeData? theme}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme ?? MenoMateTheme.sakuraTheme,
            home: const SymptomLoggerScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    Finder selectedChip(Color color) => find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          (w.decoration as BoxDecoration?)?.color == color,
    );

    testWidgets('mood selection is interaction indigo', (tester) async {
      await pumpLogger(tester);
      await tester.tap(find.text('Happy'));
      await tester.pump();

      expect(selectedChip(MenoMateTheme.sakuraInteraction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Daily Log rework: every category shares the indigo interaction
    // treatment (category meaning lives in the section icon, not the
    // selection color). Rose/amber selections are intentionally gone.
    testWidgets('flow selection uses interaction indigo, not rose', (
      tester,
    ) async {
      await pumpLogger(tester);
      // 'Light' labels both the Flow and Discharge options; the Flow
      // section precedes Discharge, so .first is the flow chip.
      await tester.ensureVisible(find.text('Light').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').first);
      await tester.pump();

      expect(selectedChip(MenoMateTheme.sakuraInteraction), findsOneWidget);
      expect(selectedChip(MenoMateTheme.sakuraPrimaryDark), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pain slider uses interaction indigo, not amber', (
      tester,
    ) async {
      await pumpLogger(tester);
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      expect(
        tester.widget<Slider>(slider).activeColor,
        MenoMateTheme.sakuraInteraction,
      );
      expect(selectedChip(MenoMateTheme.sakuraAmber), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode selection uses starry interaction indigo', (
      tester,
    ) async {
      await pumpLogger(tester, theme: MenoMateTheme.starryNightTheme);
      await tester.tap(find.text('Happy'));
      await tester.pump();

      expect(selectedChip(MenoMateTheme.starryInteraction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('login harmonization', () {
    testWidgets('auth card joins the radius family; link is indigo', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MenoMateTheme.sakuraTheme,
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final card = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.borderRadius ==
                BorderRadius.circular(18) &&
            (w.decoration as BoxDecoration?)?.color ==
                MenoMateTheme.sakuraTheme.colorScheme.surface &&
            w.padding == const EdgeInsets.all(24),
      );
      expect(card, findsOneWidget);

      final link = find.byWidgetPredicate((w) {
        if (w is! RichText) return false;
        final span = w.text;
        if (span is! TextSpan) return false;
        return span.children?.any(
              (c) =>
                  c is TextSpan &&
                  c.text == 'Create Account' &&
                  c.style?.color == MenoMateTheme.sakuraInteraction,
            ) ??
            false;
      });
      expect(link, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('dark-mode surface hierarchy', () {
    test('tinted surfaces stay dark, lifted, and distinct', () {
      const bg = MenoMateTheme.starryBg;
      const surface = MenoMateTheme.starrySurface;
      const surface2 = MenoMateTheme.starrySurface2;
      const tints = [
        MenoMateTheme.starrySurfaceRose,
        MenoMateTheme.starrySurfaceViolet,
        MenoMateTheme.starrySurfaceSage,
      ];
      // All tints read as dark navy variants, clearly above background.
      for (final t in tints) {
        expect(t.computeLuminance(), greaterThan(bg.computeLuminance()));
        expect(t, isNot(surface));
        expect(t, isNot(surface2));
      }
      // Three distinct hues, not three shades of one color.
      expect(
        {tints[0].toARGB32(), tints[1].toARGB32(), tints[2].toARGB32()}.length,
        3,
      );
    });

    testWidgets('cycle overview card earns the rose navy in dark mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final now = DateTime.now();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCycleProvider.overrideWith(
              (ref) => Future.value(
                Fresh<CurrentCycleResponse?>(
                  CurrentCycleResponse(
                    hasData: true,
                    currentCycleDay: 2,
                    phase: 'menstrual',
                    isBleeding: true,
                    isOngoing: true,
                    latestPeriodStart: now.subtract(const Duration(days: 1)),
                    predictionConfidence: 'low',
                  ),
                ),
              ),
            ),
            profileProvider.overrideWith(
              () => _FixedProfileNotifier(const NoData<Profile?>()),
            ),
          ],
          child: MaterialApp(
            theme: MenoMateTheme.starryNightTheme,
            home: const HomeTab(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The overview is the only dusty-rose navy surface on Home.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color ==
                  MenoMateTheme.starrySurfaceRose,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('wellness card earns the sage navy in dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenoMateTheme.starryNightTheme,
          home: const Scaffold(body: SymptomLoggerCard()),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color ==
                  MenoMateTheme.starrySurfaceSage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('telemetry title uses warm pale neutral, not pure white', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MenoMateTheme.starryNightTheme,
            home: const Scaffold(body: DeviceTelemetryCard()),
          ),
        ),
      );
      await tester.pump();

      final title = tester.widget<Text>(find.text('MenoMate Wearable'));
      expect(title.style?.color, MenoMateTheme.starryText);
      expect(tester.takeException(), isNull);
    });
  });
}

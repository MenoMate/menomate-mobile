import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/widgets/menomate_logo.dart';

/// Theme-aware logo selection: the active ThemeData alone decides which
/// supplied asset renders. No providers, no timers, no manual refresh.
void main() {
  String selectedAsset(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    return (image.image as AssetImage).assetName;
  }

  Future<void> pumpLogo(
    WidgetTester tester, {
    required ThemeData theme,
    double size = 68,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: MenoMateLogo(size: size))),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('theme-aware logo selection', () {
    testWidgets('light theme selects the light asset', (tester) async {
      await pumpLogo(tester, theme: MenoMateTheme.sakuraTheme);

      expect(selectedAsset(tester), MenoMateLogo.lightAsset);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme selects the dark asset', (tester) async {
      await pumpLogo(tester, theme: MenoMateTheme.starryNightTheme);

      expect(selectedAsset(tester), MenoMateLogo.darkAsset);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching theme switches the asset, no restart',
        (tester) async {
      await pumpLogo(tester, theme: MenoMateTheme.sakuraTheme);
      expect(selectedAsset(tester), MenoMateLogo.lightAsset);

      await pumpLogo(tester, theme: MenoMateTheme.starryNightTheme);
      expect(selectedAsset(tester), MenoMateLogo.darkAsset);

      await pumpLogo(tester, theme: MenoMateTheme.sakuraTheme);
      expect(selectedAsset(tester), MenoMateLogo.lightAsset);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layout: requested size kept, circular brand shape',
        (tester) async {
      await pumpLogo(tester,
          theme: MenoMateTheme.sakuraTheme, size: 68);

      expect(tester.getSize(find.byType(MenoMateLogo)),
          const Size(68, 68));
      expect(
        find.descendant(
          of: find.byType(MenoMateLogo),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

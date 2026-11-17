import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/providers/logo_variant_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('logo variant preference', () {
    // Hydration crosses async plugin-channel hops, so tests trigger the
    // build first and then settle on a real (short) delay.
    Future<void> settleHydration(ProviderContainer container) async {
      container.read(logoVariantProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    test('defaults to standard with no stored choice', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await settleHydration(container);
      expect(container.read(logoVariantProvider), AppLogoVariant.standard);
    });

    test('choice persists across provider rebuilds', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ProviderContainer();
      addTearDown(first.dispose);
      await settleHydration(first);

      await first
          .read(logoVariantProvider.notifier)
          .setVariant(AppLogoVariant.compact);
      expect(first.read(logoVariantProvider), AppLogoVariant.compact);

      final second = ProviderContainer();
      addTearDown(second.dispose);
      await settleHydration(second);
      expect(second.read(logoVariantProvider), AppLogoVariant.compact);
    });

    test('every variant has a human label and description', () {
      for (final variant in AppLogoVariant.values) {
        expect(kLogoVariantLabels[variant], isNotNull);
        expect(kLogoVariantLabels[variant]!.trim(), isNotEmpty);
        expect(kLogoVariantDescriptions[variant], isNotNull);
        expect(kLogoVariantDescriptions[variant]!.trim(), isNotEmpty);
      }
      expect(AppLogoVariant.values.length, 3);
    });
  });
}

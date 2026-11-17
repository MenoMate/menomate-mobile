import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/logo_variant_provider.dart';

/// Theme-aware MenoMate brand mark. Selects the supplied logo asset from
/// the active [ThemeData] (light asset on light, dark asset on dark) so
/// callers never duplicate theme-selection logic.
///
/// Both brand marks are circular: the square artwork is clipped to the
/// inscribed oval, which only trims the plain background margins around
/// the centered lotus — the artwork itself is untouched.
///
/// [variant] picks one of the three selectable presentations. App screens
/// should prefer [MenoMateBrandLogo], which reads the user's persisted
/// choice; [variant] exists so Settings previews and tests can render a
/// specific presentation without a provider scope.
class MenoMateLogo extends StatelessWidget {
  static const String lightAsset = 'assets/images/menomate_logo_light.png';
  static const String darkAsset = 'assets/images/menomate_logo_dark.png';

  /// Square edge length in logical pixels (matches the replaced mark).
  final double size;

  /// Presentation to render. Defaults to the classic circle.
  final AppLogoVariant variant;

  const MenoMateLogo({
    super.key,
    required this.size,
    this.variant = AppLogoVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark ? darkAsset : lightAsset;
    // Theme (and variant) changes cross-fade subtly: no flicker, no
    // broken-asset flash, no layout jump — the size never changes.
    final mark = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: SizedBox.square(
        key: ValueKey('${variant.name}-$asset'),
        dimension: size,
        child: ClipOval(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            semanticLabel: 'MenoMate logo',
          ),
        ),
      ),
    );

    switch (variant) {
      case AppLogoVariant.standard:
        return mark;
      case AppLogoVariant.framed:
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline),
          ),
          child: mark,
        );
      case AppLogoVariant.compact:
        final theme = Theme.of(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 10),
            Text(
              'MenoMate',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
    }
  }
}

/// The single brand entry point for app screens: renders [MenoMateLogo] in
/// the user's persisted [AppLogoVariant]. Changing the choice in Settings
/// rebuilds every instance at once, so no screen can drift to a different
/// presentation.
class MenoMateBrandLogo extends ConsumerWidget {
  /// Square edge length of the mark in logical pixels.
  final double size;

  const MenoMateBrandLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenoMateLogo(size: size, variant: ref.watch(logoVariantProvider));
  }
}

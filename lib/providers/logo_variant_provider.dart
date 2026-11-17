import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLogoVariantKey = 'menomate.logo_variant';

/// The three selectable MenoMate logo presentations.
///
/// These are display variants of the supplied brand artwork — the user
/// chooses the SHAPE, the app resolves the themed asset (light/dark) from
/// the active [ThemeData]. No artwork is altered, tinted, or degraded.
/// Persisted per device (SharedPreferences) so the choice applies before
/// sign-in, in offline tracking, and across restarts.
enum AppLogoVariant {
  /// The supplied mark, circular, as-is.
  standard,

  /// The mark on a soft tinted tile with a low-contrast border.
  framed,

  /// A smaller mark beside the MenoMate wordmark.
  compact,
}

/// Human labels for Settings. Original MenoMate wording.
const Map<AppLogoVariant, String> kLogoVariantLabels = {
  AppLogoVariant.standard: 'Classic circle',
  AppLogoVariant.framed: 'Soft tile',
  AppLogoVariant.compact: 'Compact with name',
};

const Map<AppLogoVariant, String> kLogoVariantDescriptions = {
  AppLogoVariant.standard: 'The MenoMate mark on its own.',
  AppLogoVariant.framed: 'The mark on a soft tinted tile.',
  AppLogoVariant.compact: 'A smaller mark beside the MenoMate name.',
};

AppLogoVariant _parseVariant(String? raw) {
  for (final variant in AppLogoVariant.values) {
    if (variant.name == raw) return variant;
  }
  return AppLogoVariant.standard;
}

/// Device-level logo preference. Degrades to in-memory state when
/// persistence is unavailable; the UI stays consistent either way.
class LogoVariantNotifier extends Notifier<AppLogoVariant> {
  @override
  AppLogoVariant build() {
    Future.microtask(_hydrate);
    return AppLogoVariant.standard;
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = _parseVariant(prefs.getString(_kLogoVariantKey));
    } catch (_) {
      // Persistence unavailable; the default stands.
    }
  }

  Future<void> setVariant(AppLogoVariant variant) async {
    state = variant;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLogoVariantKey, variant.name);
    } catch (_) {
      // Best-effort only; in-memory state still applies this session.
    }
  }
}

final logoVariantProvider =
    NotifierProvider<LogoVariantNotifier, AppLogoVariant>(
      LogoVariantNotifier.new,
    );

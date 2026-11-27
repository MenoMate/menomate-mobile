import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarePrivacyCategories {
  static const String cycles = 'cycles';
  static const String dailyLogs = 'daily_logs';
  static const String deviceHistory = 'device_history';
  static const String memories = 'memories';

  static const List<String> all = [
    cycles,
    dailyLogs,
    deviceHistory,
    memories,
  ];
}

@immutable
class CareConsentState {
  final bool consentGranted;
  final bool promptDismissed;
  final Set<String> allowedCategories;

  const CareConsentState({
    this.consentGranted = false,
    this.promptDismissed = false,
    this.allowedCategories = const {
      CarePrivacyCategories.cycles,
      CarePrivacyCategories.dailyLogs,
      CarePrivacyCategories.deviceHistory,
      CarePrivacyCategories.memories,
    },
  });

  CareConsentState copyWith({
    bool? consentGranted,
    bool? promptDismissed,
    Set<String>? allowedCategories,
  }) {
    return CareConsentState(
      consentGranted: consentGranted ?? this.consentGranted,
      promptDismissed: promptDismissed ?? this.promptDismissed,
      allowedCategories: allowedCategories ?? this.allowedCategories,
    );
  }
}

class CareConsentNotifier extends Notifier<CareConsentState> {
  static const _kConsentGranted = 'care_consent_granted';
  static const _kPromptDismissed = 'care_consent_prompt_dismissed';
  static const _kAllowedCategories = 'care_allowed_categories';

  bool _loaded = false;

  @override
  CareConsentState build() {
    if (!_loaded) {
      _loaded = true;
      Future.microtask(_load);
    }
    return const CareConsentState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final granted = prefs.getBool(_kConsentGranted) ?? false;
      final dismissed = prefs.getBool(_kPromptDismissed) ?? false;
      final cats = prefs.getStringList(_kAllowedCategories);
      state = CareConsentState(
        consentGranted: granted,
        promptDismissed: dismissed,
        allowedCategories: cats != null
            ? cats.toSet()
            : CarePrivacyCategories.all.toSet(),
      );
    } catch (e) {
      debugPrint('Failed to load Care consent state: $e');
    }
  }

  Future<void> _persist(CareConsentState next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConsentGranted, next.consentGranted);
    await prefs.setBool(_kPromptDismissed, next.promptDismissed);
    await prefs.setStringList(
      _kAllowedCategories,
      next.allowedCategories.toList(),
    );
  }

  Future<void> grantConsent() =>
      _persist(state.copyWith(consentGranted: true, promptDismissed: true));

  Future<void> revokeConsent() =>
      _persist(state.copyWith(consentGranted: false, promptDismissed: true));

  Future<void> dismissPromptWithoutConsent() =>
      _persist(state.copyWith(consentGranted: false, promptDismissed: true));

  Future<void> toggleCategory(String category, bool enabled) async {
    final next = Set<String>.from(state.allowedCategories);
    if (enabled) {
      next.add(category);
    } else {
      next.remove(category);
    }
    await _persist(state.copyWith(allowedCategories: next));
  }
}

final careConsentProvider =
    NotifierProvider<CareConsentNotifier, CareConsentState>(
      CareConsentNotifier.new,
    );

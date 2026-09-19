import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/device_timezone.dart';
import '../core/format.dart' show kMonthNames;
import '../widgets/menomate_logo.dart';
import '../data/app_database.dart' show toIsoDate;
import '../data/sync_policy.dart';
import '../models/health_context.dart'
    show
        validateBirthPair,
        kContraceptionLabels,
        kPregnancyContextLabels,
        HealthContext;
import '../models/interests.dart';
import '../models/onboarding.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/onboarding_context_provider.dart'
    show kPeriodRegularityOptions;
import '../providers/onboarding_status_provider.dart';
import '../providers/personalization_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

/// Phase 2 first-run experience: Welcome → name → interests → cycle → what
/// to track → personalization → (conditional) reproductive context →
/// (conditional) pregnancy state → basics → Ready → Home.
///
/// Principles (see product direction):
/// - ASK NOW only what improves the first experience; the rest is
///   discoverable later inside the app (ASK LATER).
/// - No account is ever forced: local users complete the same flow with
///   local-only persistence; "Create an account" is a secondary action.
/// - Personalization (interests, categories, concerns, prefs) is local-only
///   (see personalizationProvider + docs/backend_gaps.md): it decides which
///   questions to ask and will personalize later phases — it never changes
///   backend payloads, predictions, estimates, or modes.
/// - Pregnancy / trying-to-conceive are interests until the user gives an
///   explicit actual-pregnancy answer. Nothing here activates pregnancy
///   mode, computes fertility, or diagnoses.
/// - Backend truth: name + last period start/end + usual lengths +
///   timezone go to `POST /api/v1/onboarding/complete`; birth pair goes to
///   the profile; contraception/pregnancy-context go to health-context.
///   Everything else stays on-device.
///
/// Deterministic + recoverable: completion is flagged only after a
/// successful submit; an interrupted run simply restarts the flow and
/// re-asks (persisted personalization is reloaded, never corrupted).
/// Existing onboarded users never see this screen (router gate).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingData {
  String name = '';

  /// Multi-select interests (canonical ids). Empty = skipped.
  Set<String> interests = {};

  DateTime? lastStart;
  PeriodStatus status = PeriodStatus.ended;
  DateTime? lastEnd;
  int? cycleLength; // null = not sure
  int? periodLength; // null = not sure
  String? regularityKey;
  bool tracksElsewhere = false;

  Set<String> trackingCategories = {};
  Set<String> symptomAreas = {};
  Set<String> fertilityPrefs = {};
  Set<String> healthConcerns = {};

  String? contraceptionMethod;
  String? pregnancyContext;

  /// Explicit actual-pregnancy answer (null = unasked). Only an explicit
  /// `true` may route to pregnancy mode later.
  bool? isActuallyPregnant;

  int? birthMonth;
  String birthYearRaw = '';
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _data = _OnboardingData();
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();

  // ---- Adaptive step model ----
  //
  // Steps are stable ids; the visible sequence derives from interests.
  // Backend-gated inputs (name, last period) are ALWAYS asked. Everything
  // else is conditional or skippable.
  static const String _sName = 'name';
  static const String _sInterests = 'interests';
  static const String _sCycle = 'cycle';
  static const String _sTracking = 'tracking';
  static const String _sPersonal = 'personal';
  static const String _sRepro = 'repro';
  static const String _sPregnancy = 'pregnancy';
  static const String _sBasics = 'basics';
  static const String _sReady = 'ready';
  static const String _sDone = 'done';

  int _pos = 0;
  bool _isSubmitting = false;
  String? _inlineError;

  List<String> get _visibleSteps {
    final ids = <String>[
      _sName,
      _sInterests,
      _sCycle,
      _sTracking,
      _sPersonal,
    ];
    final view = Personalization(interests: _data.interests);
    if (view.wantsFertilityPrefs ||
        view.wantsPregnancyState ||
        _data.interests.contains(UserInterests.fertilityAwareness)) {
      ids.add(_sRepro);
    }
    if (view.wantsPregnancyState) ids.add(_sPregnancy);
    ids.add(_sBasics);
    ids.add(_sReady);
    ids.add(_sDone);
    return ids;
  }

  String get _currentStep =>
      _visibleSteps[_pos.clamp(0, _visibleSteps.length - 1)];

  bool get _isReady => _currentStep == _sReady;
  bool get _isCompletion => _currentStep == _sDone;

  @override
  void initState() {
    super.initState();
    // Pre-fill the name from signup metadata when available so the user
    // is not asked twice. Best-effort; the backend requires it regardless.
    try {
      final metaName = Supabase
          .instance
          .client
          .auth
          .currentUser
          ?.userMetadata?['name'];
      if (metaName is String && metaName.trim().isNotEmpty) {
        _nameController.text = metaName.trim();
        _data.name = metaName.trim();
      }
    } catch (_) {
      // No session metadata available; the name step collects it.
    }
    // Reload previously stored personalization so an interrupted run
    // resumes with earlier answers intact rather than corrupted.
    unawaited(_restorePersonalization());
  }

  Future<void> _restorePersonalization() async {
    try {
      final stored = await ref.read(personalizationProvider.future);
      if (!mounted) return;
      setState(() {
        _data.interests = Set<String>.from(stored.interests);
        _data.symptomAreas = Set<String>.from(stored.symptomAreas);
        _data.fertilityPrefs = Set<String>.from(stored.fertilityPrefs);
        _data.trackingCategories =
            Set<String>.from(stored.trackingCategories);
        _data.healthConcerns = Set<String>.from(stored.healthConcerns);
        _data.tracksElsewhere = stored.tracksElsewhere;
        _data.isActuallyPregnant = stored.isActuallyPregnant;
      });
    } catch (_) {
      // Best-effort only; the flow works from blank answers.
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _go(int next) {
    final steps = _visibleSteps;
    setState(() {
      _pos = next.clamp(0, steps.length - 1);
      _inlineError = null;
    });
    _pageController.animateToPage(
      _pos,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _goToStep(String id) {
    final at = _visibleSteps.indexOf(id);
    if (at >= 0) _go(at);
  }

  void _next() => _go(_pos + 1);
  void _back() => _go(_pos - 1);

  Future<String?> _deviceZone() async {
    try {
      return await deviceTimeZoneId().timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ---- Per-step validation ----

  bool _validateCurrent() {
    switch (_currentStep) {
      case _sName:
        if (_nameController.text.trim().isEmpty) {
          setState(() => _inlineError = 'Please enter your name.');
          return false;
        }
        _data.name = _nameController.text.trim();
        return true;
      case _sCycle:
        if (_data.lastStart == null) {
          setState(
            () => _inlineError =
                'Please choose when your last period started.',
          );
          return false;
        }
        if (_data.lastStart!.isAfter(_today())) {
          setState(
            () => _inlineError = 'Start date can\u2019t be in the future.',
          );
          return false;
        }
        if (_data.status == PeriodStatus.ended) {
          if (_data.lastEnd == null) {
            setState(
              () => _inlineError =
                  'Please choose when it ended, or select Ongoing.',
            );
            return false;
          }
          if (_data.lastEnd!.isAfter(_today())) {
            setState(
              () => _inlineError = 'End date can\u2019t be in the future.',
            );
            return false;
          }
          if (_data.lastEnd!.isBefore(_data.lastStart!)) {
            setState(
              () => _inlineError =
                  'End date can\u2019t be before the start date.',
            );
            return false;
          }
        }
        return true;
      case _sBasics:
        final raw = _birthYearController.text.trim();
        final int? year = raw.isEmpty ? null : int.tryParse(raw);
        if (raw.isNotEmpty && year == null) {
          setState(() => _inlineError = 'Please enter a 4-digit birth year.');
          return false;
        }
        final err = validateBirthPair(year, _data.birthMonth);
        if (err != null) {
          setState(() => _inlineError = err);
          return false;
        }
        return true;
      default:
        // Interests, tracking, personalization, repro, pregnancy, ready:
        // empty means skipped — never blocking.
        return true;
    }
  }

  void _onContinue() {
    if (!_validateCurrent()) return;
    unawaited(_persistPersonalization());
    _next();
  }

  /// Persist personalization answers (local-only). Best-effort; never
  /// blocks the flow. Called as the user progresses and again on submit.
  Future<void> _persistPersonalization() async {
    try {
      final personal = ref.read(personalizationProvider.notifier);
      await personal.setInterests(_data.interests).catchError((_) => null);
      await personal
          .setTrackingCategories(_data.trackingCategories)
          .catchError((_) => null);
      await personal
          .setSymptomAreas(_data.symptomAreas)
          .catchError((_) => null);
      await personal
          .setFertilityPrefs(_data.fertilityPrefs)
          .catchError((_) => null);
      await personal
          .setHealthConcerns(_data.healthConcerns)
          .catchError((_) => null);
      await personal
          .setTracksElsewhere(_data.tracksElsewhere)
          .catchError((_) => null);
      await personal
          .setIsActuallyPregnant(_data.isActuallyPregnant)
          .catchError((_) => null);
    } catch (_) {
      // Never block onboarding on local-only context.
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });
    try {
      unawaited(_persistPersonalization());

      final cycleParsed = _data.cycleLength == null
          ? const ParsedUsualDays.unset()
          : ParsedUsualDays.valid(_data.cycleLength!);
      final periodParsed = _data.periodLength == null
          ? const ParsedUsualDays.unset()
          : ParsedUsualDays.valid(_data.periodLength!);

      final errors = validateOnboardingInput(
        name: _data.name,
        periodStart: _data.lastStart,
        status: _data.status,
        periodEnd: _data.lastEnd,
        usualCycle: cycleParsed,
        usualPeriod: periodParsed,
        today: DateTime.now(),
      );
      final birthRaw = _birthYearController.text.trim();
      final int? birthYear = birthRaw.isEmpty ? null : int.tryParse(birthRaw);
      if (birthRaw.isNotEmpty && birthYear == null) {
        errors['dob'] = 'Please enter a 4-digit birth year.';
      } else {
        final dobError = validateBirthPair(birthYear, _data.birthMonth);
        if (dobError != null) errors['dob'] = dobError;
      }
      if (errors.isNotEmpty) {
        final firstKey = errors.keys.first;
        String? target;
        if (firstKey == 'name') {
          target = _sName;
        } else if (firstKey == 'start' || firstKey == 'end') {
          target = _sCycle;
        } else if (firstKey == 'cycle' || firstKey == 'period') {
          target = _sCycle;
        } else if (firstKey == 'dob') {
          target = _sBasics;
        }
        setState(() {
          _isSubmitting = false;
          _inlineError = errors.values.first;
        });
        if (target != null) _goToStep(target);
        return;
      }

      final offline = ref.read(isOfflineTrackingProvider);
      final userId = ref.read(currentUserIdProvider);
      final zone = await _deviceZone();

      if (offline && userId != null) {
        await ref.read(profileRepositoryProvider).saveProfile(userId, {
          'name': _data.name,
          'usual_cycle_days': cycleParsed.isValid ? cycleParsed.value : null,
          'usual_period_days': periodParsed.isValid ? periodParsed.value : null,
          'theme': ref.read(themeModeProvider) == ThemeMode.dark
              ? 'dark'
              : 'light',
          'units': 'metric',
          'birth_year': birthYear,
          'birth_month': _data.birthMonth,
          'timezone': zone,
        }, localOnly: true);
        await ref
            .read(cycleRepositoryProvider)
            .storeLocalCycle(
              userId,
              periodStart: toIsoDate(_data.lastStart!),
              periodEnd:
                  _data.status == PeriodStatus.ended && _data.lastEnd != null
                  ? toIsoDate(_data.lastEnd!)
                  : resolvePeriodEndIso(_data.status, null),
            );
        await _saveReproductiveContext(userId, localOnly: true);
        unawaited(ref.read(onboardingStatusProvider.notifier).markCompleted());
        refreshAllAppData(ref);
        if (mounted) _goToStep(_sDone);
        return;
      }

      final request = OnboardingRequest(
        name: _data.name,
        lastPeriodStart: toIsoDate(_data.lastStart!),
        lastPeriodEnd:
            _data.status == PeriodStatus.ended && _data.lastEnd != null
            ? toIsoDate(_data.lastEnd!)
            : resolvePeriodEndIso(_data.status, null),
        usualCycleDays: cycleParsed.isValid ? cycleParsed.value : null,
        usualPeriodDays: periodParsed.isValid ? periodParsed.value : null,
        timezone: zone,
      );
      final result = await ref
          .read(apiServiceProvider)
          .completeOnboarding(request);
      if (userId != null) {
        await ref
            .read(profileRepositoryProvider)
            .storeOnboardedProfile(result.profile);
        await ref
            .read(cycleRepositoryProvider)
            .storeOnboardedCycle(
              userId,
              serverId: result.periodId,
              periodStart: result.periodStart,
              periodEnd: result.periodEnd,
            );
        final updated = await ref.read(profileRepositoryProvider).saveProfile(
          userId,
          {
            'units': 'metric',
            'birth_year': birthYear,
            'birth_month': _data.birthMonth,
          },
        );
        ref
            .read(profileProvider.notifier)
            .setProfile(updated.dataOrNull ?? result.profile);
        await _saveReproductiveContext(userId, localOnly: false);
        unawaited(ref.read(onboardingStatusProvider.notifier).markCompleted());
      } else {
        await ref.read(profileProvider.notifier).reload();
        unawaited(ref.read(onboardingStatusProvider.notifier).markCompleted());
      }
      if (mounted) _goToStep(_sDone);
    } on ValidationError catch (e) {
      _showMessage('Please check your entries. ${e.message}');
    } on Conflict catch (e) {
      try {
        await ref.read(profileProvider.notifier).reload();
        unawaited(ref.read(onboardingStatusProvider.notifier).markCompleted());
      } catch (_) {}
      _showMessage(e.message);
      if (mounted) _goToStep(_sDone);
    } on NetworkUnavailable {
      _showMessage('You\u2019re offline. Check your connection and try again.');
    } on AuthFailure {
      _showMessage('Your session expired. Please sign in again.');
    } on ServerError {
      _showMessage('Something went wrong. Please try again.');
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Persist supported reproductive context for real. Contraception and
  /// pregnancy context ARE backend-supported via the health-context API.
  /// Skipped when the user left both blank. Never derived from interests:
  /// only explicit selections on the repro step are saved.
  Future<void> _saveReproductiveContext(
    String userId, {
    required bool localOnly,
  }) async {
    if (_data.contraceptionMethod == null && _data.pregnancyContext == null) {
      return;
    }
    try {
      final repo = ref.read(healthContextRepositoryProvider);
      final current = await repo.loadHealthContext(userId);
      final existing = current.dataOrNull;
      await repo.saveHealthContext(
        userId,
        HealthContext(
          userId: userId,
          contraceptionMethod: _data.contraceptionMethod,
          contraceptionNote: existing?.contraceptionNote,
          pregnancyContext: _data.pregnancyContext,
          healthNotes: existing?.healthNotes,
        ),
        localOnly: localOnly,
      );
    } catch (_) {
      // Reproductive context is optional: never fail onboarding over it.
    }
  }

  // ---- Shell ----

  bool _isOptionalStep(String id) {
    // Required: name + cycle (backend-gated). Ready/Done have their own
    // buttons. Everything else is skippable.
    return id != _sName && id != _sCycle && id != _sReady && id != _sDone;
  }

  void _clearOptionalStep(String id) {
    switch (id) {
      case _sInterests:
        _data.interests = {};
        _data.symptomAreas = {};
        _data.fertilityPrefs = {};
        _data.trackingCategories = {};
        _data.healthConcerns = {};
        _data.isActuallyPregnant = null;
        break;
      case _sTracking:
        _data.trackingCategories = {};
        break;
      case _sPersonal:
        _data.symptomAreas = {};
        _data.fertilityPrefs = {};
        _data.healthConcerns = {};
        break;
      case _sRepro:
        _data.contraceptionMethod = null;
        _data.pregnancyContext = null;
        break;
      case _sPregnancy:
        _data.isActuallyPregnant = null;
        break;
      case _sBasics:
        _data.birthMonth = null;
        _birthYearController.clear();
        break;
      default:
        break;
    }
    setState(() => _inlineError = null);
  }

  Widget _stepWidget(BuildContext context, String id) {
    switch (id) {
      case _sName:
        return _nameStep(context);
      case _sInterests:
        return _interestsStep(context);
      case _sCycle:
        return _cycleStep(context);
      case _sTracking:
        return _trackingStep(context);
      case _sPersonal:
        return _personalStep(context);
      case _sRepro:
        return _reproductiveStep(context);
      case _sPregnancy:
        return _pregnancyStateStep(context);
      case _sBasics:
        return _basicsStep(context);
      case _sReady:
        return _readyStep(context);
      case _sDone:
      default:
        return _completionStep(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = _visibleSteps;
    if (_pos >= steps.length) {
      _pos = steps.length - 1;
    }
    final isChromeStep = !_isReady && !_isCompletion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting started'),
        leading: _pos > 0 && !_isCompletion
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: _back,
              )
            : null,
        actions: [
          if (_isOptionalStep(_currentStep) && !_isCompletion)
            TextButton(
              onPressed: () {
                _clearOptionalStep(_currentStep);
                _next();
              },
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // The chrome (progress + bottom action area) stays mounted on
            // EVERY step, even when Ready/Done render their own buttons.
            // Removing widgets here would shift the PageView's position in
            // the Column, destroying its element mid-navigation and
            // resetting the page — so these are placeholders, never gaps.
            _ProgressBar(
              index: isChromeStep ? _pos + 1 : steps.length - 1,
              total: steps.length - 1,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pos = i),
                children: [
                  for (final id in steps) _stepWidget(context, id),
                ],
              ),
            ),
            if (isChromeStep)
              _bottomBar(context, colorScheme)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _stepShell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
    String? error,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            child,
            if (error != null || _inlineError != null) ...[
              const SizedBox(height: 12),
              Text(
                error ?? _inlineError ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onContinue,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
            if (_pos > 0) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Back'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selectableCard(
    BuildContext context, {
    required bool selected,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Steps ----

  Widget _nameStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What should we call you?',
      subtitle: 'Your name personalizes your MenoMate space.',
      child: TextField(
        controller: _nameController,
        autofocus: false,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'What should we call you?',
          hintText: 'e.g. Sarah',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _onContinue(),
      ),
    );
  }

  /// "What brings you to MenoMate?" Multi-select interests. Any subset is
  /// valid; empty means skipped. Nothing here locks the user into a mode.
  Widget _interestsStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What brings you to MenoMate?',
      subtitle:
          'You can choose more than one. You can change these later. Choosing never locks you into a mode.',
      child: Column(
        children: [
          for (final interest in kUserInterests)
            _selectableCard(
              context,
              selected: _data.interests.contains(interest.key),
              title: interest.label,
              subtitle: interest.description,
              onTap: () => setState(() {
                final next = Set<String>.from(_data.interests);
                if (next.contains(interest.key)) {
                  next.remove(interest.key);
                } else {
                  next.add(interest.key);
                }
                _data.interests = next;
                final view = Personalization(interests: next);
                if (!view.wantsSymptomAreas) _data.symptomAreas = {};
                if (!view.wantsFertilityPrefs) _data.fertilityPrefs = {};
                if (!view.wantsPregnancyState) {
                  _data.isActuallyPregnant = null;
                }
              }),
            ),
        ],
      ),
    );
  }

  /// Baseline cycle information. Last-period start is backend-required;
  /// everything else accepts "not sure". One screen, no interrogation.
  Widget _cycleStep(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat.yMMMd();
    return _stepShell(
      context,
      title: 'About your cycle',
      subtitle:
          'Just the basics so MenoMate starts in the right place. Unsure about anything? Leave it as not sure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When did your last period start?',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _data.lastStart == null
                  ? 'Select start date'
                  : fmt.format(_data.lastStart!),
            ),
            onPressed: () async {
              final today = _today();
              final picked = await showDatePicker(
                context: context,
                initialDate: _data.lastStart ?? today,
                firstDate: DateTime(1900),
                lastDate: today,
              );
              if (picked != null) {
                setState(() {
                  _data.lastStart = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                  _inlineError = null;
                });
              }
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() {
                _data.lastStart = _today();
                _inlineError = null;
              }),
              child: const Text(
                'I don\u2019t remember — use today (approximate)',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<PeriodStatus>(
            segments: const [
              ButtonSegment(
                value: PeriodStatus.ongoing,
                label: Text('Ongoing'),
                icon: Icon(Icons.more_horiz),
              ),
              ButtonSegment(
                value: PeriodStatus.ended,
                label: Text('Ended'),
                icon: Icon(Icons.check),
              ),
            ],
            selected: {_data.status},
            onSelectionChanged: (s) => setState(() {
              _data.status = s.first;
              if (_data.status == PeriodStatus.ongoing) _data.lastEnd = null;
              _inlineError = null;
            }),
          ),
          if (_data.status == PeriodStatus.ended) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _data.lastEnd == null
                    ? 'Select end date'
                    : fmt.format(_data.lastEnd!),
              ),
              onPressed: () async {
                final today = _today();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _data.lastEnd ?? _data.lastStart ?? today,
                  firstDate: _data.lastStart ?? DateTime(1900),
                  lastDate: today,
                );
                if (picked != null) {
                  setState(() {
                    _data.lastEnd = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                    );
                    _inlineError = null;
                  });
                }
              },
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Usual cycle length',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: _data.cycleLength,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('I don\u2019t know'),
              ),
              for (var d = 20; d <= 45; d++)
                DropdownMenuItem<int?>(value: d, child: Text('$d days')),
            ],
            onChanged: (v) => setState(() => _data.cycleLength = v),
          ),
          const SizedBox(height: 12),
          Text(
            'Usual period length',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: _data.periodLength,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('I don\u2019t know'),
              ),
              for (var d = 1; d <= 12; d++)
                DropdownMenuItem<int?>(value: d, child: Text('$d days')),
            ],
            onChanged: (v) => setState(() => _data.periodLength = v),
          ),
          const SizedBox(height: 20),
          Text(
            'Are your periods generally regular?',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in kPeriodRegularityOptions)
                ChoiceChip(
                  label: Text(o.$2),
                  selected: _data.regularityKey == o.$1,
                  onSelected: (sel) => setState(
                    () => _data.regularityKey = sel ? o.$1 : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _data.tracksElsewhere,
            title: const Text('I already track my periods elsewhere'),
            subtitle: const Text(
              'MenoMate starts fresh — past history isn\u2019t imported.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                setState(() => _data.tracksElsewhere = v ?? false),
          ),
        ],
      ),
    );
  }

  /// "What would you like to track?" Categories, not a questionnaire.
  /// Display hints only — implies nothing medical.
  Widget _trackingStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What would you like to track?',
      subtitle:
          'Pick the categories you care about. You can adjust these anytime inside the app. Optional.',
      child: Column(
        children: [
          for (final entry in kTrackingCategoryLabels.entries)
            _selectableCard(
              context,
              selected: _data.trackingCategories.contains(entry.key),
              title: entry.value,
              onTap: () => setState(() {
                final next = Set<String>.from(_data.trackingCategories);
                if (next.contains(entry.key)) {
                  next.remove(entry.key);
                } else {
                  next.add(entry.key);
                }
                _data.trackingCategories = next;
              }),
            ),
        ],
      ),
    );
  }

  /// Personalization: conditional symptom/fertility sections plus health
  /// concerns as context (never diagnoses). Always skippable as a whole.
  Widget _personalStep(BuildContext context) {
    final theme = Theme.of(context);
    final view = Personalization(interests: _data.interests);
    return _stepShell(
      context,
      title: 'Make it yours',
      subtitle:
          'A few optional details so MenoMate highlights what matters to you. Skip anything.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (view.wantsSymptomAreas) ...[
            Text(
              'Which areas interest you most?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in SymptomAreas.all)
                  FilterChip(
                    label: Text(kSymptomAreaLabels[area] ?? area),
                    selected: _data.symptomAreas.contains(area),
                    onSelected: (sel) => setState(() {
                      final next = Set<String>.from(_data.symptomAreas);
                      if (sel) {
                        next.add(area);
                      } else {
                        next.remove(area);
                      }
                      _data.symptomAreas = next;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (view.wantsFertilityPrefs) ...[
            Text(
              'Want to track fertility signs?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'MenoMate only records what you log — estimates always come from the server.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            for (final pref in FertilityPrefs.all)
              CheckboxListTile(
                value: _data.fertilityPrefs.contains(pref),
                title: Text(kFertilityPrefLabels[pref] ?? pref),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (sel) => setState(() {
                  final next = Set<String>.from(_data.fertilityPrefs);
                  if (sel == true) {
                    next.add(pref);
                  } else {
                    next.remove(pref);
                  }
                  _data.fertilityPrefs = next;
                }),
              ),
            const SizedBox(height: 12),
          ],
          Text(
            'Anything you\u2019d like support with?',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'These are interests for relevant information — selecting one never means you have a condition and nothing here is a diagnosis.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in kHealthConcernLabels.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _data.healthConcerns.contains(entry.key),
                  onSelected: (sel) => setState(() {
                    final next = Set<String>.from(_data.healthConcerns);
                    if (sel) {
                      next.add(entry.key);
                    } else {
                      next.remove(entry.key);
                    }
                    _data.healthConcerns = next;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Reproductive context (backend-supported enums only). Shown when
  /// fertility/pregnancy interests suggest it. Explicit selections are
  /// saved for real; blank stays blank. Never derived from interests.
  Widget _reproductiveStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Relevant reproductive context?',
      subtitle:
          'Saved to your health profile when provided. Optional — Skip to continue.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contraception',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _data.contraceptionMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select (optional)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Prefer not to say'),
              ),
              for (final m in kContraceptionLabels.entries)
                DropdownMenuItem<String?>(value: m.key, child: Text(m.value)),
            ],
            onChanged: (v) => setState(() => _data.contraceptionMethod = v),
          ),
          const SizedBox(height: 16),
          Text(
            'Pregnancy context',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _data.pregnancyContext,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select (optional)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Prefer not to say'),
              ),
              for (final p in kPregnancyContextLabels.entries)
                DropdownMenuItem<String?>(value: p.key, child: Text(p.value)),
            ],
            onChanged: (v) => setState(() => _data.pregnancyContext = v),
          ),
        ],
      ),
    );
  }

  /// Pregnancy STATE (actual pregnancy?). Only an explicit "yes" records
  /// the state for later phases. Interest alone changes nothing.
  Widget _pregnancyStateStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Are you currently pregnant?',
      subtitle:
          'Only an explicit yes records a pregnancy state. Learning or planning leaves everything unchanged. Optional — Skip if unsure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in [
            (true, 'Yes, I am pregnant'),
            (false, 'No, just learning / planning ahead'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    setState(() => _data.isActuallyPregnant = option.$1),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _data.isActuallyPregnant == option.$1
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _data.isActuallyPregnant == option.$1 ? 2 : 1,
                    ),
                  ),
                  child: Text(option.$2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Optional profile basics: birth month/year only (backend-supported).
  /// Height/weight are intentionally NOT asked: the product does not use
  /// them, so per ASK NOW / ASK LATER they stay out of first-run.
  Widget _basicsStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Just the basics',
      subtitle: 'Optional. Helps tailor information by life stage.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: _data.birthMonth,
            decoration: const InputDecoration(
              labelText: 'Birth month (optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('—')),
              for (var i = 0; i < 12; i++)
                DropdownMenuItem<int?>(
                  value: i + 1,
                  child: Text(kMonthNames[i], overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (val) => setState(() {
              _data.birthMonth = val;
              _inlineError = null;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _birthYearController,
            decoration: const InputDecoration(
              labelText: 'Birth year (optional)',
              hintText: 'e.g. 1990',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  /// Ready: personalized-feeling summary + explicit entry. "Enter MenoMate"
  /// submits onboarding; "Create an account" is a small secondary action
  /// for local users only (authenticated users already have one).
  /// Registration is never forced.
  Widget _readyStep(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLocal = ref.watch(isOfflineTrackingProvider);
    final interestCount = _data.interests.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: MenoMateLogo(size: 72)),
          const SizedBox(height: 20),
          Text(
            'You\u2019re all set, ${_data.name.isEmpty ? 'there' : _data.name}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            interestCount == 0
                ? 'Your MenoMate space is ready. As you use it, we\u2019ll learn what matters to you.'
                : 'Your MenoMate space is ready — tuned for ${interestCount == 1 ? 'your focus' : 'your $interestCount focuses'}. As you use it, we\u2019ll learn what matters to you.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enter MenoMate'),
            ),
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: 12),
            Text(
              _inlineError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          if (isLocal) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.push('/login'),
                child: const Text('Create an account to sync your data'),
              ),
            ),
            Text(
              'Optional — your tracking stays on this device until then.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _completionStep(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: MenoMateLogo(size: 72)),
          const SizedBox(height: 20),
          Text(
            'Welcome in!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your information is saved. You can always update it later in Settings.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Router observes profile + completion flag and lands on Home.
              // No manual push: avoids races with redirect.
              refreshAllAppData(ref);
            },
            child: const Text('Go to my Home'),
          ),
          if (ref.watch(isOfflineTrackingProvider)) ...[
            const SizedBox(height: 12),
            Text(
              'Your tracking data stays on this device. You can sign in later to sync it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int index;
  final int total;

  const _ProgressBar({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (index / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              semanticsLabel: 'Onboarding progress, step $index of $total',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Step $index of $total',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

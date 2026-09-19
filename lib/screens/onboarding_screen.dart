import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../providers/onboarding_context_provider.dart';
import '../providers/onboarding_status_provider.dart';
import '../providers/personalization_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

/// Genuine one-question-per-screen onboarding.
///
/// Replaces the old scrolling form entirely. Each step collects ONE
/// meaningful answer with progress, Back/Continue/Skip, validation,
/// keyboard-safe layout and accessibility labels.
///
/// Backend truth:
/// - name, last_period_start/end, usual_cycle/period_days, timezone,
///   units, birth_year/month go to the real backend via the existing
///   repository/API architecture.
/// - contraception_method + pregnancy_context are saved for real via the
///   HealthContext repository AFTER onboarding completes (supported API).
/// - height, weight, goal, regularity, age-range have NO backend field:
///   collected for UX completeness, stored ONLY on-device via
///   [onboardingContextProvider]/[ageRangeProvider], never sent anywhere.
///   See docs/backend_gaps.md. No temperature question exists anywhere.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingData {
  String name = '';
  String? ageRange;
  bool heightMetric = true;
  int heightCm = 165;
  int heightFt = 5;
  int heightIn = 5;
  bool weightMetric = true;
  int weightKg = 62;
  int weightLbs = 137;

  /// Phase 1 personalization (multi-select interests + conditional
  /// follow-ups). Local-only (see personalizationProvider); never sent to
  /// the backend, never drives predictions or modes by itself.
  Set<String> interests = {};
  Set<String> symptomAreas = {};
  Set<String> fertilityPrefs = {};

  /// Explicit actual-pregnancy answer (null = unasked). Only an explicit
  /// `true` may route to pregnancy mode later — the `pregnancy` interest
  /// alone never does.
  bool? isActuallyPregnant;

  String? regularityKey;
  int? cycleLength; // null = not sure
  int? periodLength; // null = not sure
  DateTime? lastStart;
  PeriodStatus status = PeriodStatus.ended;
  DateTime? lastEnd;
  String? contraceptionMethod;
  String? pregnancyContext;
  int? birthMonth;
  String birthYearRaw = '';
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _data = _OnboardingData();
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();

  // ---- Adaptive step model (Phase 1) ----
  //
  // Steps are identified by stable ids, not positions: the visible sequence
  // is derived from the selected interests, so follow-up questions appear
  // only when relevant. Backend-gated steps (last period start/end) are
  // ALWAYS included — the onboarding endpoint requires them — while
  // personalization follow-ups are conditional. Skipped interests (empty
  // set) ask no personalization follow-ups; cycle-length questions stay
  // unconditional because they feed the (nullable) backend payload.
  static const String _sWelcome = 'welcome';
  static const String _sName = 'name';
  static const String _sInterests = 'interests';
  static const String _sAge = 'age';
  static const String _sHeight = 'height';
  static const String _sWeight = 'weight';
  static const String _sRegularity = 'regularity';
  static const String _sCycleLen = 'cycle_len';
  static const String _sPeriodLen = 'period_len';
  static const String _sLastStart = 'last_start';
  static const String _sStatus = 'status';
  static const String _sRepro = 'repro';
  static const String _sSymptomAreas = 'symptom_areas';
  static const String _sFertility = 'fertility';
  static const String _sPregnancy = 'pregnancy';
  static const String _sBirth = 'birth';
  static const String _sDone = 'done';

  int _pos = 0;
  bool _isSubmitting = false;
  String? _inlineError;

  /// Visible step ids for the current interest selection, in order.
  List<String> get _visibleSteps {
    final ids = <String>[
      _sWelcome,
      _sName,
      _sInterests,
      _sAge,
      _sHeight,
      _sWeight,
      _sRegularity,
      _sCycleLen,
      _sPeriodLen,
      _sLastStart,
      _sStatus,
      _sRepro,
    ];
    final personalization = Personalization(interests: _data.interests);
    if (personalization.wantsSymptomAreas) ids.add(_sSymptomAreas);
    if (personalization.wantsFertilityPrefs) ids.add(_sFertility);
    if (personalization.wantsPregnancyState) ids.add(_sPregnancy);
    ids.add(_sBirth);
    ids.add(_sDone);
    return ids;
  }

  String get _currentStep => _visibleSteps[_pos.clamp(0, _visibleSteps.length - 1)];

  @override
  void initState() {
    super.initState();
    // Pre-fill the name from the signup metadata when available so the
    // user is not asked twice. Best-effort: Supabase may be uninitialized
    // in tests, and the backend still requires the name regardless.
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

  /// Jump to a step by id when it is currently visible (no-op otherwise).
  void _goToStep(String id) {
    final at = _visibleSteps.indexOf(id);
    if (at >= 0) _go(at);
  }

  void _next() => _go(_pos + 1);
  void _back() => _go(_pos - 1);

  bool get _isLastContent => _pos == _visibleSteps.length - 2;
  bool get _isCompletion => _pos == _visibleSteps.length - 1;

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
    // Required: name + last-start + status/end (+ birth pair coherence).
    // Cycle/period lengths are always valid (null = not sure). Interest
    // and follow-up steps never block: empty means skipped.
    switch (_currentStep) {
      case _sName:
        if (_nameController.text.trim().isEmpty) {
          setState(() => _inlineError = 'Please enter your name.');
          return false;
        }
        _data.name = _nameController.text.trim();
        return true;
      case _sCycleLen: // always valid (null = not sure)
      case _sPeriodLen:
        return true;
      case _sLastStart:
        if (_data.lastStart == null) {
          setState(
            () => _inlineError = 'Please choose when your last period started.',
          );
          return false;
        }
        if (_data.lastStart!.isAfter(_today())) {
          setState(
            () => _inlineError = 'Start date can\u2019t be in the future.',
          );
          return false;
        }
        return true;
      case _sStatus:
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
          if (_data.lastStart != null &&
              _data.lastEnd!.isBefore(_data.lastStart!)) {
            setState(
              () => _inlineError =
                  'End date can\u2019t be before the start date.',
            );
            return false;
          }
        }
        return true;
      case _sBirth: // birth pair optional but must be both-or-blank
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
        return true;
    }
  }

  void _onContinue() {
    if (!_validateCurrent()) return;
    // Persist local-only context best-effort as the user progresses.
    unawaited(_persistLocalContext());
    if (_isLastContent) {
      unawaited(_submit());
    } else {
      _next();
    }
  }

  Future<void> _persistLocalContext() async {
    try {
      await ref
          .read(ageRangeProvider.notifier)
          .setAgeRange(_data.ageRange)
          .catchError((_) => null);
      final ctx = ref.read(onboardingContextProvider.notifier);
      final heightCm = _data.heightMetric
          ? _data.heightCm
          : ((_data.heightFt * 12 + _data.heightIn) * 2.54).round();
      final weightKg = _data.weightMetric
          ? _data.weightKg
          : (_data.weightLbs / 2.20462).round();
      await ctx.setHeightCm(heightCm).catchError((_) => null);
      await ctx.setWeightKg(weightKg).catchError((_) => null);
      await ctx.setRegularity(_data.regularityKey).catchError((_) => null);
      // Phase 1 personalization (local-only; never sent to any backend).
      final personal = ref.read(personalizationProvider.notifier);
      await personal.setInterests(_data.interests).catchError((_) => null);
      await personal
          .setSymptomAreas(_data.symptomAreas)
          .catchError((_) => null);
      await personal
          .setFertilityPrefs(_data.fertilityPrefs)
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
      // Local-only context never blocks submission (SharedPreferences may
      // be slow/unavailable in tests/devices): fire-and-forget.
      unawaited(_persistLocalContext());

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
        // Jump back to the offending step for correction.
        final firstKey = errors.keys.first;
        String? target;
        if (firstKey == 'name') {
          target = _sName;
        } else if (firstKey == 'start') {
          target = _sLastStart;
        } else if (firstKey == 'end') {
          target = _sStatus;
        } else if (firstKey == 'cycle') {
          target = _sCycleLen;
        } else if (firstKey == 'period') {
          target = _sPeriodLen;
        } else if (firstKey == 'dob') {
          target = _sBirth;
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
        // Save supported reproductive context locally for real.
        await _saveReproductiveContext(userId, localOnly: true);
        // Completion flag is in-memory-first: never block Home on prefs.
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
  /// pregnancy context ARE backend-supported via the health-context API,
  /// so this is genuine persistence — not a fake mode. Skipped when the
  /// user left both blank.
  Future<void> _saveReproductiveContext(
    String userId, {
    required bool localOnly,
  }) async {
    if (_data.contraceptionMethod == null && _data.pregnancyContext == null) {
      return;
    }
    try {
      final repo = ref.read(healthContextRepositoryProvider);
      // Load current (if any) to preserve sibling health_notes.
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

  // ---- UI ----

  /// Widget for one visible step id. Titles of pre-existing steps are
  /// unchanged so existing flows and tests keep working.
  Widget _stepWidget(BuildContext context, String id) {
    switch (id) {
      case _sWelcome:
        return _welcomeStep(context);
      case _sName:
        return _nameStep(context);
      case _sInterests:
        return _interestsStep(context);
      case _sAge:
        return _ageRangeStep(context);
      case _sHeight:
        return _heightStep(context);
      case _sWeight:
        return _weightStep(context);
      case _sRegularity:
        return _regularityStep(context);
      case _sCycleLen:
        return _cycleLengthStep(context);
      case _sPeriodLen:
        return _periodLengthStep(context);
      case _sLastStart:
        return _lastPeriodStep(context);
      case _sStatus:
        return _periodStatusStep(context);
      case _sRepro:
        return _reproductiveStep(context);
      case _sSymptomAreas:
        return _symptomAreasStep(context);
      case _sFertility:
        return _fertilityPrefsStep(context);
      case _sPregnancy:
        return _pregnancyStateStep(context);
      case _sBirth:
        return _birthStep(context);
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
    // The visible list can shrink/grow when interests change: clamp the
    // position and jump the controller so they never disagree.
    if (_pos >= steps.length) {
      _pos = steps.length - 1;
    }

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
                if (_isLastContent) {
                  unawaited(_submit());
                } else {
                  _next();
                }
              },
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(index: _pos + 1, total: steps.length),
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
            if (!_isCompletion) _bottomBar(context, colorScheme),
          ],
        ),
      ),
    );
  }

  bool _isOptionalStep(String id) {
    // Required: welcome (via primary CTA), name, last-start, status, done.
    // Everything else — including interests and every follow-up — is
    // skippable. Skipped interests simply ask no follow-ups.
    return id != _sWelcome &&
        id != _sName &&
        id != _sLastStart &&
        id != _sStatus &&
        id != _sDone;
  }

  void _clearOptionalStep(String id) {
    switch (id) {
      case _sAge:
        _data.ageRange = null;
        break;
      case _sHeight:
      case _sWeight:
        break;
      case _sInterests:
        _data.interests = {};
        _data.symptomAreas = {};
        _data.fertilityPrefs = {};
        _data.isActuallyPregnant = null;
        break;
      case _sRegularity:
        _data.regularityKey = null;
        break;
      case _sCycleLen:
        _data.cycleLength = null;
        break;
      case _sPeriodLen:
        _data.periodLength = null;
        break;
      case _sSymptomAreas:
        _data.symptomAreas = {};
        break;
      case _sFertility:
        _data.fertilityPrefs = {};
        break;
      case _sPregnancy:
        _data.isActuallyPregnant = null;
        break;
      case _sRepro:
        _data.contraceptionMethod = null;
        _data.pregnancyContext = null;
        break;
      case _sBirth:
        _data.birthMonth = null;
        _birthYearController.clear();
        break;
      default:
        break;
    }
    setState(() => _inlineError = null);
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
    // Column (not Row) so long CTA labels like "Complete onboarding"
    // never overflow narrow phones: each button is full-width with a
    // comfortable 48dp+ target.
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
                    : Text(
                        _currentStep == _sWelcome
                            ? 'Let\u2019s get started'
                            : _isLastContent
                            ? 'Complete onboarding'
                            : 'Continue',
                      ),
              ),
            ),
            if (_currentStep != _sWelcome) ...[
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

  // ---- Steps ----

  Widget _welcomeStep(BuildContext context) {
    final theme = Theme.of(context);
    return _stepShell(
      context,
      title: 'Welcome to MenoMate',
      subtitle:
          'A safe, supportive space for your menstrual health and beyond.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: MenoMateLogo(size: 72)),
          const SizedBox(height: 20),
          _benefitRow(
            context,
            Icons.track_changes_outlined,
            'Track your cycle',
          ),
          _benefitRow(
            context,
            Icons.insights_outlined,
            'Gain personalized insights',
          ),
          _benefitRow(context, Icons.spa_outlined, 'Access supportive care'),
          _benefitRow(context, Icons.favorite_outline, 'Feel more in control'),
          const SizedBox(height: 12),
          Text(
            'One question per screen. Skip where optional.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _nameStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What should we call you?',
      subtitle: 'Your name personalizes your Home greeting.',
      child: TextField(
        controller: _nameController,
        autofocus: false,
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

  Widget _ageRangeStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What\u2019s your age range?',
      subtitle:
          'Stored only on this device. You can update it in Profile. Optional.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in kAgeRanges)
            ChoiceChip(
              label: Text(r.label),
              selected: _data.ageRange == r.key,
              onSelected: (sel) =>
                  setState(() => _data.ageRange = sel ? r.key : null),
            ),
        ],
      ),
    );
  }

  Widget _heightStep(BuildContext context) {
    final theme = Theme.of(context);
    return _stepShell(
      context,
      title: 'How tall are you?',
      subtitle: 'Saved on this device for now — sync arrives once the backend supports height. Optional.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('cm')),
              ButtonSegment(value: false, label: Text('ft')),
            ],
            selected: {_data.heightMetric},
            onSelectionChanged: (s) =>
                setState(() => _data.heightMetric = s.first),
          ),
          const SizedBox(height: 16),
          if (_data.heightMetric)
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _data.heightCm,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var cm = 140; cm <= 200; cm++)
                  DropdownMenuItem(value: cm, child: Text('$cm cm')),
              ],
              onChanged: (v) => setState(() => _data.heightCm = v ?? 165),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _data.heightFt,
                  decoration: const InputDecoration(
                    labelText: 'Feet',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var f = 4; f <= 7; f++)
                      DropdownMenuItem(value: f, child: Text('$f ft')),
                  ],
                  onChanged: (v) => setState(() => _data.heightFt = v ?? 5),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _data.heightIn,
                  decoration: const InputDecoration(
                    labelText: 'Inches',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var i = 0; i <= 11; i++)
                      DropdownMenuItem(value: i, child: Text('$i in')),
                  ],
                  onChanged: (v) => setState(() => _data.heightIn = v ?? 5),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'Backend pending: height has no API field yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightStep(BuildContext context) {
    final theme = Theme.of(context);
    return _stepShell(
      context,
      title: 'How much do you weigh?',
      subtitle: 'Saved on this device for now — sync arrives once the backend supports weight. Optional.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('kg')),
              ButtonSegment(value: false, label: Text('lbs')),
            ],
            selected: {_data.weightMetric},
            onSelectionChanged: (s) =>
                setState(() => _data.weightMetric = s.first),
          ),
          const SizedBox(height: 16),
          if (_data.weightMetric)
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _data.weightKg,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var kg = 35; kg <= 150; kg++)
                  DropdownMenuItem(value: kg, child: Text('$kg kg')),
              ],
              onChanged: (v) => setState(() => _data.weightKg = v ?? 62),
            )
          else
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _data.weightLbs,
              decoration: const InputDecoration(
                labelText: 'Weight (lbs)',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var lb = 77; lb <= 330; lb += 1)
                  if (lb % 1 == 0)
                    DropdownMenuItem(value: lb, child: Text('$lb lbs')),
              ],
              onChanged: (v) => setState(() => _data.weightLbs = v ?? 137),
            ),
          const SizedBox(height: 8),
          Text(
            'Backend pending: weight has no API field yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Phase 1 multi-select interests ("What brings you to MenoMate?").
  /// Any subset is valid; empty means skipped. The selection only decides
  /// which follow-up steps appear — it never changes the backend payload,
  /// predictions, or modes. Replaces the old single-choice goal step.
  Widget _interestsStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What brings you to MenoMate?',
      subtitle:
          'You can choose more than one. You can change these later. Skip for now if you prefer.',
      child: Column(
        children: [
          for (final interest in kUserInterests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() {
                  final next = Set<String>.from(_data.interests);
                  if (next.contains(interest.key)) {
                    next.remove(interest.key);
                  } else {
                    next.add(interest.key);
                  }
                  _data.interests = next;
                  // Keep follow-ups consistent with the new selection:
                  // answers for unselected areas are cleared so stale
                  // preferences can never leak into personalization.
                  final view = Personalization(interests: next);
                  if (!view.wantsSymptomAreas) _data.symptomAreas = {};
                  if (!view.wantsFertilityPrefs) _data.fertilityPrefs = {};
                  if (!view.wantsPregnancyState) {
                    _data.isActuallyPregnant = null;
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _data.interests.contains(interest.key)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _data.interests.contains(interest.key) ? 2 : 1,
                    ),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _data.interests.contains(interest.key)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              interest.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              interest.description,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Body-awareness follow-up: which areas interest the user. Shown only
  /// when the body_awareness interest is selected. Interest flags only —
  /// implies no condition or diagnosis, ever.
  Widget _symptomAreasStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Which areas interest you most?',
      subtitle:
          'Pick any. This shapes what MenoMate highlights — nothing is diagnosed. Optional.',
      child: Wrap(
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
    );
  }

  /// Fertility/TTC follow-up: which signs the user wants to track. Shown
  /// only when fertility_awareness or trying_to_conceive is selected.
  /// Pure logging preferences — the backend remains the sole estimator
  /// and nothing is calculated on this device.
  Widget _fertilityPrefsStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Want to track fertility signs?',
      subtitle:
          'Pick any. MenoMate only records what you log — estimates always come from the server. Optional.',
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  /// Pregnancy STATE question (actual pregnancy?). Shown only when the
  /// pregnancy interest is selected. An explicit "yes" records the state
  /// for later phases — nothing is activated automatically here, and
  /// selecting the interest alone changes nothing.
  Widget _pregnancyStateStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Are you currently pregnant?',
      subtitle:
          'Only an explicit yes records a pregnancy state. Learning about pregnancy leaves everything unchanged. Optional — Skip if unsure.',
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

  Widget _regularityStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Are your periods regular?',
      subtitle: 'A rough sense is fine. Optional.',
      child: Column(
        children: [
          for (final o in kPeriodRegularityOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _data.regularityKey = o.$1),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _data.regularityKey == o.$1
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _data.regularityKey == o.$1 ? 2 : 1,
                    ),
                  ),
                  child: Text(o.$2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cycleLengthStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Usual cycle length?',
      subtitle:
          'Days between period starts (20–45). Leave as Not sure if unsure.',
      child: Column(
        children: [
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: _data.cycleLength,
            decoration: const InputDecoration(
              labelText: 'Cycle length',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Not sure'),
              ),
              for (var d = 20; d <= 45; d++)
                DropdownMenuItem<int?>(value: d, child: Text('$d days')),
            ],
            onChanged: (v) => setState(() => _data.cycleLength = v),
          ),
        ],
      ),
    );
  }

  Widget _periodLengthStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Usual period length?',
      subtitle: 'Days bleeding lasts (1–12). Leave as Not sure if unsure.',
      child: DropdownButtonFormField<int?>(
        isExpanded: true,
        initialValue: _data.periodLength,
        decoration: const InputDecoration(
          labelText: 'Period length',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Not sure')),
          for (var d = 1; d <= 12; d++)
            DropdownMenuItem<int?>(value: d, child: Text('$d days')),
        ],
        onChanged: (v) => setState(() => _data.periodLength = v),
      ),
    );
  }

  Widget _lastPeriodStep(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return _stepShell(
      context,
      title: 'When did your last period start?',
      subtitle: 'Pick the date. If you don\u2019t remember, use today as approximate.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
      ),
    );
  }

  Widget _periodStatusStep(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return _stepShell(
      context,
      title: 'Has your last period ended?',
      subtitle: 'Choose Ongoing or pick when it ended.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
      ),
    );
  }

  Widget _reproductiveStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Relevant reproductive context?',
      subtitle: 'Saved for real to your health profile when provided. Optional — Skip to continue.',
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

  Widget _birthStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'Birth month & year?',
      subtitle: 'Optional. Both together or both blank.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: _data.birthMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
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
              labelText: 'Year',
              hintText: 'e.g. 1990',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
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
            'You\u2019re all set!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MenoMate is ready to support you. You can always update your information later in Settings.',
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
              semanticsLabel:
                  'Onboarding progress, step $index of $total',
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../models/onboarding.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/onboarding_context_provider.dart';
import '../providers/onboarding_status_provider.dart';
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
  String? goalKey;
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

  int _index = 0;
  bool _isSubmitting = false;
  String? _inlineError;

  static const int _totalSteps = 13; // 0..12 content + completion

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
    setState(() {
      _index = next.clamp(0, _totalSteps);
      _inlineError = null;
    });
    _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() => _go(_index + 1);
  void _back() => _go(_index - 1);

  bool get _isLastContent => _index == _totalSteps - 1;
  bool get _isCompletion => _index == _totalSteps;

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
    // Step indices: 0 welcome, 1 name, 2 age, 3 height, 4 weight, 5 goal,
    // 6 regularity, 7 cycle, 8 period, 9 last-start, 10 status/end,
    // 11 reproductive, 12 birth, 13 completion.
    switch (_index) {
      case 1: // name
        if (_nameController.text.trim().isEmpty) {
          setState(() => _inlineError = 'Please enter your name.');
          return false;
        }
        _data.name = _nameController.text.trim();
        return true;
      case 7: // cycle length: always valid (null = not sure)
      case 8: // period length
        return true;
      case 9: // last start required
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
      case 10: // end date when ended
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
      case 12: // birth pair optional but must be both-or-blank
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
      await ctx.setGoal(_data.goalKey).catchError((_) => null);
      await ctx.setRegularity(_data.regularityKey).catchError((_) => null);
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
        int target = _index;
        if (firstKey == 'name') {
          target = 1;
        } else if (firstKey == 'start') {
          target = 9;
        } else if (firstKey == 'end') {
          target = 10;
        } else if (firstKey == 'cycle') {
          target = 7;
        } else if (firstKey == 'period') {
          target = 8;
        } else if (firstKey == 'dob') {
          target = 12;
        }
        setState(() {
          _isSubmitting = false;
          _inlineError = errors.values.first;
        });
        _go(target);
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
        if (mounted) _go(_totalSteps);
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
      if (mounted) _go(_totalSteps);
    } on ValidationError catch (e) {
      _showMessage('Please check your entries. ${e.message}');
    } on Conflict catch (e) {
      try {
        await ref.read(profileProvider.notifier).reload();
        unawaited(ref.read(onboardingStatusProvider.notifier).markCompleted());
      } catch (_) {}
      _showMessage(e.message);
      if (mounted) _go(_totalSteps);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting started'),
        leading: _index > 0 && !_isCompletion
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: _back,
              )
            : null,
        actions: [
          if (_isOptionalStep(_index) && !_isCompletion)
            TextButton(
              onPressed: () {
                _clearOptionalStep(_index);
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
            _ProgressBar(index: _index, total: _totalSteps + 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _welcomeStep(context),
                  _nameStep(context),
                  _ageRangeStep(context),
                  _heightStep(context),
                  _weightStep(context),
                  _goalStep(context),
                  _regularityStep(context),
                  _cycleLengthStep(context),
                  _periodLengthStep(context),
                  _lastPeriodStep(context),
                  _periodStatusStep(context),
                  _reproductiveStep(context),
                  _birthStep(context),
                  _completionStep(context),
                ],
              ),
            ),
            if (!_isCompletion) _bottomBar(context, colorScheme),
          ],
        ),
      ),
    );
  }

  bool _isOptionalStep(int i) {
    // Required: welcome(0) via primary CTA, name(1), last-start(9),
    // status(10). Completion(13) has no Back/Skip. All others skippable.
    return !(i == 0 || i == 1 || i == 9 || i == 10 || i == 13);
  }

  void _clearOptionalStep(int i) {
    switch (i) {
      case 2:
        _data.ageRange = null;
        break;
      case 3:
        break;
      case 4:
        break;
      case 5:
        _data.goalKey = null;
        break;
      case 6:
        _data.regularityKey = null;
        break;
      case 7:
        _data.cycleLength = null;
        break;
      case 8:
        _data.periodLength = null;
        break;
      case 11:
        _data.contraceptionMethod = null;
        _data.pregnancyContext = null;
        break;
      case 12:
        _data.birthMonth = null;
        _birthYearController.clear();
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
                        _index == 0
                            ? 'Let\u2019s get started'
                            : _isLastContent
                            ? 'Complete onboarding'
                            : 'Continue',
                      ),
              ),
            ),
            if (_index > 0) ...[
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

  Widget _goalStep(BuildContext context) {
    return _stepShell(
      context,
      title: 'What\u2019s your main goal with MenoMate?',
      subtitle: 'Pick one. Only tracking + learning are active today.',
      child: Column(
        children: [
          for (final g in kOnboardingGoals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _data.goalKey = g.key),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _data.goalKey == g.key
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _data.goalKey == g.key ? 2 : 1,
                    ),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _data.goalKey == g.key
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              g.description,
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
    final progress = ((index + 1) / (total + 1)).clamp(0.0, 1.0);
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
                  'Onboarding progress, step ${index + 1} of ${total + 1}',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${index + 1} of ${total + 1}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

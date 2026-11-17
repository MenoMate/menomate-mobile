import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/sync_policy.dart';
import '../core/theme.dart';
import '../models/daily_log.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/offline_banner.dart';

class SymptomLoggerScreen extends ConsumerStatefulWidget {
  /// ISO `yyyy-MM-dd` date this logger edits. Defaults to today.
  /// History/calendar passes the selected day so saved logs are
  /// discoverable and editable in place — same record per user+date,
  /// never a duplicate.
  final String? initialDate;

  const SymptomLoggerScreen({super.key, this.initialDate});

  @override
  ConsumerState<SymptomLoggerScreen> createState() =>
      _SymptomLoggerScreenState();
}

class _SymptomLoggerScreenState extends ConsumerState<SymptomLoggerScreen> {
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  DataState<DailyLogResponse?>? _loadState;

  /// Whether a saved log existed when this screen opened. A save that
  /// creates the record resets the form; a save that edits keeps values.
  bool _existedAtOpen = false;

  /// Null = not logged (no fake selection is ever displayed).
  int? _pain;

  /// Multi-select moods (canonical ids). Empty = not logged.
  final Set<String> _moods = {};

  /// Single-select, nullable. Tapping the selected option deselects it.
  String? _flow;
  String? _discharge;

  /// Selected symptom ids (canonical backend ids) + per-symptom severity.
  /// Severity defaults to 0 (present, unrated) until the stepper moves.
  final Set<String> _symptoms = {};
  final Map<String, int> _severities = {};

  /// Canonical mood vocabulary (backend MoodEnum). Order is display order.
  static const List<String> _moodOptions = [
    'happy',
    'calm',
    'neutral',
    'sad',
    'irritable',
    'anxious',
    'tired',
  ];

  /// Single-selection flow (backend FlowEnum minus the retired `none`:
  /// unselected now means "not recorded").
  static const List<String> _flowOptions = [
    'spotting',
    'light',
    'medium',
    'heavy',
  ];

  late String _dateString;

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    _dateString = (initial != null && _isoDate.hasMatch(initial))
        ? initial
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDailyLog();
  }

  Future<void> _loadDailyLog() async {
    final userId = ref.read(currentUserIdProvider);
    final offline = ref.read(isOfflineTrackingProvider);
    DataState<DailyLogResponse?> state = const Unavailable('Signed out.');
    if (userId != null) {
      try {
        final repo = ref.read(dailyLogRepositoryProvider);
        state = offline
            ? await repo.loadLogLocal(userId, _dateString)
            : await repo.loadLog(userId, _dateString);
      } catch (_) {
        state = const Unavailable('Couldn\'t load this log.');
      }
    }

    if (!mounted) return;
    final log = state.dataOrNull;
    setState(() {
      _loadState = state;
      _existedAtOpen = log != null;
      if (log != null) {
        _pain = log.pain;
        _moods
          ..clear()
          ..addAll((log.mood ?? []).where(_moodOptions.contains));
        // Legacy flow `none` (retired) reads as unselected: unselected
        // now means "not recorded", which is exactly what `none` meant.
        _flow = _flowOptions.contains(log.flow) ? log.flow : null;
        // Legacy discharge values outside the qualitative vocabulary
        // render as unselected — never reinterpreted, never crashed on.
        _discharge = kDischargeOptions.any((d) => d.id == log.discharge)
            ? log.discharge
            : null;
        _symptoms
          ..clear()
          ..addAll(log.symptoms.map((s) => s.symptomType));
        _severities
          ..clear()
          ..addEntries(
            log.symptoms.map((s) => MapEntry(s.symptomType, s.severity)),
          );
        _notesController.text = log.notes ?? '';
      }
      _isLoading = false;
    });
  }

  void _resetForm() {
    _pain = null;
    _moods.clear();
    _flow = null;
    _discharge = null;
    _symptoms.clear();
    _severities.clear();
    _notesController.clear();
  }

  String _prettyDate() {
    try {
      return DateFormat('EEEE, MMMM d').format(DateTime.parse(_dateString));
    } catch (_) {
      return _dateString;
    }
  }

  Future<void> _saveLog() async {
    final userId = ref.read(currentUserIdProvider);
    final offline = ref.read(isOfflineTrackingProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in or continue offline to save your log.'),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final payload = DailyLogCreate(
      logDate: _dateString,
      pain: _pain,
      // Canonical order keeps the stored array deterministic.
      mood: _moods.isEmpty
          ? null
          : [
              for (final m in _moodOptions)
                if (_moods.contains(m)) m,
            ],
      flow: _flow,
      discharge: _discharge,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      symptoms: [
        for (final id in _symptoms)
          SymptomItem(symptomType: id, severity: _severities[id] ?? 0),
      ],
    );

    // Local-first: the entry is persisted before any network attempt, so
    // an offline save is never lost. Same user+date always updates the
    // same local/server record — never a duplicate.
    final wasCreate = !_existedAtOpen;
    DataState<DailyLogResponse> result;
    try {
      result = await ref
          .read(dailyLogRepositoryProvider)
          .saveLog(userId, payload, localOnly: offline);
    } catch (_) {
      result = const Unavailable('Couldn\'t save right now.');
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _loadState = result;
      if (wasCreate &&
          (result is Fresh<DailyLogResponse> ||
              result is PendingSync<DailyLogResponse>)) {
        // A fresh create resets the form; the record now exists, so any
        // further save edits it rather than looking like a new entry.
        _resetForm();
        _existedAtOpen = true;
      }
    });

    // Explicit result: where the data went is never ambiguous. The screen
    // stays open so the pending/not-synced state remains visible offline.
    switch (result) {
      case Fresh():
        refreshAllAppData(ref);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Daily log saved')));
      case PendingSync():
        refreshAllAppData(ref);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved on this device')));
      case ConflictState(message: final m):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved on this device, needs review: $m')),
        );
      case Unavailable(message: final m):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      case NoData():
      case Cached():
        refreshAllAppData(ref);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // One coherent selection language: indigo interaction treatment in
    // both modes. Category meaning lives in the section icon, not in
    // per-category selection colors.
    final selectedFill = MenoMateTheme.interactionColor(isDark);
    final cycleAccent = isDark
        ? MenoMateTheme.starryPrimary
        : MenoMateTheme.sakuraPrimaryDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Check-In',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadState != null) SyncStatusChip(state: _loadState!),
            Text(
              _existedAtOpen
                  ? '${_prettyDate()} · editing saved log'
                  : '${_prettyDate()} · how are you feeling today?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),

            _buildGroupLabel('Cycle', context),
            const SizedBox(height: 12),
            _buildFieldLabel(
              context,
              Icons.water_drop_outlined,
              'Menstrual flow',
              cycleAccent,
            ),
            const SizedBox(height: 8),
            _buildChipWrap<String>(
              values: _flowOptions,
              isSelected: (v) => v == _flow,
              // Tapping the selected option deselects it; tapping another
              // moves the single selection. Never multi-select.
              onTap: (v) => setState(() => _flow = _flow == v ? null : v),
              labelOf: _capitalize,
              selectedFill: selectedFill,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel(
              context,
              Icons.opacity_outlined,
              'Discharge',
              cycleAccent,
            ),
            const SizedBox(height: 8),
            _buildChipWrap<DischargeOption>(
              values: kDischargeOptions,
              isSelected: (d) => d.id == _discharge,
              onTap: (d) =>
                  setState(() => _discharge = _discharge == d.id ? null : d.id),
              labelOf: (d) => d.label,
              selectedFill: selectedFill,
            ),
            const SizedBox(height: 20),

            _buildGroupLabel('Wellbeing', context),
            const SizedBox(height: 12),
            _buildFieldLabel(
              context,
              Icons.sentiment_satisfied_outlined,
              'Mood',
              null,
            ),
            const SizedBox(height: 8),
            _buildChipWrap<String>(
              values: _moodOptions,
              isSelected: (v) => _moods.contains(v),
              // Independent toggles: zero, one, or several moods are valid.
              onTap: (v) => setState(() {
                if (!_moods.remove(v)) _moods.add(v);
              }),
              labelOf: _capitalize,
              selectedFill: selectedFill,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel(context, Icons.healing_outlined, 'Symptoms', null),
            const SizedBox(height: 8),
            _buildChipWrap<LoggableSymptom>(
              values: kLoggableSymptoms,
              isSelected: (s) => _symptoms.contains(s.id),
              onTap: (s) => setState(() {
                if (_symptoms.remove(s.id)) {
                  _severities.remove(s.id);
                } else {
                  _symptoms.add(s.id);
                  _severities[s.id] = 0;
                }
              }),
              labelOf: (s) => s.label,
              selectedFill: selectedFill,
            ),
            if (_symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final sym in kLoggableSymptoms.where(
                (s) => _symptoms.contains(s.id),
              ))
                _buildSeverityRow(sym, context, selectedFill),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFieldLabel(context, Icons.speed_outlined, 'Pain', null),
                const Spacer(),
                if (_pain != null)
                  Text(
                    _pain.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  )
                else
                  Text(
                    'Not logged',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.secondary,
                    ),
                  ),
                if (_pain != null)
                  TextButton(
                    onPressed: () => setState(() => _pain = null),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            Slider(
              value: (_pain ?? 0).toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: _pain?.toString(),
              activeColor: selectedFill,
              inactiveColor: colorScheme.outline,
              onChanged: (v) => setState(() => _pain = v.round()),
            ),
            const SizedBox(height: 20),

            _buildGroupLabel('Optional', context),
            const SizedBox(height: 12),
            _buildFieldLabel(context, Icons.edit_note_outlined, 'Notes', null),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                // Notes stay personal history only — the hint no longer
                // invites symptom content Care cannot use.
                hintText: 'Personal notes for your own records',
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  Widget _buildGroupLabel(String label, BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildFieldLabel(
    BuildContext context,
    IconData icon,
    String label,
    Color? iconColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor ?? colorScheme.secondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Compact toggle chip row: one selection language everywhere.
  /// Unselected = theme surface + warm-neutral outline + normal text.
  /// Selected = indigo interaction fill + white text.
  Widget _buildChipWrap<T>({
    required List<T> values,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
    required String Function(T) labelOf,
    required Color selectedFill,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          Builder(
            builder: (context) {
              final selected = isSelected(value);
              return GestureDetector(
                onTap: () => onTap(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedFill : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? selectedFill : colorScheme.outline,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    labelOf(value),
                    style: TextStyle(
                      color: selected ? Colors.white : colorScheme.onSurface,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSeverityRow(
    LoggableSymptom symptom,
    BuildContext context,
    Color accent,
  ) {
    final severity = _severities[symptom.id] ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    Widget stepper(IconData icon, VoidCallback? onPressed) {
      return IconButton(
        icon: Icon(icon, size: 20),
        color: colorScheme.onSurface,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${symptom.label} severity',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
          stepper(
            Icons.remove_circle_outline,
            severity > 0
                ? () => setState(() => _severities[symptom.id] = severity - 1)
                : null,
          ),
          Text(
            severity.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          stepper(
            Icons.add_circle_outline,
            severity < 10
                ? () => setState(() => _severities[symptom.id] = severity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

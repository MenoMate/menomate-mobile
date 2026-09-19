import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart' show todayIso;
import '../data/repositories/reproductive_repository.dart';
import '../data/sync_policy.dart';
import '../models/reproductive.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/reproductive_providers.dart';
import '../widgets/offline_banner.dart';

/// Fertility-sign logging for one date (Phase 2 observations).
///
/// Records the three supported observation types through an understandable
/// flow without disturbing period/symptom/daily logging:
/// - LH test (positive / negative / invalid)
/// - Basal body temperature (°C, backend range enforced authoritatively)
/// - Cervical mucus (dedicated fertility scale — never conflated with the
///   generic daily-log `discharge` symptom)
///
/// Each type is its own card with its own save: re-saving a type overwrites
/// that date+type deterministically (backend upsert), never duplicating.
/// Offline saves persist locally as pending and sync on the next pass.
/// The backend remains authoritative for validation; its errors surface
/// verbatim instead of silently discarding failed submissions.
class FertilityLogScreen extends ConsumerStatefulWidget {
  /// ISO `yyyy-MM-dd` date this logger edits. Defaults to today.
  final String? initialDate;

  const FertilityLogScreen({super.key, this.initialDate});

  @override
  ConsumerState<FertilityLogScreen> createState() => _FertilityLogScreenState();
}

class _FertilityLogScreenState extends ConsumerState<FertilityLogScreen> {
  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  late String _dateString;

  String? _lhResult;
  final _bbtController = TextEditingController();
  String? _mucusCategory;
  final _noteControllers = {
    ObservationTypes.lhTest: TextEditingController(),
    ObservationTypes.bbt: TextEditingController(),
    ObservationTypes.cervicalMucus: TextEditingController(),
  };

  String? _bbtError;
  bool _savingLh = false;
  bool _savingBbt = false;
  bool _savingMucus = false;
  final _initializedTypes = <String>{};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    final today = todayIso();
    var date = (initial != null && _isoDate.hasMatch(initial))
        ? initial
        : today;
    // Observation dates can't be in the future: clamp a future deep link
    // to today rather than rendering an unsavable form.
    if (date.compareTo(today) > 0) date = today;
    _dateString = date;
  }

  @override
  void dispose() {
    _bbtController.dispose();
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromSaved(List<FertilityObservation> all) {
    for (final o in filterObservations(all, observationDate: _dateString)) {
      if (_initializedTypes.contains(o.observationType)) continue;
      _initializedTypes.add(o.observationType);
      switch (o.observationType) {
        case ObservationTypes.lhTest:
          _lhResult = o.lhResult;
        case ObservationTypes.bbt:
          if (o.bbtCelsius != null) {
            _bbtController.text = o.bbtCelsius!.toStringAsFixed(2);
          }
        case ObservationTypes.cervicalMucus:
          _mucusCategory = o.mucusCategory;
      }
      _noteControllers[o.observationType]?.text = o.note ?? '';
    }
  }

  String _prettyDate() {
    try {
      return DateFormat('EEEE, MMMM d').format(DateTime.parse(_dateString));
    } catch (_) {
      return _dateString;
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final initial = DateTime.tryParse(_dateString) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) {
      setState(() {
        _dateString =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
        _initializedTypes.clear();
        _lhResult = null;
        _bbtController.clear();
        _mucusCategory = null;
        _bbtError = null;
        for (final c in _noteControllers.values) {
          c.clear();
        }
      });
    }
  }

  String? _cleanNote(String type) {
    final text = _noteControllers[type]?.text.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveLh() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _showMessage('Sign in or continue offline to save.');
      return;
    }
    if (_lhResult == null) {
      _showMessage('Please choose the LH test result first.');
      return;
    }
    setState(() => _savingLh = true);
    try {
      final result = await ref
          .read(reproductiveRepositoryProvider)
          .saveObservation(
            userId,
            observationDate: _dateString,
            observationType: ObservationTypes.lhTest,
            lhResult: _lhResult,
            note: _cleanNote(ObservationTypes.lhTest),
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      _showMessage(_savedMessage(result));
    } on ValidationError catch (e) {
      _showMessage(e.message);
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t save right now.');
    } finally {
      if (mounted) setState(() => _savingLh = false);
    }
  }

  Future<void> _saveBbt() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _showMessage('Sign in or continue offline to save.');
      return;
    }
    final raw = _bbtController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite) {
      setState(() => _bbtError = 'Please enter the measured temperature.');
      return;
    }
    final rounded = (value * 100).round() / 100;
    setState(() => _bbtError = null);
    setState(() => _savingBbt = true);
    try {
      final result = await ref
          .read(reproductiveRepositoryProvider)
          .saveObservation(
            userId,
            observationDate: _dateString,
            observationType: ObservationTypes.bbt,
            bbtCelsius: rounded,
            note: _cleanNote(ObservationTypes.bbt),
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      _showMessage(_savedMessage(result));
    } on ValidationError catch (e) {
      setState(() => _bbtError = e.message);
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t save right now.');
    } finally {
      if (mounted) setState(() => _savingBbt = false);
    }
  }

  Future<void> _saveMucus() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _showMessage('Sign in or continue offline to save.');
      return;
    }
    if (_mucusCategory == null) {
      _showMessage('Please choose the observed category first.');
      return;
    }
    setState(() => _savingMucus = true);
    try {
      final result = await ref
          .read(reproductiveRepositoryProvider)
          .saveObservation(
            userId,
            observationDate: _dateString,
            observationType: ObservationTypes.cervicalMucus,
            mucusCategory: _mucusCategory,
            note: _cleanNote(ObservationTypes.cervicalMucus),
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      _showMessage(_savedMessage(result));
    } on ValidationError catch (e) {
      _showMessage(e.message);
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t save right now.');
    } finally {
      if (mounted) setState(() => _savingMucus = false);
    }
  }

  String _savedMessage(DataState<FertilityObservation> result) {
    return switch (result) {
      PendingSync() => 'Saved on this device. Will sync when online.',
      ConflictState(message: final m) =>
        'Saved on this device, needs review: $m',
      _ => 'Fertility sign saved.',
    };
  }

  Future<void> _deleteType(String type) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _showMessage('Sign in or continue offline to delete.');
      return;
    }
    final state = ref.read(observationsProvider).value;
    final saved = state == null
        ? null
        : filterObservations(
            state.dataOrNull ?? const [],
            observationDate: _dateString,
            observationType: type,
          ).firstOrNull;
    if (saved?.localId == null) return;
    try {
      await ref
          .read(reproductiveRepositoryProvider)
          .deleteObservation(
            userId,
            saved!.localId!,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      if (mounted) {
        setState(() {
          switch (type) {
            case ObservationTypes.lhTest:
              _lhResult = null;
            case ObservationTypes.bbt:
              _bbtController.clear();
            case ObservationTypes.cervicalMucus:
              _mucusCategory = null;
          }
          _noteControllers[type]?.clear();
        });
      }
      _showMessage('Entry removed.');
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t remove right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final observationsAsync = ref.watch(observationsProvider);

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
          'Fertility signs',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: observationsAsync.when(
        data: (state) {
          _initFromSaved(state.dataOrNull ?? const []);
          final savedForDate = filterObservations(
            state.dataOrNull ?? const [],
            observationDate: _dateString,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state is! NoData) SyncStatusChip(state: state),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _prettyDate(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record what you measured. A test result is an observation only — it never confirms anything by itself.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _ObservationCard(
                  icon: Icons.science_outlined,
                  title: 'LH test',
                  subtitle: 'Ovulation test strip result, as observed.',
                  saved: savedForDate
                      .where(
                        (o) => o.observationType == ObservationTypes.lhTest,
                      )
                      .firstOrNull,
                  isSaving: _savingLh,
                  onSave: _saveLh,
                  onDelete: () => _deleteType(ObservationTypes.lhTest),
                  input: _ChipOptions<String>(
                    values: LhResults.all,
                    labels: kLhResultLabels,
                    selected: _lhResult,
                    onSelected: (v) =>
                        setState(() => _lhResult = _lhResult == v ? null : v),
                    semanticPrefix: 'LH result',
                  ),
                  noteController: _noteControllers[ObservationTypes.lhTest]!,
                ),
                _ObservationCard(
                  icon: Icons.thermostat_outlined,
                  title: 'Basal body temperature',
                  subtitle: 'Morning resting temperature in °C.',
                  saved: savedForDate
                      .where((o) => o.observationType == ObservationTypes.bbt)
                      .firstOrNull,
                  isSaving: _savingBbt,
                  onSave: _saveBbt,
                  onDelete: () => _deleteType(ObservationTypes.bbt),
                  input: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _bbtController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Temperature (°C)',
                          hintText: 'e.g. 36.60',
                          errorText: _bbtError,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accepted range 35.00–42.00 °C.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  noteController: _noteControllers[ObservationTypes.bbt]!,
                ),
                _ObservationCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Cervical mucus',
                  subtitle: 'Fertility observation — separate from discharge logging.',
                  saved: savedForDate
                      .where(
                        (o) =>
                            o.observationType == ObservationTypes.cervicalMucus,
                      )
                      .firstOrNull,
                  isSaving: _savingMucus,
                  onSave: _saveMucus,
                  onDelete: () => _deleteType(ObservationTypes.cervicalMucus),
                  input: _ChipOptions<String>(
                    values: MucusCategories.all,
                    labels: kMucusCategoryLabels,
                    selected: _mucusCategory,
                    onSelected: (v) => setState(
                      () => _mucusCategory = _mucusCategory == v ? null : v,
                    ),
                    semanticPrefix: 'Mucus category',
                  ),
                  noteController:
                      _noteControllers[ObservationTypes.cervicalMucus]!,
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _StateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Couldn\u2019t load fertility signs',
          detail: '$err',
          onRetry: () => refreshReproductiveData(ref),
        ),
      ),
    );
  }
}

/// One observation-type card: current saved value (if any), input, optional
/// note, save + remove actions. Same card language as the rest of the app.
class _ObservationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final FertilityObservation? saved;
  final Widget input;
  final TextEditingController noteController;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const _ObservationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.saved,
    required this.input,
    required this.noteController,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (saved != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Saved: ${saved!.valueLabel}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: colorScheme.secondary),
          ),
          const SizedBox(height: 12),
          input,
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Anything to remember',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
              if (saved != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  child: const Text('Remove'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Single-select chips with semantic labels. Tapping the selected option
/// deselects it. Meaning never rests on color alone (label text always
/// present, selected state also bold).
class _ChipOptions<T> extends StatelessWidget {
  final List<T> values;
  final Map<T, String> labels;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String semanticPrefix;

  const _ChipOptions({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.semanticPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          Builder(
            builder: (context) {
              final isSelected = value == selected;
              return GestureDetector(
                onTap: () => onSelected(value),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: '$semanticPrefix: ${labels[value]}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    // The button node already announces the full
                    // "$prefix: $option" label; the visible text is
                    // excluded so screen readers hear it exactly once.
                    child: ExcludeSemantics(
                      child: Text(
                        labels[value] ?? '$value',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRetry;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colorScheme.secondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

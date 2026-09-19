import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/sync_policy.dart';
import '../models/reproductive.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/reproductive_providers.dart';
import '../widgets/offline_banner.dart';

/// Explicit user-controlled pregnancy mode (Phase 3).
///
/// Entered and exited only by the user's own actions here — never by model
/// inference. A late period, symptom pattern, or estimate never activates
/// it, and the UI never suggests otherwise.
///
/// The user can view context, activate mode with dating information, see
/// dating provenance (user-friendly labels, never raw backend codes), see
/// the server-provided EDD and gestational age (never client-calculated),
/// deactivate (history retained), or erase (explicit exit with erasure).
/// Activating or updating never deletes historical periods, cycles,
/// observations, logs, or symptoms: it is a context change only.
class PregnancyModeScreen extends ConsumerStatefulWidget {
  const PregnancyModeScreen({super.key});

  @override
  ConsumerState<PregnancyModeScreen> createState() =>
      _PregnancyModeScreenState();
}

class _PregnancyModeScreenState extends ConsumerState<PregnancyModeScreen> {
  final _noteController = TextEditingController();

  String? _datingSource;
  String? _edd;
  String? _lmp;
  String? _confirmation;
  bool _formInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _initForm(PregnancyContext? context) {
    if (_formInitialized) return;
    _datingSource = context?.datingSource;
    _edd = context?.estimatedDueDate;
    _lmp = context?.lmpDate;
    _confirmation = context?.confirmationDate;
    _noteController.text = context?.datingNote ?? '';
    _formInitialized = true;
  }

  String? _clean(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<String?> _pickDate(
    String? current, {
    required bool allowFuture,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = current == null
        ? today
        : (DateTime.tryParse(current) ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: !allowFuture && initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2020),
      lastDate: allowFuture
          ? DateTime(today.year + 1, today.month, today.day)
          : today,
    );
    if (picked == null) return null;
    return '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _showMessage('Sign in or continue offline to save.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(reproductiveRepositoryProvider)
          .savePregnancyPut(
            userId,
            PregnancyContext(
              userId: userId,
              isActive: true,
              datingSource: _datingSource,
              estimatedDueDate: _edd,
              lmpDate: _lmp,
              confirmationDate: _confirmation,
              datingNote: _clean(_noteController),
            ),
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      refreshAllAppData(ref);
      if (mounted) _showMessage(_savedMessage(result));
    } on ValidationError catch (e) {
      _showMessage(e.message);
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t save right now.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _savedMessage(DataState<PregnancyContext> result) {
    return switch (result) {
      PendingSync() => 'Saved on this device. Will sync when online.',
      ConflictState(message: final m) =>
        'Saved on this device, needs review: $m',
      _ => 'Pregnancy mode updated.',
    };
  }

  Future<void> _deactivate() async {
    final confirmed = await _confirmDialog(
      title: 'Pause pregnancy mode?',
      body: 'Your dating information is kept. Fertility estimates resume their usual behavior.',
      confirmLabel: 'Pause',
    );
    if (confirmed != true) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || !mounted) return;
    try {
      await ref
          .read(reproductiveRepositoryProvider)
          .deactivatePregnancy(
            userId,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      refreshAllAppData(ref);
      _showMessage('Pregnancy mode paused. History kept.');
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t pause right now.');
    }
  }

  Future<void> _erase() async {
    final confirmed = await _confirmDialog(
      title: 'Erase pregnancy history?',
      body: 'This permanently removes the stored pregnancy context. Periods, cycles, and logs are kept. This needs a connection.',
      confirmLabel: 'Erase',
      destructive: true,
    );
    if (confirmed != true) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || !mounted) return;
    try {
      await ref.read(reproductiveRepositoryProvider).deletePregnancy(userId);
      refreshReproductiveData(ref);
      refreshAllAppData(ref);
      if (mounted) {
        setState(() {
          _formInitialized = false;
          _datingSource = null;
          _edd = null;
          _lmp = null;
          _confirmation = null;
          _noteController.clear();
        });
      }
      _showMessage('Pregnancy history erased.');
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage(
        'Couldn\u2019t erase right now. Connect and try again — nothing was removed.',
      );
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: colorScheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pregnancyAsync = ref.watch(pregnancyProvider);

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
          'Pregnancy mode',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: pregnancyAsync.when(
        data: (state) {
          _initForm(state.dataOrNull);
          final current = state.dataOrNull;
          final active = current?.isActive == true;
          final conflictMessage = switch (state) {
            ConflictState(message: final m) => m,
            _ => null,
          };
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state is! NoData) SyncStatusChip(state: state),
                if (conflictMessage != null)
                  _NoticeBanner(
                    icon: Icons.warning_amber_rounded,
                    text: conflictMessage,
                    isError: true,
                  ),
                if (active && current != null)
                  _ContextSummaryCard(context: current, formatDate: _formatDate)
                else
                  _OffCard(hasHistory: current != null && current.hasDating),
                const SizedBox(height: 16),
                Text(
                  active
                      ? 'Update dating information'
                      : 'Turn on pregnancy mode',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pregnancy mode turns on only when you save here. '
                  'MenoMate never turns it on from late periods, symptoms, or estimates. '
                  'Saving keeps your periods, cycles, and logs — it only changes context.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  colorScheme,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DropdownRow(
                        label: 'Dating source',
                        value: _datingSource,
                        items: {
                          for (final v in DatingSources.all)
                            v: kDatingSourceLabels[v] ?? v,
                        },
                        onChanged: (v) => setState(() {
                          _datingSource = v;
                          // LMP date is provenance for LMP dating only.
                          if (v != DatingSources.lmp) _lmp = null;
                          if (v == null || v == DatingSources.unknown) {
                            _edd = null;
                          }
                        }),
                      ),
                      const SizedBox(height: 12),
                      _DateRow(
                        label: current?.eddLabelText ?? 'Estimated due date',
                        value: _edd,
                        display: _formatDate(_edd),
                        onPick: () async {
                          final picked = await _pickDate(
                            _edd,
                            allowFuture: true,
                          );
                          if (picked != null) {
                            setState(() => _edd = picked);
                          }
                        },
                        onClear: _edd == null
                            ? null
                            : () => setState(() => _edd = null),
                      ),
                      _DateRow(
                        label: 'First day of last period',
                        value: _lmp,
                        display: _formatDate(_lmp),
                        enabled: _datingSource == DatingSources.lmp,
                        disabledHint: 'Used with last-period dating only.',
                        onPick: () async {
                          final picked = await _pickDate(
                            _lmp,
                            allowFuture: false,
                          );
                          if (picked != null) {
                            setState(() => _lmp = picked);
                          }
                        },
                        onClear: _lmp == null
                            ? null
                            : () => setState(() => _lmp = null),
                      ),
                      _DateRow(
                        label: 'Confirmation date (optional)',
                        value: _confirmation,
                        display: _formatDate(_confirmation),
                        onPick: () async {
                          final picked = await _pickDate(
                            _confirmation,
                            allowFuture: false,
                          );
                          if (picked != null) {
                            setState(() => _confirmation = picked);
                          }
                        },
                        onClear: _confirmation == null
                            ? null
                            : () => setState(() => _confirmation = null),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dating note (optional)',
                          hintText: 'Anything your clinician told you',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            active ? 'Save changes' : 'Turn on pregnancy mode',
                          ),
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _deactivate,
                      child: const Text('Pause pregnancy mode (keep history)'),
                    ),
                  ),
                ],
                if (current != null && (active || current.hasDating)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _erase,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      child: const Text('Erase pregnancy history'),
                    ),
                  ),
                ],
                if (current?.disclaimer != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    current!.disclaimer!,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Couldn\u2019t load pregnancy mode.'),
                const SizedBox(height: 8),
                Text('$err'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => refreshReproductiveData(ref),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(ColorScheme scheme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: child,
    );
  }
}

/// Current-context summary rendered from server-provided dating display
/// only. Gestational age and due countdown are displayed values — this
/// widget computes nothing medical (only plural wording of given numbers).
class _ContextSummaryCard extends StatelessWidget {
  final PregnancyContext context;
  final String Function(String?) formatDate;

  const _ContextSummaryCard({required this.context, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = this.context;
    final daysLeft = c.daysUntilDue;
    String? dueCountdown;
    if (c.estimatedDueDate != null && daysLeft != null) {
      if (daysLeft > 0) {
        dueCountdown =
            'About $daysLeft ${daysLeft == 1 ? 'day' : 'days'} to go';
      } else if (daysLeft == 0) {
        dueCountdown = 'Due today';
      } else {
        final ago = -daysLeft;
        dueCountdown =
            'Due date was $ago ${ago == 1 ? 'day' : 'days'} ago — mode stays on until you change it';
      }
    }
    return Container(
      width: double.infinity,
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
              Icon(
                Icons.pregnant_woman_rounded,
                size: 20,
                color: colorScheme.onSurface,
                semanticLabel: 'Pregnancy mode on',
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pregnancy mode is on',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
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
                  c.provenanceLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: _summarySemantics(c),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Source', c.datingSourceLabel),
                if (c.estimatedDueDate != null)
                  _row(c.eddLabelText, formatDate(c.estimatedDueDate)),
                if (c.hasGestationalAge)
                  _row(
                    'Gestational age',
                    '${c.gestationalAgeWeeks}w ${c.gestationalAgeDays}d'
                        '${c.asOfDate != null ? ' · as of ${formatDate(c.asOfDate)}' : ''}',
                  ),
                if (dueCountdown != null) _row('Countdown', dueCountdown),
                if (c.confirmationDate != null)
                  _row('Confirmed', formatDate(c.confirmationDate)),
                if (c.datingNote != null && c.datingNote!.trim().isNotEmpty)
                  _row('Note', c.datingNote!.trim()),
                if (c.estimatedDueDate == null)
                  Text(
                    'No due date recorded yet — add dating information below if you have it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _summarySemantics(PregnancyContext c) {
    final parts = <String>[
      'Pregnancy mode is on',
      'Source: ${c.datingSourceLabel}',
    ];
    if (c.estimatedDueDate != null) {
      parts.add('${c.eddLabelText}: ${c.estimatedDueDate}');
    }
    if (c.hasGestationalAge) {
      parts.add(
        'Gestational age ${c.gestationalAgeWeeks} weeks ${c.gestationalAgeDays} days',
      );
    }
    return parts.join('. ');
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _OffCard extends StatelessWidget {
  final bool hasHistory;

  const _OffCard({required this.hasHistory});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(
        hasHistory
            ? 'Pregnancy mode is paused. Your dating information is kept below — resume anytime by saving.'
            : 'Pregnancy mode is off. Turn it on below if it applies to you.',
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.secondary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isError;

  const _NoticeBanner({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isError ? colorScheme.error : colorScheme.secondary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        DropdownButton<String?>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          hint: const Text('Not set'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Not set'),
            ),
            for (final entry in items.entries)
              DropdownMenuItem<String?>(
                value: entry.key,
                child: Text(entry.value),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String? value;
  final String display;
  final bool enabled;
  final String? disabledHint;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DateRow({
    required this.label,
    required this.value,
    required this.display,
    required this.onPick,
    this.enabled = true,
    this.disabledHint,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled ? display : (disabledHint ?? display),
                  style: TextStyle(fontSize: 13, color: colorScheme.secondary),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            if (onClear != null)
              TextButton(onPressed: onClear, child: const Text('Clear')),
            OutlinedButton(onPressed: onPick, child: const Text('Choose')),
          ],
        ],
      ),
    );
  }
}

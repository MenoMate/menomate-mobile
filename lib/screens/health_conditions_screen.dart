import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_policy.dart';
import '../models/health_context.dart';
import '../providers/data_providers.dart';
import '../providers/health_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/offline_banner.dart';

/// Focused screen for user-reported health conditions: browse the curated
/// list, add with an optional note, edit notes, or remove. Presence here
/// is the user's own statement — never a detection or diagnosis.
class HealthConditionsScreen extends ConsumerWidget {
  const HealthConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final async = ref.watch(conditionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Health conditions',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Conditions you tell MenoMate about — never a diagnosis by MenoMate.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: async.when(
                  data: (state) {
                    final items = state.dataOrNull ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SyncStatusChip(state: state),
                        if (items.isEmpty)
                          Text(
                            'None added. Add anything you\u2019d like MenoMate to know about.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.secondary,
                              height: 1.4,
                            ),
                          )
                        else
                          for (final item in items) _ConditionRow(item: item),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showConditionDialog(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add condition'),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text(
                    'Couldn\u2019t load conditions.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConditionDialog(
    BuildContext context,
    WidgetRef ref, {
    HealthCondition? existing,
  }) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _ConditionDialog(existing: existing),
    );
    if (updated == true) refreshHealthData(ref);
  }
}

class _ConditionRow extends ConsumerWidget {
  final HealthCondition item;

  const _ConditionRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // Transparent Material so the ListTile ink paints above the section
    // card instead of hiding behind its DecoratedBox.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          item.displayLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: item.note == null
            ? null
            : Text(
                item.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colorScheme.secondary),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Remove',
          onPressed: () => _confirmDelete(context, ref),
        ),
        onTap: () async {
          final updated = await showDialog<bool>(
            context: context,
            builder: (context) => _ConditionDialog(existing: item),
          );
          if (updated == true) refreshHealthData(ref);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove condition?'),
        content: Text(
          'Remove “${item.displayLabel}” from your health context?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || item.localId == null) return;
    try {
      await ref
          .read(healthContextRepositoryProvider)
          .deleteCondition(
            userId,
            item.localId!,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshHealthData(ref);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\u2019t remove this entry.')),
        );
      }
    }
  }
}

/// Add/edit dialog for a condition. Add mode picks from the curated list
/// (`Other` reveals a required custom-label field); edit mode only edits
/// the note — changing the code itself is delete + re-add, which keeps the
/// backend other-label contract impossible to violate from this UI.
class _ConditionDialog extends ConsumerStatefulWidget {
  final HealthCondition? existing;

  const _ConditionDialog({this.existing});

  @override
  ConsumerState<_ConditionDialog> createState() => _ConditionDialogState();
}

class _ConditionDialogState extends ConsumerState<_ConditionDialog> {
  late String _code;
  final _labelController = TextEditingController();
  final _noteController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = widget.existing?.code ?? HealthConditionCodes.pcos;
    _labelController.text = widget.existing?.customLabel ?? '';
    _noteController.text = widget.existing?.note ?? '';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isAdd => widget.existing == null;

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    final label = _labelController.text.trim();
    final note = _noteController.text.trim();
    final error = validateConditionInput(
      _code,
      _code == HealthConditionCodes.other ? label : null,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repo = ref.read(healthContextRepositoryProvider);
      final offline = ref.read(isOfflineTrackingProvider);
      if (_isAdd) {
        await repo.addCondition(
          userId,
          code: _code,
          customLabel: _code == HealthConditionCodes.other ? label : null,
          note: note.isEmpty ? null : note,
          localOnly: offline,
        );
      } else {
        await repo.updateCondition(
          userId,
          widget.existing!.localId!,
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          localOnly: offline,
        );
      }
      // The screen refreshes the targeted health providers on pop;
      // cycle/history/prediction state is never touched by health writes.
      if (mounted) Navigator.of(context).pop(true);
    } on ValidationError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Couldn\u2019t save this entry. Please try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(_isAdd ? 'Add condition' : 'Edit note'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Conditions you tell MenoMate about — never a diagnosis by MenoMate.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.secondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              if (_isAdd) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    key: const ValueKey('condition_code_list'),
                    child: RadioGroup<String>(
                      groupValue: _code,
                      onChanged: (val) => setState(() {
                        if (val != null) {
                          _code = val;
                          _error = null;
                        }
                      }),
                      child: Column(
                        children: [
                          for (final code in HealthConditionCodes.curated)
                            RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                kConditionLabels[code]!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: code,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_code == HealthConditionCodes.other) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    maxLength: 128,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Your label (required)',
                      hintText: 'e.g. Fibromyalgia',
                      counterText: '',
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  widget.existing!.displayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _noteController,
                maxLength: 1000,
                maxLines: 2,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 12, color: colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_isAdd ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

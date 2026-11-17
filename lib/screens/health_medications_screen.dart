import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_policy.dart';
import '../models/health_context.dart';
import '../providers/data_providers.dart';
import '../providers/health_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/offline_banner.dart';

/// Focused screen for user-recorded medications and treatments: add with
/// an optional note, toggle active/inactive, edit, or remove. Names are
/// free text and duplicates stay allowed; nothing is inferred from them.
class HealthMedicationsScreen extends ConsumerWidget {
  const HealthMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final async = ref.watch(medicationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Medications & treatments',
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
                'Record what you take, for context only. MenoMate gives no medication advice.',
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
                            'None added. Record anything you take, if you want MenoMate to have the full picture.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.secondary,
                              height: 1.4,
                            ),
                          )
                        else
                          for (final item in items) _MedicationRow(item: item),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showMedicationDialog(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add medication'),
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
                    'Couldn\u2019t load medications.',
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

  Future<void> _showMedicationDialog(
    BuildContext context,
    WidgetRef ref, {
    Medication? existing,
  }) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _MedicationDialog(existing: existing),
    );
    if (updated == true) refreshHealthData(ref);
  }
}

class _MedicationRow extends ConsumerWidget {
  final Medication item;

  const _MedicationRow({required this.item});

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
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.note != null)
              Text(
                item.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colorScheme.secondary),
              ),
            Text(
              item.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.isActive,
              onChanged: (val) => _setActive(context, ref, val),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Remove',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        onTap: () async {
          final updated = await showDialog<bool>(
            context: context,
            builder: (context) => _MedicationDialog(existing: item),
          );
          if (updated == true) refreshHealthData(ref);
        },
      ),
    );
  }

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || item.localId == null) return;
    try {
      await ref
          .read(healthContextRepositoryProvider)
          .updateMedication(
            userId,
            item.localId!,
            isActive: value,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshHealthData(ref);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\u2019t update this entry.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove medication?'),
        content: Text('Remove “${item.name}” from your health context?'),
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
          .deleteMedication(
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

/// Add/edit dialog for a medication. Names are free text; duplicates are
/// allowed. Nothing here suggests, doses, or links a medication to any
/// condition.
class _MedicationDialog extends ConsumerStatefulWidget {
  final Medication? existing;

  const _MedicationDialog({this.existing});

  @override
  ConsumerState<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends ConsumerState<_MedicationDialog> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  late bool _isActive;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.existing?.name ?? '';
    _noteController.text = widget.existing?.note ?? '';
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final name = _nameController.text.trim();
    final note = _noteController.text.trim();
    final error = validateMedicationName(name);
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
        await repo.addMedication(
          userId,
          name: name,
          note: note.isEmpty ? null : note,
          isActive: _isActive,
          localOnly: offline,
        );
      } else {
        await repo.updateMedication(
          userId,
          widget.existing!.localId!,
          name: name,
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          isActive: _isActive,
          localOnly: offline,
        );
      }
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
      title: Text(_isAdd ? 'Add medication' : 'Edit medication'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Record what you take, for context only. MenoMate gives no medication advice.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.secondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                maxLength: 128,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name (required)',
                  hintText: 'e.g. Ibuprofen',
                  counterText: '',
                ),
              ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Currently taking',
                    style: TextStyle(fontSize: 14),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
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

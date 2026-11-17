import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/sync_policy.dart';
import '../models/health_context.dart';
import '../providers/data_providers.dart';
import '../providers/health_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/reproductive_providers.dart';
import '../widgets/offline_banner.dart';

/// Focused screen for reproductive health context: contraception method +
/// note and pregnancy/fertility context. Optional, non-judgmental, and
/// never presented as prediction — selections here don't change
/// predictions or determine anything about pregnancy.
///
/// The singleton saves whole (PUT semantics), so this screen carries the
/// untouched notes field along from the provider and writes it back
/// unchanged — saving here can never clear what the notes screen holds.
class HealthReproductiveScreen extends ConsumerStatefulWidget {
  const HealthReproductiveScreen({super.key});

  @override
  ConsumerState<HealthReproductiveScreen> createState() =>
      _HealthReproductiveScreenState();
}

class _HealthReproductiveScreenState
    extends ConsumerState<HealthReproductiveScreen> {
  final _contraceptionNoteController = TextEditingController();

  String? _contraception;
  String? _pregnancy;
  String? _preservedNotes;
  bool _formInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _contraceptionNoteController.dispose();
    super.dispose();
  }

  void _initForm(HealthContext? context) {
    if (context == null || _formInitialized) return;
    _contraception = context.contraceptionMethod;
    _contraceptionNoteController.text = context.contraceptionNote ?? '';
    _pregnancy = context.pregnancyContext;
    _preservedNotes = context.healthNotes;
    _formInitialized = true;
  }

  String? _clean(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in or continue offline to save.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(healthContextRepositoryProvider)
          .saveHealthContext(
            userId,
            HealthContext(
              userId: userId,
              contraceptionMethod: _contraception,
              contraceptionNote: _clean(_contraceptionNoteController),
              pregnancyContext: _pregnancy,
              healthNotes: _preservedNotes,
            ),
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshHealthData(ref);
      if (mounted) {
        final message = switch (result) {
          PendingSync() => 'Saved on this device. Will sync when online.',
          ConflictState(message: final m) =>
            'Saved on this device, needs review: $m',
          _ => 'Reproductive health saved.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save these details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.watch(healthContextProvider).whenData((state) {
      _initForm(state.dataOrNull);
    });
    final singletonState = ref.watch(healthContextProvider).value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Reproductive health',
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
                'Optional context only. These selections don\u2019t change '
                'predictions or determine anything about pregnancy.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Contraception', colorScheme),
              _card(
                colorScheme,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabeledDropdown<String?>(
                      label: 'Contraception method',
                      icon: Icons.shield_outlined,
                      value: _contraception,
                      hint: 'Not set',
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Not set'),
                        ),
                        for (final entry in kContraceptionLabels.entries)
                          DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (val) => setState(() => _contraception = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contraceptionNoteController,
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
                        hintText: 'Any specifics you want to remember',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('Pregnancy & fertility', colorScheme),
              _card(
                colorScheme,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabeledDropdown<String?>(
                      label: 'Context (optional)',
                      icon: Icons.child_care_outlined,
                      value: _pregnancy,
                      hint: 'Not set',
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Not set'),
                        ),
                        for (final entry in kPregnancyContextLabels.entries)
                          DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (val) => setState(() => _pregnancy = val),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Context only — this selection never changes predictions and never turns on pregnancy mode.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('Pregnancy mode', colorScheme),
              _ModeTile(
                icon: Icons.pregnant_woman_rounded,
                title: 'Pregnancy mode',
                summary: _pregnancyModeSummary(ref),
                onTap: () => context.push('/profile/health/pregnancy-mode'),
              ),
              const SizedBox(height: 12),
              _buildSectionHeader('Reproductive-aging context', colorScheme),
              _ModeTile(
                icon: Icons.spa_outlined,
                title: 'Aging context',
                summary: _agingSummary(ref),
                onTap: () => context.push('/profile/health/aging'),
              ),
              const SizedBox(height: 20),
              if (singletonState != null) SyncStatusChip(state: singletonState),
              SizedBox(
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
                      : const Text('Save reproductive health'),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _card(ColorScheme colorScheme, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }
}

/// Explicit-mode navigation tile: icon, title, live summary, chevron.
/// Pregnancy mode and aging context have their own screens — separate from
/// the legacy context dropdown above, which keeps its existing meaning.
class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          leading: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            summary,
            style: TextStyle(fontSize: 12, color: colorScheme.secondary),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.secondary),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// '…' while loading, honest text once settled.
String _pregnancyModeSummary(WidgetRef ref) {
  final state = ref.watch(pregnancyProvider).value;
  if (state == null) return '…';
  if (state is Unavailable) return 'Couldn\u2019t load';
  final ctx = state.dataOrNull;
  if (ctx?.isActive == true) return 'On — explicit mode';
  if (ctx != null && ctx.hasDating) return 'Paused — history kept';
  return 'Off';
}

/// '…' while loading, honest text once settled.
String _agingSummary(WidgetRef ref) {
  final state = ref.watch(agingProvider).value;
  if (state == null) return '…';
  if (state is Unavailable) return 'Couldn\u2019t load';
  final ctx = state.dataOrNull;
  if (ctx?.hasContext == true) return 'You recorded this';
  return 'Not set yet';
}

/// Labeled single-select matching the Settings dropdown language
/// (label + chevron row) without deprecated form-field plumbing.
class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.secondary),
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
        ),
        const SizedBox(height: 4),
        DropdownButton<T>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

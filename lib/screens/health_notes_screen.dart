import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_policy.dart';
import '../models/health_context.dart';
import '../providers/data_providers.dart';
import '../providers/health_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/offline_banner.dart';

/// Focused screen for the free-text health notes. The text is stored
/// verbatim and never parsed, classified, or summarized.
///
/// The singleton saves whole (PUT semantics), so this screen carries the
/// contraception and pregnancy selections along from the provider and
/// writes them back unchanged — saving here can never clear what the
/// reproductive screen holds.
class HealthNotesScreen extends ConsumerStatefulWidget {
  const HealthNotesScreen({super.key});

  @override
  ConsumerState<HealthNotesScreen> createState() => _HealthNotesScreenState();
}

class _HealthNotesScreenState extends ConsumerState<HealthNotesScreen> {
  final _healthNotesController = TextEditingController();

  String? _preservedContraception;
  String? _preservedContraceptionNote;
  String? _preservedPregnancy;
  bool _formInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _healthNotesController.dispose();
    super.dispose();
  }

  void _initForm(HealthContext? context) {
    if (context == null || _formInitialized) return;
    _healthNotesController.text = context.healthNotes ?? '';
    _preservedContraception = context.contraceptionMethod;
    _preservedContraceptionNote = context.contraceptionNote;
    _preservedPregnancy = context.pregnancyContext;
    _formInitialized = true;
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in or continue offline to save.')),
      );
      return;
    }
    final text = _healthNotesController.text.trim();
    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(healthContextRepositoryProvider)
          .saveHealthContext(
            userId,
            HealthContext(
              userId: userId,
              contraceptionMethod: _preservedContraception,
              contraceptionNote: _preservedContraceptionNote,
              pregnancyContext: _preservedPregnancy,
              healthNotes: text.isEmpty ? null : text,
            ),
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshHealthData(ref);
      if (mounted) {
        final message = switch (result) {
          PendingSync() => 'Saved on this device. Will sync when online.',
          ConflictState(message: final m) =>
            'Saved on this device, needs review: $m',
          _ => 'Notes saved.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save your notes: $e')),
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
          'Anything else',
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _healthNotesController,
                      maxLength: 2000,
                      maxLines: 6,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                      decoration: const InputDecoration(
                        labelText:
                            'Anything else you\u2019d like MenoMate to know?',
                        hintText: 'Optional free text for your own records',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is information you choose to provide. MenoMate '
                      'does not automatically interpret it as a diagnosis.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
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
                      : const Text('Save notes'),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/sync_policy.dart';
import '../models/reproductive.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/reproductive_providers.dart';
import '../widgets/offline_banner.dart';

/// Lightweight user-declared reproductive-aging context (Phase 4).
///
/// A free-text note the user owns, stored verbatim and never parsed into
/// medical facts. There is deliberately no staging vocabulary here: no
/// selectable "perimenopause"/"menopause" states, no detection from cycle
/// variability, age, or symptoms. This context never changes predictions
/// or fertility estimates, and it never deletes anything.
class AgingContextScreen extends ConsumerStatefulWidget {
  const AgingContextScreen({super.key});

  @override
  ConsumerState<AgingContextScreen> createState() => _AgingContextScreenState();
}

class _AgingContextScreenState extends ConsumerState<AgingContextScreen> {
  final _notesController = TextEditingController();
  bool _formInitialized = false;
  bool _isSaving = false;
  bool _isClearing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initForm(AgingContext? context) {
    if (_formInitialized) return;
    _notesController.text = context?.notes ?? '';
    _formInitialized = true;
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
          .saveAging(
            userId,
            _notesController.text,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
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

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this context?'),
        content: const Text(
          'Your saved note will be removed. Nothing else changes.',
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
    if (confirmed != true) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || !mounted) return;
    setState(() => _isClearing = true);
    try {
      await ref
          .read(reproductiveRepositoryProvider)
          .saveAging(
            userId,
            null,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshReproductiveData(ref);
      if (mounted) setState(() => _notesController.clear());
      _showMessage('Context removed.');
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Couldn\u2019t remove right now.');
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  String _savedMessage(DataState<AgingContext> result) {
    return switch (result) {
      PendingSync() => 'Saved on this device. Will sync when online.',
      ConflictState(message: final m) =>
        'Saved on this device, needs review: $m',
      _ => 'Context saved.',
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final agingAsync = ref.watch(agingProvider);

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
          'Reproductive-aging context',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: agingAsync.when(
        data: (state) {
          _initForm(state.dataOrNull);
          final hasContext = state.dataOrNull?.hasContext == true;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state is! NoData) SyncStatusChip(state: state),
                Text(
                  'Optional context in your own words — for example, changes you\u2019ve noticed and want to remember. '
                  'This is never treated as a diagnosis, and it never changes predictions or estimates. '
                  'If you notice persistent or concerning changes, consider talking to a clinician you trust.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                            Icons.edit_note_outlined,
                            size: 18,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Your note',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (hasContext)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'You recorded this',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Reproductive-aging context note',
                        child: TextField(
                          controller: _notesController,
                          maxLines: 5,
                          maxLength: kAgingNoteMaxLength,
                          decoration: const InputDecoration(
                            hintText: 'Anything you want MenoMate to remember…',
                            counterText: '',
                          ),
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
                        : const Text('Save context'),
                  ),
                ),
                if (hasContext) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isClearing ? null : _clear,
                      child: _isClearing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Remove this context'),
                    ),
                  ),
                ],
                if (state.dataOrNull?.disclaimer != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.dataOrNull!.disclaimer!,
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
                const Text('Couldn\u2019t load this context.'),
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
}

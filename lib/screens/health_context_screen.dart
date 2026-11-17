import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/sync_policy.dart';
import '../models/health_context.dart';
import '../providers/health_providers.dart';
import '../providers/offline_mode_provider.dart';

/// Health & Context hub: a scannable overview of the kinds of things the
/// user can tell MenoMate. Each category opens a focused screen; nothing
/// here diagnoses, infers, or alters predictions, and everything stays
/// optional — the hub itself has no form and no save button.
class HealthContextScreen extends ConsumerWidget {
  const HealthContextScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final offline = ref.watch(isOfflineTrackingProvider);
    final conditionsAsync = ref.watch(conditionsProvider);
    final medicationsAsync = ref.watch(medicationsProvider);
    final contextAsync = ref.watch(healthContextProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Health & Context',
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
                'Anything you share here is information you tell MenoMate '
                'about yourself. It is never treated as a diagnosis.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _HubCard(
                icon: Icons.favorite_outline,
                title: 'Health conditions',
                summary: _countSummary(
                  conditionsAsync,
                  one: 'condition',
                  many: 'conditions',
                ),
                onTap: () => context.push('/profile/health/conditions'),
              ),
              const SizedBox(height: 12),
              _HubCard(
                icon: Icons.medication_outlined,
                title: 'Medications & treatments',
                summary: _countSummary(
                  medicationsAsync,
                  one: 'medication',
                  many: 'medications',
                ),
                onTap: () => context.push('/profile/health/medications'),
              ),
              const SizedBox(height: 12),
              _HubCard(
                icon: Icons.health_and_safety_outlined,
                title: 'Reproductive health',
                summary: _reproductiveSummary(contextAsync),
                onTap: () => context.push('/profile/health/reproductive'),
              ),
              const SizedBox(height: 12),
              _HubCard(
                icon: Icons.edit_note_outlined,
                title: 'Anything else',
                summary: _notesSummary(contextAsync),
                onTap: () => context.push('/profile/health/notes'),
              ),
              if (offline) ...[
                const SizedBox(height: 16),
                Text(
                  'Optional health information stays on this device while '
                  'you\u2019re using MenoMate offline. If you sign in and '
                  'choose to sync/adopt your offline data, it can be '
                  'associated with your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// One hub category: icon, title, live summary, chevron. Same card
/// language as the Settings hub tile.
class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  const _HubCard({
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

/// '…' while loading, honest empty text once settled, counts after.
String _countSummary<T>(
  AsyncValue<DataState<List<T>>> async, {
  required String one,
  required String many,
}) {
  final state = async.value;
  if (state == null) return '…';
  if (state is Unavailable) return 'Couldn\u2019t load';
  final count = state.dataOrNull?.length ?? 0;
  if (count == 0) return 'None added yet';
  return '$count ${count == 1 ? one : many}';
}

/// Joined human labels of the set fields, or 'Not set yet'.
String _reproductiveSummary(AsyncValue<DataState<HealthContext?>> async) {
  final state = async.value;
  if (state == null) return '…';
  if (state is Unavailable) return 'Couldn\u2019t load';
  final ctx = state.dataOrNull;
  final parts = <String>[
    if (ctx?.contraceptionMethod != null)
      kContraceptionLabels[ctx!.contraceptionMethod] ??
          ctx.contraceptionMethod!,
    if (ctx?.pregnancyContext != null)
      kPregnancyContextLabels[ctx!.pregnancyContext] ?? ctx.pregnancyContext!,
  ];
  if (parts.isEmpty) return 'Not set yet';
  return parts.join(' · ');
}

/// First line-ish preview of the free-text notes, or 'Not set yet'.
String _notesSummary(AsyncValue<DataState<HealthContext?>> async) {
  final state = async.value;
  if (state == null) return '…';
  if (state is Unavailable) return 'Couldn\u2019t load';
  final notes = state.dataOrNull?.healthNotes?.trim() ?? '';
  if (notes.isEmpty) return 'Not set yet';
  final singleLine = notes.replaceAll(RegExp(r'\s+'), ' ');
  if (singleLine.length <= 60) return singleLine;
  return '${singleLine.substring(0, 60)}…';
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/sync_policy.dart';

/// Small sync-status indicator. Renders nothing for [Fresh]/[NoData];
/// [Unavailable] is rendered by each screen as a full state (never as
/// empty data), so it is also nothing here.
class SyncStatusChip extends StatelessWidget {
  final DataState state;

  const SyncStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (state) {
      Cached(fetchedAt: final at) =>
        'Offline · updated ${DateFormat('MMM d').format(at)}',
      PendingSync() => 'Not synced',
      ConflictState() => 'Needs review',
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();
    final bool warn = state is ConflictState;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (warn ? colorScheme.error : colorScheme.secondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warn ? Icons.warning_amber_rounded : Icons.cloud_off_outlined,
            size: 13,
            color: warn ? colorScheme.error : colorScheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: warn ? colorScheme.error : colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

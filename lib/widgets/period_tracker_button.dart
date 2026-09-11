import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import '../data/sync_policy.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';

class PeriodTrackerButton extends ConsumerStatefulWidget {
  final bool isOngoing;

  const PeriodTrackerButton({
    super.key,
    required this.isOngoing,
  });

  @override
  ConsumerState<PeriodTrackerButton> createState() => _PeriodTrackerButtonState();
}

class _PeriodTrackerButtonState extends ConsumerState<PeriodTrackerButton> {
  bool _isLoading = false;

  Future<void> _togglePeriod() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Signed out. Please sign in again.')),
          );
        }
        return;
      }

      // Local-first: the action is stored immediately and pushed when
      // reachable, so an offline tap is never lost.
      final repo = ref.read(cycleRepositoryProvider);
      final todayStr = toIsoDate(DateTime.now());
      final result = widget.isOngoing
          ? await repo.endOngoingPeriod(userId, todayStr)
          : await repo.startPeriod(userId, todayStr);

      refreshAllAppData(ref);

      if (mounted) {
        final base = widget.isOngoing
            ? 'Period marked as ended today.'
            : 'Period marked as started today.';
        final message = switch (result) {
          PendingSync() => '$base Will sync when you\'re online.',
          ConflictState(message: final m) => '$base Needs review: $m',
          Unavailable(message: final m) => m,
          _ => base,
        };
        final isError =
            result is ConflictState || result is Unavailable;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError
                ? Theme.of(context).colorScheme.error
                : null,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating period: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t update your period: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _togglePeriod,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(widget.isOngoing ? Icons.stop_circle_rounded : Icons.water_drop_rounded),
        label: Text(
          widget.isOngoing ? 'Log Period Ended Today' : 'Log Period Started Today',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.isOngoing ? Colors.redAccent.shade100 : Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

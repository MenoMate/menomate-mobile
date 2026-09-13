import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../data/sync_policy.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';

class PeriodTrackerButton extends ConsumerStatefulWidget {
  final bool isOngoing;

  /// Start of the currently ongoing period, if known. Enables the
  /// retrospective end-date correction (never inferred: the user picks it).
  final DateTime? ongoingStart;

  const PeriodTrackerButton({
    super.key,
    required this.isOngoing,
    this.ongoingStart,
  });

  @override
  ConsumerState<PeriodTrackerButton> createState() => _PeriodTrackerButtonState();
}

class _PeriodTrackerButtonState extends ConsumerState<PeriodTrackerButton> {
  bool _isLoading = false;

  Future<void> _togglePeriod() async {
    if (!widget.isOngoing) {
      await _submitStart();
      return;
    }
    await _submitEnd(toIsoDate(DateTime.now()), isToday: true);
  }

  Future<void> _submitStart() async {
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

      final repo = ref.read(cycleRepositoryProvider);
      final result =
          await repo.startPeriod(userId, toIsoDate(DateTime.now()));

      refreshAllAppData(ref);

      if (mounted) {
        const base = 'Period marked as started today.';
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

  /// Ends the ongoing period on a user-chosen date. The same local row is
  /// updated (never a duplicate); sync follows the existing pending flow.
  Future<void> _submitEnd(String isoDate, {required bool isToday}) async {
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
      final result = await repo.endOngoingPeriod(userId, isoDate);

      refreshAllAppData(ref);

      if (mounted) {
        final base = isToday
            ? 'Period marked as ended today.'
            : 'Period ended ${DateFormat('MMM d').format(DateTime.parse(isoDate))} recorded.';
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

  /// Retrospective correction: the user explicitly picks the actual past
  /// end date. Bounded to [periodStart, today]: never before the start,
  /// never in the future, never inferred.
  Future<void> _pickHistoricalEnd() async {
    final start = widget.ongoingStart;
    if (start == null) return;
    final startDay = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today.isBefore(startDay) ? startDay : today,
      firstDate: startDay,
      lastDate: today,
      helpText: 'When did your period end?',
    );
    if (picked == null || !mounted) return;
    final pickedDay = DateTime(picked.year, picked.month, picked.day);
    await _submitEnd(
      toIsoDate(pickedDay),
      isToday: pickedDay.isAtSameMomentAs(today),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              // Period action: menstrual rose carries the meaning. Ongoing
              // (stop) state rests on the soft container; starting a log
              // keeps full primary emphasis as the key Home action.
              backgroundColor: widget.isOngoing
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: widget.isOngoing
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (widget.isOngoing && widget.ongoingStart != null)
          TextButton(
            onPressed: _isLoading ? null : _pickHistoricalEnd,
            child: const Text('Forgot to log when it ended?'),
          ),
      ],
    );
  }
}

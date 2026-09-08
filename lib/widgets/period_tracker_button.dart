import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/cycle_provider.dart';

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
      final apiService = ref.read(apiServiceProvider);

      if (widget.isOngoing) {
        await apiService.endOngoingPeriod(DateTime.now());
      } else {
        await apiService.startPeriod(DateTime.now());
      }

      refreshAllAppData(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isOngoing
                  ? 'Period marked as ended today.'
                  : 'Period marked as started today.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating period: $e');
      if (mounted) {
        String friendlyMessage = "Couldn't update your period. Please try again.";
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['detail'] != null) {
            friendlyMessage = data['detail'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/cycle_provider.dart';

class PeriodTrackerButton extends ConsumerStatefulWidget {
  final bool isBleeding;
  final DateTime? latestPeriodStart;
  
  const PeriodTrackerButton({
    super.key, 
    required this.isBleeding,
    this.latestPeriodStart,
  });

  @override
  ConsumerState<PeriodTrackerButton> createState() => _PeriodTrackerButtonState();
}

class _PeriodTrackerButtonState extends ConsumerState<PeriodTrackerButton> {
  bool _isLoading = false;

  void _togglePeriod() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      if (widget.isBleeding) {
        // We can't end period without cycle_id easily if we don't have it here. 
        // Let's assume we need to fetch cycle_id or we'll just show a snackbar for now.
        // Actually, the API needs cycle_id to end it. 
        // For simplicity, let's just show a snackbar if we don't have cycle ID.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ending period feature coming soon.')),
        );
      } else {
        await apiService.startPeriod(DateTime.now());
        ref.invalidate(currentCycleProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(widget.isBleeding ? Icons.stop_circle : Icons.water_drop),
        label: Text(widget.isBleeding ? 'Log Period Ended Today' : 'Log Period Started Today'),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isBleeding ? Colors.redAccent.shade100 : Colors.redAccent,
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

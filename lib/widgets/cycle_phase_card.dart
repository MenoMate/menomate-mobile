import 'package:flutter/material.dart';
import '../models/cycle.dart';

class CyclePhaseCard extends StatelessWidget {
  final CurrentCycleResponse? cycleData;
  final bool isLoading;
  final String? error;

  const CyclePhaseCard({
    super.key,
    required this.cycleData,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF4A0024), const Color(0xFF31001B)]
              : [const Color(0xFFFFE4E1), const Color(0xFFFFC0CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Phase',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (cycleData?.isBleeding == true)
                const Icon(Icons.water_drop, color: Colors.redAccent, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null)
            Text('Error: $error', style: const TextStyle(color: Colors.red))
          else if (!isLoading && cycleData == null)
            const Text(
              'No cycle data available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )
          else ...[
            Text(
              cycleData?.phase.toUpperCase() ?? 'NO DATA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cycleData?.hasData == true 
                  ? 'Day ${cycleData!.currentCycleDay} of Cycle'
                  : (cycleData?.hasData == false ? 'Log a period to begin' : 'Waiting for data...'),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

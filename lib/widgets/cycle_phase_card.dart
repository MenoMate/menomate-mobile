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
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4E1), Color(0xFFFFC0CB)],
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
              const Text(
                'Current Phase',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
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
              cycleData?.phase ?? 'Calculating...',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cycleData?.currentCycleDay != null
                  ? 'Day ${cycleData!.currentCycleDay} of your cycle'
                  : (cycleData?.hasData == false ? 'Log a period to begin' : 'Waiting for data...'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

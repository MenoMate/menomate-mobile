import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/ble_service.dart';
import '../models/therapy.dart';

class PulsingTherapyFab extends StatefulWidget {
  const PulsingTherapyFab({super.key});

  @override
  State<PulsingTherapyFab> createState() => _PulsingTherapyFabState();
}

class _PulsingTherapyFabState extends State<PulsingTherapyFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTherapyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TherapyRecommendationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withAlpha((100 * _scaleAnimation.value).toInt()),
                  blurRadius: 20 * _scaleAnimation.value,
                  spreadRadius: 5 * _scaleAnimation.value,
                )
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _showTherapyBottomSheet(context),
              backgroundColor: Colors.pinkAccent,
              child: const Icon(Icons.healing, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}

class TherapyRecommendationSheet extends ConsumerStatefulWidget {
  const TherapyRecommendationSheet({super.key});

  @override
  ConsumerState<TherapyRecommendationSheet> createState() => _TherapyRecommendationSheetState();
}

class _TherapyRecommendationSheetState extends ConsumerState<TherapyRecommendationSheet> {
  bool _isLoading = true;
  TherapyRecommendationResponse? _recommendation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.getTherapyRecommendations();
      if (mounted) {
        setState(() {
          _recommendation = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startTherapy() async {
    if (_recommendation == null) return;

    final bleService = ref.read(bleServiceProvider);
    
    // Strict cap at 44C
    final safeTemp = min(_recommendation!.targetTemperatureC, 44.0);
    
    await bleService.sendTherapyCommand(
      targetTemperature: safeTemp,
      vibrationMode: _recommendation!.vibrationMode,
      vibrationIntensity: _recommendation!.vibrationIntensity,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Therapy started: ${safeTemp}C, ${_recommendation!.vibrationMode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Therapy Recommendation',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
            else if (_recommendation != null) ...[
              _buildSettingRow('Target Temperature', '${min(_recommendation!.targetTemperatureC, 44.0)}°C'),
              if (_recommendation!.targetTemperatureC > 44.0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Safety cap applied (Max 44°C)',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              _buildSettingRow('Vibration Mode', _recommendation!.vibrationMode.toUpperCase()),
              _buildSettingRow('Vibration Intensity', '${_recommendation!.vibrationIntensity}'),
              _buildSettingRow('Duration', '${_recommendation!.durationMinutes} min'),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _recommendation!.reasoning,
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _startTherapy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Start Therapy', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';

class DeviceTelemetryCard extends ConsumerStatefulWidget {
  const DeviceTelemetryCard({super.key});

  @override
  ConsumerState<DeviceTelemetryCard> createState() => _DeviceTelemetryCardState();
}

class _DeviceTelemetryCardState extends ConsumerState<DeviceTelemetryCard> {
  bool _isScanning = false;

  void _handleConnect() async {
    final bleService = ref.read(bleServiceProvider);
    
    if (bleService.isWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BLE is not supported on Web. Please use Android/iOS.')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });
    
    await bleService.startScan();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning for MenoMate Wearable...')),
    );
    
    // Reset scan state after 15s timeout
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.3),
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
              const Row(
                children: [
                  Icon(Icons.watch, color: Colors.white70, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'MenoMate Wearable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isScanning ? Icons.search : Icons.circle, 
                      color: _isScanning ? Colors.blueAccent : Colors.redAccent, 
                      size: _isScanning ? 12 : 8
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isScanning ? 'Scanning...' : 'Disconnected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _handleConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Colors.blueGrey.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isScanning
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                      'Connect Device',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

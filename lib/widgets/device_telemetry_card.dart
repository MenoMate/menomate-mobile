import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
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
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning for MenoMate Wearable...')),
      );
    }
    
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
    // The card stays deep navy in both modes (hardware identity), but on
    // the dark theme it needs a restrained outline plus a high-contrast
    // action button so the section reads as actionable, never neon.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MenoMateTheme.starrySurface, MenoMateTheme.starrySurface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
              Row(
                children: [
                  Icon(Icons.watch,
                      color: MenoMateTheme.starryText
                          .withValues(alpha: 0.7),
                      size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'MenoMate Wearable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MenoMateTheme.starryText,
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
                      // Active scan glows lavender; idle disconnected is a
                      // quiet neutral, never an error red.
                      color: _isScanning
                          ? MenoMateTheme.starryAccent
                          : MenoMateTheme.starryText
                              .withValues(alpha: 0.38),
                      size: _isScanning ? 12 : 8
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isScanning ? 'Scanning...' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        color: MenoMateTheme.starryText
                            .withValues(alpha: 0.7),
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
                // Pale neutral button in dark mode (navy text): maximum
                // separation on the navy card. Light mode keeps the white
                // button it already had.
                backgroundColor: isDark
                    ? MenoMateTheme.starryText
                    : Theme.of(context).colorScheme.surface,
                foregroundColor: isDark
                    ? MenoMateTheme.starryBg
                    : Colors.blueGrey.shade900,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isScanning
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                      'Connect Device',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/wearable_state.dart';
import '../services/ble_service.dart';

class DeviceTelemetryCard extends ConsumerStatefulWidget {
  const DeviceTelemetryCard({super.key});

  @override
  ConsumerState<DeviceTelemetryCard> createState() => _DeviceTelemetryCardState();
}

class _DeviceTelemetryCardState extends ConsumerState<DeviceTelemetryCard> {
  void _handleScanOrConnect() async {
    final bleService = ref.read(bleServiceProvider);

    if (bleService.isWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BLE is not supported on Web. Please use Android/iOS.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanning for MenoMate Wearable...'),
        duration: Duration(seconds: 2),
      ),
    );

    await bleService.startScan();
  }

  void _handleDisconnect() async {
    final bleService = ref.read(bleServiceProvider);
    await bleService.disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wearable disconnected. Actuators turned OFF.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handlePowerToggle(bool turnOn) async {
    final bleService = ref.read(bleServiceProvider);
    try {
      await bleService.setPower(turnOn);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set power: $e')),
        );
      }
    }
  }

  void _handleSetHeat(WearableHeatLevel level) async {
    final bleService = ref.read(bleServiceProvider);
    try {
      await bleService.setHeatLevel(level);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set heat level: $e')),
        );
      }
    }
  }

  void _handleSetMotor(WearableMotorMode mode) async {
    final bleService = ref.read(bleServiceProvider);
    try {
      await bleService.setMotorMode(mode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set motor mode: $e')),
        );
      }
    }
  }

  void _handleAllOff() async {
    final bleService = ref.read(bleServiceProvider);
    try {
      await bleService.allOff();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ALL OFF command sent — actuators stopped.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency ALL OFF failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final connectionStatus = ref.watch(bleConnectionStatusProvider).value ?? BleConnectionStatus.disconnected;
    final deviceStatus = ref.watch(wearableStatusProvider).value ?? const WearableDeviceStatus();
    final discoveredDevices = ref.watch(discoveredWearablesProvider).value ?? const [];
    final isBusy = ref.watch(bleIsBusyProvider).value ?? false;
    final errorMessage = ref.watch(bleErrorProvider).value;

    final isConnected = connectionStatus == BleConnectionStatus.connected;
    final isScanning = connectionStatus == BleConnectionStatus.scanning;
    final isConnecting = connectionStatus == BleConnectionStatus.connecting;

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
          color: colorScheme.outline,
          width: 1,
        ),
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
          // --- Card Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.watch,
                    color: MenoMateTheme.starryText.withValues(alpha: 0.7),
                    size: 24,
                  ),
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
              // Connection badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isScanning || isConnecting
                          ? Icons.search
                          : (isConnected ? Icons.check_circle : Icons.circle),
                      color: isConnected
                          ? const Color(0xFF4CC790) // ok green
                          : (isScanning || isConnecting
                              ? MenoMateTheme.starryAccent
                              : MenoMateTheme.starryText.withValues(alpha: 0.38)),
                      size: isScanning || isConnecting ? 12 : 8,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectionStatus.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: MenoMateTheme.starryText.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // In-flight operation progress bar
          if (isBusy) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(MenoMateTheme.starryAccent),
              ),
            ),
          ],

          // Error message banner if any
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // --- BODY CONTENT: Disconnected vs Connected ---
          if (!isConnected) ...[
            // Disconnected State: Scan & Found Devices
            if (discoveredDevices.isNotEmpty) ...[
              Text(
                'Available Devices',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MenoMateTheme.starryText.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              ...discoveredDevices.map((dev) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dev.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: MenoMateTheme.starryText,
                              ),
                            ),
                            Text(
                              'RSSI: ${dev.rssi} dBm',
                              style: TextStyle(
                                fontSize: 11,
                                color: MenoMateTheme.starryText.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: isConnecting
                              ? null
                              : () => ref.read(bleServiceProvider).connect(dev.device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MenoMateTheme.starryAccent,
                            foregroundColor: MenoMateTheme.starryBg,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
            ],

            // Main Scan / Connect Button (Preserves visual_system_test requirements)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isScanning || isConnecting) ? null : _handleScanOrConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? MenoMateTheme.starryText
                      : Theme.of(context).colorScheme.surface,
                  foregroundColor: isDark
                      ? MenoMateTheme.starryBg
                      : Colors.blueGrey.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: (isScanning || isConnecting)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Connect Device',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Connected State: Master Power, Actuator Controls, Emergency All-Off
            _buildConnectedControls(context, deviceStatus, isBusy),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectedControls(
    BuildContext context,
    WearableDeviceStatus status,
    bool isBusy,
  ) {
    final isPowerOn = status.isPowerOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Power & Emergency Actions Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Master Power Toggle
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : () => _handlePowerToggle(!isPowerOn),
                icon: Icon(
                  isPowerOn ? Icons.power_settings_new : Icons.power_off,
                  size: 18,
                ),
                label: Text(
                  isPowerOn ? 'MASTER: ON' : 'MASTER: OFF',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPowerOn ? const Color(0xFF4CC790) : Colors.white24,
                  foregroundColor: isPowerOn ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Emergency ALL OFF Button
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: isBusy ? null : _handleAllOff,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'ALL OFF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Disconnect Icon Button
            IconButton(
              onPressed: isBusy ? null : _handleDisconnect,
              icon: const Icon(Icons.link_off, color: MenoMateTheme.starrySecondary),
              tooltip: 'Disconnect Wearable',
            ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          isPowerOn
              ? 'Device is active · 10-minute session limit running'
              : 'Turn Master Power ON to activate heating and vibration',
          style: TextStyle(
            fontSize: 11,
            color: MenoMateTheme.starryText.withValues(alpha: 0.6),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 16),

        // 2. Heating Control (Relay Time-Proportioning)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Heating Level',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MenoMateTheme.starryText,
              ),
            ),
            // Live Relay State
            Text(
              status.isPowerOn && status.heatLevel != WearableHeatLevel.off
                  ? (status.isHeaterActive ? '● Relay Closed (Heating)' : '○ Relay Open (Resting)')
                  : '○ Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.isPowerOn && status.isHeaterActive
                    ? const Color(0xFFFF85A1)
                    : MenoMateTheme.starryText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Time-proportioned relay switching (20s period) · Not temperature regulation',
          style: TextStyle(
            fontSize: 10,
            color: MenoMateTheme.starryText.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),

        // Heat Level Buttons: OFF, LOW, MEDIUM, HIGH
        Row(
          children: [
            _buildHeatOption(WearableHeatLevel.off, status, isPowerOn, isBusy),
            const SizedBox(width: 6),
            _buildHeatOption(WearableHeatLevel.low, status, isPowerOn, isBusy),
            const SizedBox(width: 6),
            _buildHeatOption(WearableHeatLevel.medium, status, isPowerOn, isBusy),
            const SizedBox(width: 6),
            _buildHeatOption(WearableHeatLevel.high, status, isPowerOn, isBusy),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 16),

        // 3. Vibration Control (Relay Safe Patterns)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vibration Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MenoMateTheme.starryText,
              ),
            ),
            // Live Motor State
            Text(
              status.isPowerOn && status.motorMode != WearableMotorMode.off
                  ? (status.isMotorActive ? '● Motor Active' : '○ Motor Resting')
                  : '○ Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.isPowerOn && status.isMotorActive
                    ? MenoMateTheme.starryAccent
                    : MenoMateTheme.starryText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Relay-safe patterns (PULSE disabled for contact life)',
          style: TextStyle(
            fontSize: 10,
            color: MenoMateTheme.starryText.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),

        // Motor Mode Buttons: OFF, STEADY, WAVE
        Row(
          children: [
            _buildMotorOption(WearableMotorMode.off, status, isPowerOn, isBusy),
            const SizedBox(width: 6),
            _buildMotorOption(WearableMotorMode.steady, status, isPowerOn, isBusy),
            const SizedBox(width: 6),
            _buildMotorOption(WearableMotorMode.wave, status, isPowerOn, isBusy),
          ],
        ),
      ],
    );
  }

  Widget _buildHeatOption(
    WearableHeatLevel level,
    WearableDeviceStatus status,
    bool isPowerOn,
    bool isBusy,
  ) {
    final isSelected = status.heatLevel == level;
    final isEnabled = isPowerOn && !isBusy;

    return Expanded(
      child: InkWell(
        onTap: isEnabled ? () => _handleSetHeat(level) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF85A1).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF85A1)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                level.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isEnabled
                      ? (isSelected ? const Color(0xFFFF85A1) : MenoMateTheme.starryText)
                      : MenoMateTheme.starryText.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                level.dutyCycle,
                style: TextStyle(
                  fontSize: 9,
                  color: isEnabled
                      ? (isSelected
                          ? const Color(0xFFFF85A1).withValues(alpha: 0.9)
                          : MenoMateTheme.starrySecondary)
                      : MenoMateTheme.starrySecondary.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotorOption(
    WearableMotorMode mode,
    WearableDeviceStatus status,
    bool isPowerOn,
    bool isBusy,
  ) {
    final isSelected = status.motorMode == mode;
    final isEnabled = isPowerOn && !isBusy;

    return Expanded(
      child: InkWell(
        onTap: isEnabled ? () => _handleSetMotor(mode) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? MenoMateTheme.starryAccent.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? MenoMateTheme.starryAccent
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              mode.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isEnabled
                    ? (isSelected ? MenoMateTheme.starryAccent : MenoMateTheme.starryText)
                    : MenoMateTheme.starryText.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

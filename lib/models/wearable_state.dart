import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Connection state of the wearable device over BLE.
enum BleConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting;

  String get displayName {
    switch (this) {
      case BleConnectionStatus.disconnected:
        return 'Disconnected';
      case BleConnectionStatus.scanning:
        return 'Scanning...';
      case BleConnectionStatus.connecting:
        return 'Connecting...';
      case BleConnectionStatus.connected:
        return 'Connected';
      case BleConnectionStatus.disconnecting:
        return 'Disconnecting...';
    }
  }
}

/// Time-proportioned heat levels for the heating film relay.
///
/// NOTE: This is time-proportioning relay switching, NOT temperature regulation.
/// Do NOT display or describe these as temperatures in degrees Celsius.
enum WearableHeatLevel {
  off(0, 'OFF', '0%'),
  low(1, 'LOW', '20%'),
  medium(2, 'MEDIUM', '35%'),
  high(3, 'HIGH', '50%');

  final int level;
  final String label;
  final String dutyCycle;

  const WearableHeatLevel(this.level, this.label, this.dutyCycle);

  static WearableHeatLevel fromInt(int? val) {
    switch (val) {
      case 1:
        return WearableHeatLevel.low;
      case 2:
        return WearableHeatLevel.medium;
      case 3:
        return WearableHeatLevel.high;
      default:
        return WearableHeatLevel.off;
    }
  }
}

/// Relay-safe vibration motor modes.
///
/// Rapid pulse/tap mode (400ms) is explicitly omitted to protect
/// mechanical relay electrical ratings.
enum WearableMotorMode {
  off('off', 'OFF'),
  steady('steady', 'STEADY'),
  wave('wave', 'WAVE');

  final String wireValue;
  final String label;

  const WearableMotorMode(this.wireValue, this.label);

  static WearableMotorMode fromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'steady':
      case 'smooth':
        return WearableMotorMode.steady;
      case 'wave':
        return WearableMotorMode.wave;
      default:
        return WearableMotorMode.off;
    }
  }
}

/// Snapshot of the ESP32 wearable hardware status as reported by the device.
///
/// The ESP32 is the source of truth for the physical actuator state.
class WearableDeviceStatus {
  final bool isConnected;
  final bool isPowerOn;
  final WearableHeatLevel heatLevel;
  final WearableMotorMode motorMode;
  final bool isHeaterActive;
  final bool isMotorActive;
  final String? rawJson;

  const WearableDeviceStatus({
    this.isConnected = false,
    this.isPowerOn = false,
    this.heatLevel = WearableHeatLevel.off,
    this.motorMode = WearableMotorMode.off,
    this.isHeaterActive = false,
    this.isMotorActive = false,
    this.rawJson,
  });

  factory WearableDeviceStatus.fromJson(Map<String, dynamic> json) {
    return WearableDeviceStatus(
      isConnected: json['connected'] == true,
      isPowerOn: json['on'] == true,
      heatLevel: WearableHeatLevel.fromInt(json['heat'] as int?),
      motorMode: WearableMotorMode.fromWire(json['motor'] as String?),
      isHeaterActive: json['heater_active'] == true || json['hon'] == true,
      isMotorActive: json['motor_active'] == true,
      rawJson: json.toString(),
    );
  }

  WearableDeviceStatus copyWith({
    bool? isConnected,
    bool? isPowerOn,
    WearableHeatLevel? heatLevel,
    WearableMotorMode? motorMode,
    bool? isHeaterActive,
    bool? isMotorActive,
    String? rawJson,
  }) {
    return WearableDeviceStatus(
      isConnected: isConnected ?? this.isConnected,
      isPowerOn: isPowerOn ?? this.isPowerOn,
      heatLevel: heatLevel ?? this.heatLevel,
      motorMode: motorMode ?? this.motorMode,
      isHeaterActive: isHeaterActive ?? this.isHeaterActive,
      isMotorActive: isMotorActive ?? this.isMotorActive,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  @override
  String toString() {
    return 'WearableDeviceStatus(connected: $isConnected, on: $isPowerOn, heat: ${heatLevel.label}, motor: ${motorMode.label}, heatRelay: $isHeaterActive, motorRelay: $isMotorActive)';
  }
}

/// Discovered BLE peripheral during active scanning.
class DiscoveredWearable {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  const DiscoveredWearable({
    required this.device,
    required this.name,
    required this.rssi,
  });
}

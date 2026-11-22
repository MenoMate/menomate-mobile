import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/wearable_state.dart';

// ---------- Riverpod Providers ----------

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Live connection status stream provider.
final bleConnectionStatusProvider = StreamProvider<BleConnectionStatus>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionStatusStream;
});

/// Convenience provider returning true when a wearable device is connected.
/// Maintained for seamless integration with existing tabs (e.g. Care/Assistant).
final bleConnectedProvider = Provider<bool>((ref) {
  final service = ref.watch(bleServiceProvider);
  final status = ref.watch(bleConnectionStatusProvider).value;
  return (status ?? service.connectionStatus) == BleConnectionStatus.connected;
});

/// Authoritative actuator and hardware state reported by the ESP32.
final wearableStatusProvider = StreamProvider<WearableDeviceStatus>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.deviceStatusStream;
});

/// List of discovered wearables found during an active scan.
final discoveredWearablesProvider = StreamProvider<List<DiscoveredWearable>>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.discoveredDevicesStream;
});

/// True when a command transmission or GATT operation is currently in-flight.
final bleIsBusyProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.isBusyStream;
});

/// Holds the last error message, if any.
final bleErrorProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.errorStream;
});

// ---------- BleService Implementation ----------

class BleService {
  // --- Custom GATT UUIDs ---
  static const String serviceUuid = '00000001-e099-4d24-a5e9-1152a2818987';
  static const String commandCharUuid = '00000002-e099-4d24-a5e9-1152a2818987';
  static const String statusCharUuid = '00000003-e099-4d24-a5e9-1152a2818987';
  static const String defaultDeviceName = 'MenoMate-Wearable';

  bool get isWeb => kIsWeb;

  BleConnectionStatus _connectionStatus = BleConnectionStatus.disconnected;
  BleConnectionStatus get connectionStatus => _connectionStatus;
  final _connectionStatusController = StreamController<BleConnectionStatus>.broadcast();
  Stream<BleConnectionStatus> get connectionStatusStream async* {
    yield _connectionStatus;
    yield* _connectionStatusController.stream;
  }

  bool get isConnected => _connectionStatus == BleConnectionStatus.connected;

  WearableDeviceStatus _deviceStatus = const WearableDeviceStatus();
  WearableDeviceStatus get deviceStatus => _deviceStatus;
  final _deviceStatusController = StreamController<WearableDeviceStatus>.broadcast();
  Stream<WearableDeviceStatus> get deviceStatusStream async* {
    yield _deviceStatus;
    yield* _deviceStatusController.stream;
  }

  List<DiscoveredWearable> _discoveredDevices = [];
  List<DiscoveredWearable> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  final _discoveredDevicesController = StreamController<List<DiscoveredWearable>>.broadcast();
  Stream<List<DiscoveredWearable>> get discoveredDevicesStream async* {
    yield _discoveredDevices;
    yield* _discoveredDevicesController.stream;
  }

  bool _isBusy = false;
  bool get isBusy => _isBusy;
  final _isBusyController = StreamController<bool>.broadcast();
  Stream<bool> get isBusyStream async* {
    yield _isBusy;
    yield* _isBusyController.stream;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  final _errorController = StreamController<String?>.broadcast();
  Stream<String?> get errorStream async* {
    yield _errorMessage;
    yield* _errorController.stream;
  }

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BluetoothCharacteristic? _cmdCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _statusSubscription;

  BleService() {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    if (kIsWeb) return;

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && _connectionStatus == BleConnectionStatus.scanning) {
        _setConnectionStatus(BleConnectionStatus.disconnected);
      }
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final List<DiscoveredWearable> matched = [];
      for (final r in results) {
        final advName = r.advertisementData.advName;
        final devName = r.device.platformName;
        final name = advName.isNotEmpty ? advName : devName;

        // Match our known device name or advertised service UUID
        final bool matchesName = name.contains('MenoMate') || name.contains('HeatPad');
        final bool matchesService = r.advertisementData.serviceUuids.any(
          (u) => u.toString().toLowerCase() == serviceUuid.toLowerCase(),
        );

        if (matchesName || matchesService) {
          final displayName = name.isNotEmpty ? name : 'MenoMate Device';
          matched.add(DiscoveredWearable(
            device: r.device,
            name: displayName,
            rssi: r.rssi,
          ));
        }
      }

      _discoveredDevices = matched;
      _discoveredDevicesController.add(matched);
    });
  }

  void _setConnectionStatus(BleConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  void _setDeviceStatus(WearableDeviceStatus status) {
    _deviceStatus = status;
    _deviceStatusController.add(status);
  }

  void _setIsBusy(bool busy) {
    _isBusy = busy;
    _isBusyController.add(busy);
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _errorController.add(msg);
  }

  void _clearError() {
    _errorMessage = null;
    _errorController.add(null);
  }

  /// Request runtime Bluetooth permissions on Android.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final locationGranted = statuses[Permission.location]?.isGranted ?? false;

      return (scanGranted && connectGranted) || locationGranted;
    }
    return true;
  }

  /// Start scanning for MenoMate wearable devices.
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (kIsWeb) {
      _setError('BLE is not supported on Web');
      return;
    }

    try {
      final hasPerm = await requestPermissions();
      if (!hasPerm) {
        _setError('Bluetooth permissions not granted');
        return;
      }

      _clearError();
      _discoveredDevices = [];
      _discoveredDevicesController.add([]);
      _setConnectionStatus(BleConnectionStatus.scanning);

      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
        timeout: timeout,
      );
    } catch (e) {
      try {
        await FlutterBluePlus.startScan(timeout: timeout);
      } catch (innerError) {
        _setError('Error scanning for devices: $innerError');
        _setConnectionStatus(BleConnectionStatus.disconnected);
      }
    }
  }

  /// Stop active scan.
  void stopScan() {
    if (kIsWeb) return;
    FlutterBluePlus.stopScan();
    if (_connectionStatus == BleConnectionStatus.scanning) {
      _setConnectionStatus(BleConnectionStatus.disconnected);
    }
  }

  /// Connect to a selected BLE peripheral.
  Future<void> connect(BluetoothDevice device) async {
    if (kIsWeb) return;

    try {
      stopScan();
      _clearError();
      _setConnectionStatus(BleConnectionStatus.connecting);
      _setIsBusy(true);

      _connectedDevice = device;

      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnected();
        }
      });

      // In flutter_blue_plus 2.3.12, license parameter is required
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      final services = await device.discoverServices();
      BluetoothService? targetService;
      for (final s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          targetService = s;
          break;
        }
      }

      if (targetService == null) {
        throw Exception('MenoMate GATT service ($serviceUuid) not found on device.');
      }

      _cmdCharacteristic = null;
      _statusCharacteristic = null;

      for (final c in targetService.characteristics) {
        final uuidStr = c.uuid.toString().toLowerCase();
        if (uuidStr == commandCharUuid.toLowerCase()) {
          _cmdCharacteristic = c;
        } else if (uuidStr == statusCharUuid.toLowerCase()) {
          _statusCharacteristic = c;
        }
      }

      if (_cmdCharacteristic == null || _statusCharacteristic == null) {
        throw Exception('Required command or status characteristic missing.');
      }

      await _statusSubscription?.cancel();
      await _statusCharacteristic!.setNotifyValue(true);
      _statusSubscription = _statusCharacteristic!.onValueReceived.listen((bytes) {
        _handleStatusBytes(bytes);
      });

      // Read initial device status (source of truth on connect)
      final initialBytes = await _statusCharacteristic!.read();
      _handleStatusBytes(initialBytes);

      _setConnectionStatus(BleConnectionStatus.connected);
      _setIsBusy(false);
      debugPrint('[BLE] Successfully connected and subscribed to MenoMate wearable.');
    } catch (e) {
      debugPrint('[BLE] Connection error: $e');
      _setError('Failed to connect to device: $e');
      _handleDisconnected();
    }
  }

  /// Disconnect cleanly from the wearable.
  Future<void> disconnect() async {
    if (kIsWeb || _connectedDevice == null) {
      _handleDisconnected();
      return;
    }

    try {
      _setConnectionStatus(BleConnectionStatus.disconnecting);
      _setIsBusy(true);

      try {
        await allOff();
      } catch (_) {}

      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint('[BLE] Error during disconnect: $e');
    } finally {
      _handleDisconnected();
    }
  }

  void _handleDisconnected() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _cmdCharacteristic = null;
    _statusCharacteristic = null;
    _connectedDevice = null;

    _setConnectionStatus(BleConnectionStatus.disconnected);
    _setDeviceStatus(const WearableDeviceStatus(isConnected: false));
    _setIsBusy(false);
    debugPrint('[BLE] Device disconnected. Actuators reset to safe OFF state.');
  }

  void _handleStatusBytes(List<int> bytes) {
    if (bytes.isEmpty) return;
    try {
      final jsonString = utf8.decode(bytes);
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        _setDeviceStatus(WearableDeviceStatus.fromJson(decoded));
        debugPrint('[BLE STATUS RX] $_deviceStatus');
      }
    } catch (e) {
      debugPrint('[BLE] Failed to parse status payload: $e');
    }
  }

  // ---------- Actuator Commands ----------

  /// Master power command: {"cmd":"set_power","on":true|false}
  Future<void> setPower(bool on) async {
    await _sendCommand({'cmd': 'set_power', 'on': on});
  }

  /// Set heater time-proportioning level: {"cmd":"set_heat","level":0..3}
  ///
  /// Mechanical relay percentage: 0=OFF, 1=LOW (20%), 2=MED (35%), 3=HIGH (50%).
  Future<void> setHeatLevel(WearableHeatLevel level) async {
    await _sendCommand({'cmd': 'set_heat', 'level': level.level});
  }

  /// Set vibration motor mode: {"cmd":"set_motor","mode":"off"|"steady"|"wave"}
  Future<void> setMotorMode(WearableMotorMode mode) async {
    await _sendCommand({'cmd': 'set_motor', 'mode': mode.wireValue});
  }

  /// Emergency / Master ALL OFF command: {"cmd":"all_off"}
  Future<void> allOff() async {
    await _sendCommand({'cmd': 'all_off'});
  }

  /// Sends a raw JSON command map to the ESP32 Command Characteristic.
  Future<void> _sendCommand(Map<String, dynamic> commandMap) async {
    if (!isConnected || _cmdCharacteristic == null) {
      _setError('Wearable device is not connected.');
      return;
    }

    try {
      _setIsBusy(true);
      _clearError();

      final jsonStr = jsonEncode(commandMap);
      final bytes = utf8.encode(jsonStr);

      await _cmdCharacteristic!.write(bytes, withoutResponse: false);
      debugPrint('[BLE CMD TX] $jsonStr');
    } catch (e) {
      debugPrint('[BLE CMD ERROR] $e');
      _setError('Command failed: $e');
      rethrow;
    } finally {
      _setIsBusy(false);
    }
  }

  /// Compatibility wrapper for existing therapy recommendation callers (e.g. Care assistant).
  ///
  /// Maps bounded deterministic therapy recommendations to physical relay settings.
  Future<void> sendTherapyCommand({
    required double targetTemperature,
    required String vibrationMode,
    required int vibrationIntensity,
  }) async {
    if (!isConnected) {
      _setError('Wearable not connected.');
      return;
    }

    WearableHeatLevel heatLevel;
    if (targetTemperature <= 36.0) {
      heatLevel = WearableHeatLevel.off;
    } else if (targetTemperature <= 38.0) {
      heatLevel = WearableHeatLevel.low;
    } else if (targetTemperature <= 40.0) {
      heatLevel = WearableHeatLevel.medium;
    } else {
      heatLevel = WearableHeatLevel.high;
    }

    WearableMotorMode motorMode;
    if (vibrationMode.toLowerCase() == 'wave') {
      motorMode = WearableMotorMode.wave;
    } else if (vibrationIntensity > 0 || vibrationMode.toLowerCase() == 'steady') {
      motorMode = WearableMotorMode.steady;
    } else {
      motorMode = WearableMotorMode.off;
    }

    await setPower(true);
    if (heatLevel != WearableHeatLevel.off) {
      await setHeatLevel(heatLevel);
    }
    if (motorMode != WearableMotorMode.off) {
      await setMotorMode(motorMode);
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _connectionSubscription?.cancel();
    _statusSubscription?.cancel();

    _connectionStatusController.close();
    _deviceStatusController.close();
    _discoveredDevicesController.close();
    _isBusyController.close();
    _errorController.close();
  }
}

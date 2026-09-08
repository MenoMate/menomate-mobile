import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

final bleConnectedProvider = Provider<bool>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.isConnected;
});

class BleService {
  bool get isWeb => kIsWeb;
  bool get isConnected => !kIsWeb && FlutterBluePlus.connectedDevices.isNotEmpty;

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses[Permission.bluetoothScan]?.isGranted == true &&
             statuses[Permission.bluetoothConnect]?.isGranted == true &&
             statuses[Permission.location]?.isGranted == true;
    }
    return true; // iOS permissions are handled via Info.plist
  }

  Future<void> startScan() async {
    if (kIsWeb) {
      debugPrint('BLE not supported on Web');
      return;
    }

    try {
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        debugPrint('Bluetooth permissions not granted');
        return;
      }

      await FlutterBluePlus.startScan(
        withNames: ["MenoMate"], // Default name for the ESP32 Wearable
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Error starting BLE scan: $e');
    }
  }

  void stopScan() {
    if (kIsWeb) return;
    FlutterBluePlus.stopScan();
  }

  Future<void> sendTherapyCommand({
    required double targetTemperature,
    required String vibrationMode,
    required int vibrationIntensity,
  }) async {
    debugPrint('BLE COMMAND: Set Temp to $targetTemperature C');
    debugPrint('BLE COMMAND: Set Vibration Mode to $vibrationMode');
    debugPrint('BLE COMMAND: Set Vibration Intensity to $vibrationIntensity');
    
    if (kIsWeb) {
      debugPrint('Mocking BLE command on Web');
      return;
    }

    // In the future, this will serialize the command and write to the ESP32 characteristic
    debugPrint('Sending BLE command payload...');
  }
}

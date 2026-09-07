import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

class BleService {
  bool get isWeb => kIsWeb;

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
      print('BLE not supported on Web');
      return;
    }

    try {
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        print('Bluetooth permissions not granted');
        return;
      }

      await FlutterBluePlus.startScan(
        withNames: ["MenoMate"], // Default name for the ESP32 Wearable
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      print('Error starting BLE scan: $e');
    }
  }

  void stopScan() {
    if (kIsWeb) return;
    FlutterBluePlus.stopScan();
  }
}

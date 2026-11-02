// Call this from your login flow (e.g. right after a successful sign-in,
// before BleSosService.instance.start() runs) so Android actually grants
// BLUETOOTH_SCAN / BLUETOOTH_CONNECT instead of silently failing to find
// the pendant. Requires the permission_handler package (already added to
// pubspec.yaml).
//
// import 'package:permission_handler/permission_handler.dart';
//
// Future<void> requestBlePermissions() async {
//   await [
//     Permission.bluetoothScan,
//     Permission.bluetoothConnect,
//     Permission.locationWhenInUse, // still required by some OEMs for BLE scan
//   ].request();
// }

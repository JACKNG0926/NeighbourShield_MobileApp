import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'; // Gives us access to kIsWeb
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../features/home/data/incident_repository.dart';
import '../session/app_session.dart';

class BleSosService {
  BleSosService._();
  static final BleSosService instance = BleSosService._();

  // Must match the UUIDs in the ESP32 .ino file exactly (case-insensitive).
  static final Guid _serviceUuid =
      Guid('4f5a1b30-7e21-4a7a-9c7a-1b7e6a1d9001');
  static final Guid _characteristicUuid =
      Guid('4f5a1b31-7e21-4a7a-9c7a-1b7e6a1d9001');

  final IncidentRepository _incidentRepository = IncidentRepository();

  AppSession? _session;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  BluetoothDevice? _device;
  bool _starting = false;

  DateTime? _lastAction;
  static const _debounce = Duration(seconds: 3);

  Future<void> start(AppSession session) async {
    // 🚨 THE FIX: Stop the scan immediately if running on Web 🚨
    if (kIsWeb) {
      debugPrint('BLE: Running on Web, skipping Bluetooth scan.');
      return;
    }

    _session = session;
    if (_starting || _device != null) return;
    _starting = true;

    try {
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('BLE: this device has no Bluetooth support');
        return;
      }

      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 10), onTimeout: () => BluetoothAdapterState.unknown);

      _scanSub = FlutterBluePlus.scanResults.listen(_onScanResults);
      await FlutterBluePlus.startScan(
        withServices: [_serviceUuid],
        timeout: const Duration(seconds: 0), // we stop it manually on connect
      );
      debugPrint('BLE: scanning for NeighbourShield-Pendant...');
    } catch (e) {
      debugPrint('BLE: failed to start scanning: $e');
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return; // No need to stop if we never started
    
    await _notifySub?.cancel();
    await _scanSub?.cancel();
    try {
      await FlutterBluePlus.stopScan();
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _notifySub = null;
    _scanSub = null;
  }

  void _onScanResults(List<ScanResult> results) async {
    if (_device != null) return; 
    for (final r in results) {
      if (r.advertisementData.serviceUuids.contains(_serviceUuid) ||
          r.device.platformName == 'NeighbourShield-Pendant') {
        await FlutterBluePlus.stopScan();
        await _connect(r.device);
        return;
      }
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    _device = device;
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint('BLE: pendant disconnected, resuming scan');
        _device = null;
        _notifySub?.cancel();
        _notifySub = null;
        final session = _session;
        if (session != null && session.isAuthenticated) {
          Future.delayed(const Duration(seconds: 2), () => start(session));
        }
      }
    });

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == _serviceUuid);
      final characteristic =
          service.characteristics.firstWhere((c) => c.uuid == _characteristicUuid);

      await characteristic.setNotifyValue(true);
      _notifySub = characteristic.onValueReceived.listen(_onPayload);
      debugPrint('BLE: connected to pendant, listening for SOS/ping');
    } catch (e) {
      debugPrint('BLE: connect/discover failed: $e');
      _device = null;
    }
  }

  void _onPayload(List<int> bytes) {
    late Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('BLE: bad payload, ignoring: $e');
      return;
    }

    final now = DateTime.now();
    if (_lastAction != null && now.difference(_lastAction!) < _debounce) return;
    _lastAction = now;

    final action = json['action'] as String?;
    final hasFix = json['fix'] == true;
    final lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['lng'] as num?)?.toDouble() ?? 0.0;

    if (!hasFix) {
      debugPrint('BLE: pendant has no GPS fix yet, ignoring $action');
      return;
    }

    final session = _session;
    final user = session?.currentUser;

    if (action == 'SOS') {
      debugPrint('BLE: SOS received from pendant ($lat, $lng)');
      _incidentRepository
          .sendSos(lat, lng, phone: user?.phoneNumber, notes: user?.unitAddress)
          .catchError((e) => debugPrint('BLE: failed to send SOS: $e'));
    } else if (action == 'PING') {
      debugPrint('BLE: GPS ping received from pendant ($lat, $lng)');
    }
  }
}
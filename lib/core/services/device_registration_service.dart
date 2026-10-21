import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/api_config.dart';

/// Handles device token registration with the Django REST API (`/api/devices/`).
/// Ensures backend can target this device with high-priority FCM emergency broadcasts.
class DeviceRegistrationService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Registers or updates the device FCM token on the backend.
  Future<bool> registerDevice({required String fcmToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) {
      // Cannot register device without an authenticated user session
      return false;
    }

    // Avoid redundant calls if already registered with the same token
    final lastRegistered = prefs.getString('last_registered_fcm_token');
    if (lastRegistered == fcmToken) {
      return true;
    }

    final platform = _resolvePlatform();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'fcm_token': fcmToken.trim(),
          'platform': platform,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"detail": "Timeout"}', 408),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString('last_registered_fcm_token', fcmToken);
        return true;
      }
    } catch (_) {
      // Fail safely without disrupting the UI
      return false;
    }

    return false;
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}

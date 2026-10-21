import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/api_config.dart';
import 'emergency_broadcast_service.dart';

/// Periodic broadcast synchronization service for local development.
///
/// In local dev (without cloud FCM credentials), this service polls Django's
/// `/api/posts/latest_broadcast/` endpoint while the user is authenticated,
/// immediately forwarding new emergency broadcasts to [EmergencyBroadcastService].
class LocalBroadcastSyncService {
  LocalBroadcastSyncService._();
  static final LocalBroadcastSyncService instance = LocalBroadcastSyncService._();

  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _lastHandledBroadcastId;

  static const String _prefLastHandledKey = 'last_handled_broadcast_id';

  /// Starts periodic polling for active emergency broadcasts.
  void start({Duration interval = const Duration(seconds: 3)}) {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;

    // Check immediately on startup/sign-in
    checkForActiveBroadcast();

    _pollingTimer = Timer.periodic(interval, (_) {
      checkForActiveBroadcast();
    });
  }

  /// Stops polling on sign out.
  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  /// Polls the Django backend for the most recent open broadcast.
  Future<void> checkForActiveBroadcast({http.Client? client}) async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;

      _lastHandledBroadcastId ??= prefs.getString(_prefLastHandledKey);

      final httpClient = client ?? http.Client();
      final uri = Uri.parse('${ApiConfig.baseUrl}/posts/latest_broadcast/');

      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['broadcast'] != null) {
          final broadcast = decoded['broadcast'] as Map<String, dynamic>;
          final broadcastId =
              broadcast['id']?.toString() ?? broadcast['broadcast_id']?.toString();

          if (broadcastId != null &&
              broadcastId.isNotEmpty &&
              broadcastId != _lastHandledBroadcastId) {
            _lastHandledBroadcastId = broadcastId;
            await prefs.setString(_prefLastHandledKey, broadcastId);

            EmergencyBroadcastService.handleBroadcastPayload({
              'type': 'emergency_broadcast',
              'broadcast_id': broadcastId,
              'severity': broadcast['severity'] ?? 'info',
              'category': broadcast['category'] ?? 'other',
              'title': broadcast['title'] ?? 'Emergency Broadcast',
              'description': broadcast['description'] ?? '',
              'created_at': broadcast['created_at'],
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocalBroadcastSyncService poll exception: $e');
      }
    } finally {
      _isPolling = false;
    }
  }

  /// Clears the last handled broadcast ID (useful for testing or re-triggering).
  Future<void> resetHandledState() async {
    _lastHandledBroadcastId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefLastHandledKey);
  }
}

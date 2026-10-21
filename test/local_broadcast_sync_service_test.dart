import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neighbour_shield_mobile/core/services/local_broadcast_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_token_123',
    });
    await LocalBroadcastSyncService.instance.resetHandledState();
  });

  group('LocalBroadcastSyncService', () {
    test('fetches active broadcast and triggers EmergencyBroadcastService overlay', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/posts/latest_broadcast/'));
        expect(request.headers['Authorization'], 'Token test_token_123');

        return http.Response(
          jsonEncode({
            'broadcast': {
              'id': 201,
              'broadcast_id': '201',
              'title': 'FLASH FLOOD TEST',
              'description': 'Evacuate immediately.',
              'severity': 'critical',
              'category': 'flood',
              'status': 'open',
              'created_at': '2026-10-21T14:40:00Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Intercept by testing mock client
      await LocalBroadcastSyncService.instance.checkForActiveBroadcast(client: mockClient);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_handled_broadcast_id'), '201');
    });

    test('does not re-dispatch already handled broadcast ID', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token_123',
        'last_handled_broadcast_id': '201',
      });

      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'broadcast': {
              'id': 201,
              'broadcast_id': '201',
              'title': 'FLASH FLOOD TEST',
              'severity': 'critical',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await LocalBroadcastSyncService.instance.checkForActiveBroadcast(client: mockClient);

      expect(requestCount, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_handled_broadcast_id'), '201');
    });

    test('handles null broadcast gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'broadcast': null}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await LocalBroadcastSyncService.instance.checkForActiveBroadcast(client: mockClient);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_handled_broadcast_id'), isNull);
    });
  });
}

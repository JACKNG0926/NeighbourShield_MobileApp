import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/volunteer_incident.dart';

/// API client for the verified volunteer response queue.
/// The Django endpoint filters incidents to the volunteer's current radius.
class VolunteerIncidentRepository {
  // Keep this aligned with AuthRepository's host address.
  final String baseUrl = 'http://192.168.0.5:8000/api';

  Future<void> updateMyLocation({
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/me/location/'),
      headers: _headers(token),
      body: jsonEncode({
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to update your location (HTTP ${response.statusCode}).',
      );
    }
  }

  Future<List<VolunteerIncident>> fetchNearbyIncidents() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/incidents/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Token $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to load nearby SOS alerts (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    // DRF DefaultRouter returns a JSON list for this ViewSet.
    if (decoded is! List) {
      throw const FormatException(
        'Django returned an unexpected incident list.',
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => VolunteerIncident.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> acknowledgeIncident({
    required int incidentId,
    int? etaMinutes,
    String note = '',
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/incidents/$incidentId/acknowledge/'),
      headers: _headers(token),
      body: jsonEncode({'eta_minutes': ?etaMinutes, 'note': note}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to acknowledge SOS (HTTP ${response.statusCode}).',
      );
    }
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Token $token',
  };

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please sign in again.');
    }
    return token;
  }

  String? _readError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return '${entry.key}: ${value.first}';
        }
        if (value is String && value.isNotEmpty) return '${entry.key}: $value';
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

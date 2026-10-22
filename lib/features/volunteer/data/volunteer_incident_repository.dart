import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../models/volunteer_incident.dart';

/// API client for the verified volunteer response queue.
/// The Django endpoint filters incidents to the volunteer's current radius.
class VolunteerIncidentRepository {
  final String baseUrl = ApiConfig.baseUrl;

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
      body: jsonEncode({
        if (etaMinutes != null) 'eta_minutes': etaMinutes,
        'note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to acknowledge SOS (HTTP ${response.statusCode}).',
      );
    }
  }

  /// The volunteer's own SOS. Same endpoint the resident app uses, with the
  /// phone number and unit address pulled from the volunteer's profile
  /// (registered details, or whatever they last saved on their profile).
  Future<void> sendSos({
    required double latitude,
    required double longitude,
    String incidentType = 'other',
    String message = '',
  }) async {
    final token = await _getToken();
    final contact = await _myContact(token);

    final response = await http.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: _headers(token),
      body: jsonEncode({
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
        'incident_type': incidentType,
        'message': message,
        if (contact.unit.isNotEmpty) 'location_notes': contact.unit,
        if (contact.phone.isNotEmpty) 'contact_phone': contact.phone,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        _readError(response.body) ??
            'Unable to send SOS (HTTP ${response.statusCode}).',
      );
    }
  }

  /// Responder asks security for backup. Django creates a new incident of
  /// type 'backup' at the responder's current location.
  Future<void> requestBackup({
    required int originalIncidentId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();
    final contact = await _myContact(token);

    final notes = contact.unit.isEmpty
        ? 'Volunteer backup request (SOS #$originalIncidentId)'
        : 'Volunteer backup request (SOS #$originalIncidentId) - ${contact.unit}';

    final response = await http.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: _headers(token),
      body: jsonEncode({
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
        'incident_type': 'backup',
        'message': 'Backup requested for SOS #$originalIncidentId',
        'location_notes': notes,
        if (contact.phone.isNotEmpty) 'contact_phone': contact.phone,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        _readError(response.body) ??
            'Unable to request backup (HTTP ${response.statusCode}).',
      );
    }
  }

  /// Security / admin closes an incident with an outcome note.
  Future<void> resolveIncident({
    required int incidentId,
    String note = '',
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/incidents/$incidentId/resolve/'),
      headers: _headers(token),
      body: jsonEncode({'note': note}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to resolve SOS (HTTP ${response.statusCode}).',
      );
    }
  }

  /// Reads phone_number and unit_address from GET /me/. Never throws: an SOS
  /// must still go out even if the profile call fails.
  Future<({String phone, String unit})> _myContact(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return (
            phone: (decoded['phone_number'] ?? '').toString().trim(),
            unit: (decoded['unit_address'] ?? '').toString().trim(),
          );
        }
      }
    } catch (_) {
      // Fall through to empty details.
    }
    return (phone: '', unit: '');
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
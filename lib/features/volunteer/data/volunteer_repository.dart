import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API access for volunteer opt-in and profile status.
///
/// PATCH /api/me/ records the user's opt-in only. Django controls the actual
/// role and verification fields; the client must never grant those itself.
class VolunteerRepository {
  // Keep aligned with AuthRepository and IncidentRepository.
  final String baseUrl = 'http://192.168.0.5:8000/api';

  Future<Map<String, dynamic>> submitVolunteerOptIn() async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({'is_volunteer_opted_in': true}),
    );

    final decoded = _decodeProfile(response.body);
    if (response.statusCode == 200) {
      if (decoded['is_volunteer_opted_in'] == true) {
        return decoded;
      }
      throw Exception(
        'Django responded, but did not confirm your volunteer application.',
      );
    }

    throw Exception(
      _readError(response.body) ??
          'Unable to submit volunteer application '
              '(HTTP ${response.statusCode}).',
    );
  }

  /// Reads the current user's server-side role and application fields.
  /// Call this when the resident taps "Check Application Status".
  Future<Map<String, dynamic>> fetchCurrentProfile() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/me/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return _decodeProfile(response.body);
    }

    throw Exception(
      _readError(response.body) ??
          'Unable to refresh your profile (HTTP ${response.statusCode}).',
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please sign in again.');
    }

    return token;
  }

  Map<String, dynamic> _decodeProfile(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // Fall through to a descriptive API response error.
    }
    throw const FormatException(
      'Django returned an unexpected profile response.',
    );
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
        if (value is String && value.isNotEmpty) {
          return '${entry.key}: $value';
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../app/api_config.dart';

/// Talks to Django's /me/ and /auth/change-password/ endpoints.
class ProfileRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String unitAddress,
  }) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/me/'),
      headers: _headers(token),
      body: jsonEncode({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
        'phone_number': phone.trim(),
        'unit_address': unitAddress.trim(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to save your profile (HTTP ${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Django returned an unexpected profile.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// Django rotates the auth token after a password change; save the new one.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password/'),
      headers: _headers(token),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readError(response.body) ??
            'Unable to change password (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    final newToken = decoded is Map ? decoded['token'] : null;
    if (newToken is String && newToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', newToken);
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../models/user_session.dart';

class AuthRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<UserSession> signIn({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // Django TokenLoginView authenticates by username, not email.
        'username': username.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return _saveTokenAndReadUser(response.body);
    }

    if (response.statusCode == 400) {
      throw Exception(
        _readError(response.body) ?? 'Invalid username or password.',
      );
    }

    throw Exception(
      'Server error (${response.statusCode}). Please try again later.',
    );
  }

  Future<UserSession> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'email': email.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone_number': phone.trim(),
        'unit_address': address.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return _saveTokenAndReadUser(response.body);
    }

    if (response.statusCode == 400) {
      throw Exception(
        _readError(response.body) ?? 'Please check your registration details.',
      );
    }

    throw Exception(
      'Server error (${response.statusCode}). Please try again later.',
    );
  }

  Future<UserSession> _saveTokenAndReadUser(String responseBody) async {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final token = data['token'];
    final rawUser = data['user'];

    if (token is! String || rawUser is! Map) {
      throw const FormatException(
        'Django returned an unexpected authentication response.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    return UserSession.fromBackend(Map<String, dynamic>.from(rawUser));
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

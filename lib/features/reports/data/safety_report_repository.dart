import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../models/safety_report.dart';

class SafetyReportRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token;
  }

  Future<List<SafetyReport>> fetchReports() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/posts/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while loading reports.'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((item) => SafetyReport.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    throw Exception('Failed to load safety reports (HTTP ${response.statusCode})');
  }

  Future<SafetyReport> createReport({
    required String title,
    required String description,
    required String category,
    required String severity,
    double? latitude,
    double? longitude,
  }) async {
    final token = await _getToken();
    final Map<String, dynamic> payload = {
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'severity': severity,
      'post_type': 'hazard',
    };

    if (latitude != null && longitude != null) {
      payload['latitude'] = double.parse(latitude.toStringAsFixed(6));
      payload['longitude'] = double.parse(longitude.toStringAsFixed(6));
    }

    final response = await http.post(
      Uri.parse('$baseUrl/posts/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(payload),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while submitting report.'),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return SafetyReport.fromJson(decoded as Map<String, dynamic>);
    }

    final decoded = jsonDecode(response.body);
    String errorMessage = 'Failed to submit report (HTTP ${response.statusCode})';
    if (decoded is Map) {
      if (decoded.containsKey('detail')) {
        errorMessage = decoded['detail'].toString();
      } else if (decoded.isNotEmpty) {
        final firstKey = decoded.keys.first;
        errorMessage = '$firstKey: ${decoded[firstKey]}';
      }
    }
    throw Exception(errorMessage);
  }
}

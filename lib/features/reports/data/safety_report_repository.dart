import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../../../core/services/multipart_helper.dart';
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

  String _parseError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('detail')) return decoded['detail'].toString();
        if (decoded.isNotEmpty) {
          final firstKey = decoded.keys.first;
          return '$firstKey: ${decoded[firstKey]}';
        }
      }
    } catch (_) {}
    return 'Failed to submit report (HTTP ${response.statusCode})';
  }

  Future<SafetyReport> createReport({
    required String title,
    required String description,
    required String category,
    required String severity,
    double? latitude,
    double? longitude,
    XFile? image, // NEW: optional photo from ImagePickerField
  }) async {
    final token = await _getToken();

    final Map<String, String> fields = {
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'severity': severity,
      'post_type': 'hazard',
      if (latitude != null) 'latitude': latitude.toStringAsFixed(6),
      if (longitude != null) 'longitude': longitude.toStringAsFixed(6),
    };

    late http.Response response;
    if (image != null) {
      // multipart/form-data - required by Django's MultiPartParser when a file is attached.
      response = await MultipartHelper.post(
        url: Uri.parse('$baseUrl/posts/'),
        token: token,
        fields: fields,
        image: image,
      ).timeout(
        const Duration(seconds: 20), // uploads need more time than plain JSON
        onTimeout: () => throw Exception('Connection timed out while uploading photo.'),
      );
    } else {
      // No photo: keep the simple JSON path, unchanged from before.
      response = await http.post(
        Uri.parse('$baseUrl/posts/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          ...fields,
          if (latitude != null) 'latitude': double.parse(latitude.toStringAsFixed(6)),
          if (longitude != null) 'longitude': double.parse(longitude.toStringAsFixed(6)),
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timed out while submitting report.'),
      );
    }

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return SafetyReport.fromJson(decoded as Map<String, dynamic>);
    }
    throw Exception(_parseError(response));
  }
}

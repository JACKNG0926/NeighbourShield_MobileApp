import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IncidentRepository {
  final String baseUrl = 'http://192.168.0.5:8000/api';

  Future<void> sendSos(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        // Round to 6 decimal places, then convert back to a number
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
      }),
    );

    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      String backendMessage = response.body;

      if (errorData is Map) {
        if (errorData.containsKey('detail')) {
          backendMessage = errorData['detail'];
        } else {
          // Extract the first specific field error from Django
          final firstKey = errorData.keys.first;
          backendMessage = '$firstKey: ${errorData[firstKey][0]}';
        }
      }

      throw Exception('Server rejected SOS: $backendMessage');
    }
  }
}

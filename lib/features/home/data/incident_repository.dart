import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/api_config.dart';

class IncidentRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<void> sendSos(double latitude, double longitude, {String? phone, String? notes, String? incidentType}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Authentication token not found. Please log in again.');

    final response = await http.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
        'contact_phone': phone ?? '',
        'location_notes': notes ?? '',
        'incident_type': incidentType ?? 'other', // <-- Passes the Fire/Medical/Crime type
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      String backendMessage = 'Server error (${response.statusCode})';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('detail')) {
          backendMessage = errorData['detail'];
        }
      } catch (e) {
        backendMessage = 'Server rejected SOS. Check Django terminal.';
      }
      throw Exception(backendMessage);
    }
  }
}
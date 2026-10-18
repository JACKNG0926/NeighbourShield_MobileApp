import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  // Use your computer's LAN IP where Django is running
  final String baseUrl = 'http://192.168.0.5:8000/api';

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      // Django's TokenLoginView expects 'username', so we map the email input to it
      body: jsonEncode({
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      // Save the token locally for future API requests
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Return the username provided by the Django MobileProfileSerializer
      return data['user']['username'] ?? email;
    } else if (response.statusCode == 400) {
      throw Exception('Invalid username or password.');
    } else {
      throw Exception('Server error. Please try again later.');
    }
  }

  // Helper to retrieve the token later for the SOS button
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
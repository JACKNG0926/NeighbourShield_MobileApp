import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../models/community_post.dart';

class CommunityPostRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token;
  }

  Future<List<CommunityPost>> fetchPosts() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/community-posts/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while fetching community posts.'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    throw Exception('Failed to load community posts (HTTP ${response.statusCode})');
  }

  Future<CommunityPost> createCommunityPost({
    required String title,
    required String content,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/community-posts/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'title': title.trim(),
        'content': content.trim(),
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while publishing post.'),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return CommunityPost.fromJson(decoded as Map<String, dynamic>);
    }

    final decoded = jsonDecode(response.body);
    String errorMessage = 'Failed to submit post (HTTP ${response.statusCode})';
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

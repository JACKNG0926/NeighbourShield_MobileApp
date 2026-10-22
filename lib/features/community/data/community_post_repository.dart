import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../models/community_post.dart';
import '../models/community_post_comment.dart';

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

  String _parseErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('detail')) {
          return decoded['detail'].toString();
        } else if (decoded.isNotEmpty) {
          final firstKey = decoded.keys.first;
          final val = decoded[firstKey];
          if (val is List && val.isNotEmpty) {
            return '$firstKey: ${val.first}';
          }
          return '$firstKey: $val';
        }
      }
    } catch (_) {}
    return '$fallback (HTTP ${response.statusCode})';
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

    throw Exception(_parseErrorMessage(response, 'Failed to submit post'));
  }

  Future<({bool isLiked, int likesCount})> toggleLike(int postId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/community-posts/$postId/like/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while updating like.'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final isLiked = decoded['is_liked'] == true;
      final likesCount = decoded['likes_count'] as int? ?? 0;
      return (isLiked: isLiked, likesCount: likesCount);
    }

    throw Exception(_parseErrorMessage(response, 'Failed to update like'));
  }

  Future<List<CommunityPostComment>> fetchComments(int postId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/community-posts/$postId/comments/'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while loading comments.'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((item) => CommunityPostComment.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    throw Exception(_parseErrorMessage(response, 'Failed to load comments'));
  }

  Future<CommunityPostComment> addComment({
    required int postId,
    required String content,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/community-posts/$postId/comments/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'content': content.trim(),
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timed out while sending comment.'),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return CommunityPostComment.fromJson(decoded as Map<String, dynamic>);
    }

    throw Exception(_parseErrorMessage(response, 'Failed to post comment'));
  }
}

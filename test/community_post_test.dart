import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/features/community/models/community_post.dart';

void main() {
  group('CommunityPost model', () {
    test('parses Django CommunityPost JSON correctly', () {
      final json = {
        'id': 2,
        'author_name': 'win',
        'author_area': 'Block B',
        'title': 'Lost Cat near Block B',
        'content': 'Has anyone seen an orange tabby cat near Block B playground? Please contact unit 04-12.',
        'is_hidden': false,
        'created_at': '2026-10-20T15:12:48.996833Z',
      };

      final post = CommunityPost.fromJson(json);

      expect(post.id, 2);
      expect(post.authorName, 'win');
      expect(post.authorArea, 'Block B');
      expect(post.title, 'Lost Cat near Block B');
      expect(post.content, contains('orange tabby cat'));
      expect(post.isHidden, false);
      expect(post.createdAt.year, 2026);
    });

    test('handles fallback defaults when fields are missing or null', () {
      final json = <String, dynamic>{
        'id': 5,
        'title': 'Community Meeting',
      };

      final post = CommunityPost.fromJson(json);

      expect(post.id, 5);
      expect(post.authorName, 'Resident');
      expect(post.authorArea, 'Township');
      expect(post.title, 'Community Meeting');
      expect(post.content, '');
      expect(post.isHidden, false);
    });

    test('timeAgo returns readable formatting', () {
      final now = DateTime.now();
      final justNowPost = CommunityPost(
        id: 1,
        authorName: 'User',
        authorArea: 'Block A',
        title: 'Hi',
        content: 'Hello',
        isHidden: false,
        createdAt: now.subtract(const Duration(seconds: 10)),
      );
      expect(justNowPost.timeAgo, 'Just now');

      final minutesAgoPost = CommunityPost(
        id: 2,
        authorName: 'User',
        authorArea: 'Block A',
        title: 'Hi',
        content: 'Hello',
        isHidden: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(minutesAgoPost.timeAgo, '5m ago');

      final hoursAgoPost = CommunityPost(
        id: 3,
        authorName: 'User',
        authorArea: 'Block A',
        title: 'Hi',
        content: 'Hello',
        isHidden: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgoPost.timeAgo, '3h ago');
    });
  });
}

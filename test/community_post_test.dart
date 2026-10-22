import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/features/community/models/community_post.dart';
import 'package:neighbour_shield_mobile/features/community/models/community_post_comment.dart';

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

    test('parses likes_count, comments_count, and is_liked from JSON', () {
      final json = {
        'id': 10,
        'author_name': 'alice',
        'author_area': 'Block C',
        'title': 'Lost Dog',
        'content': 'Brown poodle lost near gate 3',
        'is_hidden': false,
        'created_at': '2026-10-22T10:00:00Z',
        'likes_count': 7,
        'comments_count': 3,
        'is_liked': true,
      };

      final post = CommunityPost.fromJson(json);

      expect(post.likesCount, 7);
      expect(post.commentsCount, 3);
      expect(post.isLiked, true);

      final updated = post.copyWith(likesCount: 8, isLiked: false);
      expect(updated.likesCount, 8);
      expect(updated.isLiked, false);
      expect(updated.commentsCount, 3);
      expect(updated.title, 'Lost Dog');
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

  group('CommunityPostComment model', () {
    test('parses comment JSON correctly', () {
      final json = {
        'id': 101,
        'post': 2,
        'author_name': 'bob',
        'author_role': 'volunteer',
        'content': 'I saw the cat earlier today near the bench!',
        'is_hidden': false,
        'created_at': '2026-10-22T08:30:00Z',
      };

      final comment = CommunityPostComment.fromJson(json);

      expect(comment.id, 101);
      expect(comment.postId, 2);
      expect(comment.authorName, 'bob');
      expect(comment.authorRole, 'volunteer');
      expect(comment.content, contains('near the bench'));
      expect(comment.isHidden, false);

      final map = comment.toJson();
      expect(map['author_name'], 'bob');
      expect(map['author_role'], 'volunteer');
      expect(map['post'], 2);
    });

    test('handles fallback defaults for comment', () {
      final json = <String, dynamic>{
        'id': 102,
        'content': 'Thanks!',
      };

      final comment = CommunityPostComment.fromJson(json);

      expect(comment.id, 102);
      expect(comment.postId, 0);
      expect(comment.authorName, 'Resident');
      expect(comment.authorRole, 'resident');
      expect(comment.content, 'Thanks!');
      expect(comment.isHidden, false);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/features/community/data/community_post_repository.dart';
import 'package:neighbour_shield_mobile/features/community/models/community_post.dart';
import 'package:neighbour_shield_mobile/features/community/models/community_post_comment.dart';
import 'package:neighbour_shield_mobile/features/community/presentation/widgets/community_post_card.dart';

class FakeCommunityPostRepository extends CommunityPostRepository {
  bool toggleLikeCalled = false;
  bool fetchCommentsCalled = false;
  bool addCommentCalled = false;

  @override
  Future<({bool isLiked, int likesCount})> toggleLike(int postId) async {
    toggleLikeCalled = true;
    return (isLiked: true, likesCount: 6);
  }

  @override
  Future<List<CommunityPostComment>> fetchComments(int postId) async {
    fetchCommentsCalled = true;
    return [
      CommunityPostComment(
        id: 1,
        postId: postId,
        authorName: 'Volunteer Sam',
        authorRole: 'volunteer',
        content: 'I checked the playground, cat is safe!',
        isHidden: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  @override
  Future<CommunityPostComment> addComment({
    required int postId,
    required String content,
  }) async {
    addCommentCalled = true;
    return CommunityPostComment(
      id: 2,
      postId: postId,
      authorName: 'Jane',
      authorRole: 'resident',
      content: content,
      isHidden: false,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('CommunityPostCard Widget', () {
    testWidgets('renders post content and action buttons', (tester) async {
      final repo = FakeCommunityPostRepository();
      final post = CommunityPost(
        id: 10,
        authorName: 'Winson',
        authorArea: 'Block B',
        title: 'Lost Cat',
        content: 'Orange tabby lost near the park.',
        isHidden: false,
        createdAt: DateTime.now(),
        likesCount: 5,
        commentsCount: 1,
        isLiked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityPostCard(
              post: post,
              repository: repo,
            ),
          ),
        ),
      );

      expect(find.text('Lost Cat'), findsOneWidget);
      expect(find.text('Orange tabby lost near the park.'), findsOneWidget);
      expect(find.text('5 likes'), findsOneWidget);
      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
    });

    testWidgets('tapping like triggers like animation and repository call', (tester) async {
      final repo = FakeCommunityPostRepository();
      final post = CommunityPost(
        id: 10,
        authorName: 'Winson',
        authorArea: 'Block B',
        title: 'Lost Cat',
        content: 'Orange tabby lost.',
        isHidden: false,
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityPostCard(
              post: post,
              repository: repo,
            ),
          ),
        ),
      );

      expect(find.text('Like'), findsOneWidget);

      await tester.tap(find.text('Like'));
      await tester.pumpAndSettle();

      expect(repo.toggleLikeCalled, isTrue);
      expect(find.text('Liked'), findsOneWidget);
      expect(find.text('6 likes'), findsOneWidget);
    });

    testWidgets('tapping comment expands comment section and allows posting comment', (tester) async {
      final repo = FakeCommunityPostRepository();
      final post = CommunityPost(
        id: 10,
        authorName: 'Winson',
        authorArea: 'Block B',
        title: 'Lost Cat',
        content: 'Orange tabby lost.',
        isHidden: false,
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: post,
                repository: repo,
              ),
            ),
          ),
        ),
      );

      // Tap Comment to expand
      await tester.tap(find.text('Comment'));
      await tester.pumpAndSettle();

      expect(repo.fetchCommentsCalled, isTrue);
      expect(find.text('Volunteer Sam'), findsOneWidget);
      expect(find.text('Volunteer'), findsOneWidget);
      expect(find.text('I checked the playground, cat is safe!'), findsOneWidget);
      expect(find.text('Hide Comments'), findsOneWidget);

      // Type in new comment
      await tester.enterText(find.byType(TextField), 'Great news, thank you!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(repo.addCommentCalled, isTrue);
      expect(find.text('Great news, thank you!'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });
  });
}

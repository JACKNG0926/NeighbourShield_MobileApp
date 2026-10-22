import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../data/community_post_repository.dart';
import '../../models/community_post.dart';
import '../../models/community_post_comment.dart';

class CommunityPostCard extends StatefulWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.repository,
    this.onPostUpdated,
  });

  final CommunityPost post;
  final CommunityPostRepository repository;
  final ValueChanged<CommunityPost>? onPostUpdated;

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard>
    with SingleTickerProviderStateMixin {
  late CommunityPost _post;
  bool _isLiking = false;

  // Comments state
  bool _isCommentsExpanded = false;
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  List<CommunityPostComment>? _comments;
  String? _commentsError;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnim;

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _likeAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant CommunityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleToggleLike() async {
    if (_isLiking) return;

    final prevPost = _post;
    final newIsLiked = !_post.isLiked;
    final newLikesCount = newIsLiked
        ? _post.likesCount + 1
        : (_post.likesCount > 0 ? _post.likesCount - 1 : 0);

    // Optimistic UI update
    setState(() {
      _isLiking = true;
      _post = _post.copyWith(
        isLiked: newIsLiked,
        likesCount: newLikesCount,
      );
    });

    if (newIsLiked) {
      _likeAnimController.forward(from: 0.0);
    }

    widget.onPostUpdated?.call(_post);

    try {
      final result = await widget.repository.toggleLike(_post.id);
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(
          isLiked: result.isLiked,
          likesCount: result.likesCount,
        );
      });
      widget.onPostUpdated?.call(_post);
    } catch (e) {
      if (!mounted) return;
      // Revert on failure
      setState(() => _post = prevPost);
      widget.onPostUpdated?.call(_post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.dangerColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _toggleCommentsSection() {
    setState(() {
      _isCommentsExpanded = !_isCommentsExpanded;
    });

    if (_isCommentsExpanded && _comments == null && !_isLoadingComments) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    try {
      final comments = await widget.repository.fetchComments(_post.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _handleSubmitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;

    setState(() => _isSubmittingComment = true);

    try {
      final newComment = await widget.repository.addComment(
        postId: _post.id,
        content: text,
      );

      if (!mounted) return;
      _commentController.clear();
      _commentFocusNode.unfocus();

      setState(() {
        final currentList = _comments ?? [];
        _comments = [...currentList, newComment];
        _post = _post.copyWith(
          commentsCount: _post.commentsCount + 1,
        );
      });

      widget.onPostUpdated?.call(_post);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.dangerColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        _post.authorName.isNotEmpty
                            ? _post.authorName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textColor,
                            ),
                          ),
                          Text(
                            _post.authorArea,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _post.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  _post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 6),

                // Content
                Text(
                  _post.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          // Engagement count stats bar (if likes or comments exist)
          if (_post.likesCount > 0 || _post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_post.likesCount > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_post.likesCount} ${_post.likesCount == 1 ? 'like' : 'likes'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (_post.commentsCount > 0)
                    GestureDetector(
                      onTap: _toggleCommentsSection,
                      child: Text(
                        '${_post.commentsCount} ${_post.commentsCount == 1 ? 'comment' : 'comments'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Actions Row (Like & Comment buttons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // LIKE BUTTON
                Expanded(
                  child: InkWell(
                    onTap: _handleToggleLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _likeScaleAnim,
                            child: Icon(
                              _post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 19,
                              color: _post.isLiked
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _post.isLiked ? 'Liked' : 'Like',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _post.isLiked
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _post.isLiked
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  height: 20,
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                ),

                // COMMENT BUTTON
                Expanded(
                  child: InkWell(
                    onTap: _toggleCommentsSection,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCommentsExpanded
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                            size: 18,
                            color: _isCommentsExpanded
                                ? AppTheme.primaryColor
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isCommentsExpanded ? 'Hide Comments' : 'Comment',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isCommentsExpanded
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _isCommentsExpanded
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // EXPANDABLE COMMENTS SECTION
          if (_isCommentsExpanded) _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Comments List
          if (_isLoadingComments)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            )
          else if (_commentsError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: AppTheme.dangerColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _commentsError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.dangerColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadComments,
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            )
          else if (_comments == null || _comments!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 28,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No comments yet. Start the conversation!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _comments!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final comment = _comments![index];
                return _buildCommentItem(comment);
              },
            ),

          // ADD COMMENT INPUT BAR
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSubmitComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed:
                      _isSubmittingComment ? null : _handleSubmitComment,
                  icon: _isSubmittingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommunityPostComment comment) {
    final isVolunteer = comment.authorRole == 'volunteer';
    final isAdmin = comment.authorRole == 'admin';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            comment.authorName.isNotEmpty
                ? comment.authorName[0].toUpperCase()
                : 'U',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    if (isVolunteer) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Volunteer',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ] else if (isAdmin) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

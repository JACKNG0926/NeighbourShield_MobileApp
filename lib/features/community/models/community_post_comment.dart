class CommunityPostComment {
  const CommunityPostComment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.isHidden,
    required this.createdAt,
  });

  final int id;
  final int postId;
  final String authorName;
  final String authorRole;
  final String content;
  final bool isHidden;
  final DateTime createdAt;

  factory CommunityPostComment.fromJson(Map<String, dynamic> json) {
    DateTime createdDate;
    if (json['created_at'] != null) {
      createdDate =
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    return CommunityPostComment(
      id: json['id'] as int? ?? 0,
      postId: json['post'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? 'Resident',
      authorRole: json['author_role'] as String? ?? 'resident',
      content: json['content'] as String? ?? '',
      isHidden: json['is_hidden'] == true,
      createdAt: createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': postId,
      'author_name': authorName,
      'author_role': authorRole,
      'content': content,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

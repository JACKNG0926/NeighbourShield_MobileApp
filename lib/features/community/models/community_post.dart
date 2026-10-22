class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorArea,
    required this.title,
    required this.content,
    required this.isHidden,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  final int id;
  final String authorName;
  final String authorArea;
  final String title;
  final String content;
  final bool isHidden;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  CommunityPost copyWith({
    int? id,
    String? authorName,
    String? authorArea,
    String? title,
    String? content,
    bool? isHidden,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorArea: authorArea ?? this.authorArea,
      title: title ?? this.title,
      content: content ?? this.content,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    DateTime createdDate;
    if (json['created_at'] != null) {
      createdDate =
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    return CommunityPost(
      id: json['id'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? 'Resident',
      authorArea: json['author_area'] as String? ?? 'Township',
      title: json['title'] as String? ?? 'Untitled Post',
      content: json['content'] as String? ?? '',
      isHidden: json['is_hidden'] == true,
      createdAt: createdDate,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'author_area': authorArea,
      'title': title,
      'content': content,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
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

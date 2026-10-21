class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorArea,
    required this.title,
    required this.content,
    required this.isHidden,
    required this.createdAt,
  });

  final int id;
  final String authorName;
  final String authorArea;
  final String title;
  final String content;
  final bool isHidden;
  final DateTime createdAt;

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
    );
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

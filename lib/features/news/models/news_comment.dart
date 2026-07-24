class NewsComment {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int newsId;
  final int? parentId;
  final String content;
  final DateTime createdAt;
  final List<NewsComment> replies;

  NewsComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.newsId,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  factory NewsComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    return NewsComment(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: user?['name']?.toString() ?? json['user_name']?.toString() ?? 'Citizen User',
      userAvatar: user?['avatar']?.toString() ?? json['user_avatar']?.toString(),
      newsId: json['news_id'] is int
          ? json['news_id'] as int
          : int.tryParse(json['news_id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] != null
          ? (json['parent_id'] is int
              ? json['parent_id'] as int
              : int.tryParse(json['parent_id'].toString()))
          : null,
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      replies: json['replies'] is List
          ? (json['replies'] as List)
              .map((r) => NewsComment.fromJson(r as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'news_id': newsId,
      'parent_id': parentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

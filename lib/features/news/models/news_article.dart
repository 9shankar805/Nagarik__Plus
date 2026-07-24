class NewsArticle {
  final int id;
  final String title;
  final String? titleNp;
  final String? category;
  final String? source;
  final String? sourceUrl;
  final String? imageUrl;
  final bool? isVerified;
  final bool? isFeatured;
  final DateTime? publishedAt;
  final String? content;
  final String? contentNp;
  final int? likeCount;
  final int? commentCount;
  final int? shareCount;
  final bool? isLiked;
  final bool? isBookmarked;

  NewsArticle({
    required this.id,
    required this.title,
    this.titleNp,
    this.category,
    this.source,
    this.sourceUrl,
    this.imageUrl,
    this.isVerified,
    this.isFeatured,
    this.publishedAt,
    this.content,
    this.contentNp,
    this.likeCount,
    this.commentCount,
    this.shareCount,
    this.isLiked,
    this.isBookmarked,
  });

  String displayTitle(bool isNepali) =>
      (isNepali && titleNp != null && titleNp!.isNotEmpty) ? titleNp! : title;
  String displayContent(bool isNepali) =>
      (isNepali && contentNp != null && contentNp!.isNotEmpty)
          ? contentNp!
          : (content ?? '');
  String displaySource(bool isNepali) => source ?? 'Nagarik Notice';
  String displayCategory(bool isNepali) => category ?? 'Notices';

  NewsArticle copyWith({
    int? id,
    String? title,
    String? titleNp,
    String? category,
    String? source,
    String? sourceUrl,
    String? imageUrl,
    bool? isVerified,
    bool? isFeatured,
    DateTime? publishedAt,
    String? content,
    String? contentNp,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      titleNp: titleNp ?? this.titleNp,
      category: category ?? this.category,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      content: content ?? this.content,
      contentNp: contentNp ?? this.contentNp,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      titleNp: json['title_np']?.toString(),
      category: json['category']?.toString(),
      source: json['source']?.toString(),
      sourceUrl: json['source_url']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      content: json['content']?.toString(),
      contentNp: json['content_np']?.toString(),
      likeCount: json['like_count'] is int ? json['like_count'] as int : int.tryParse(json['like_count']?.toString() ?? '0') ?? 0,
      commentCount: json['comment_count'] is int ? json['comment_count'] as int : int.tryParse(json['comment_count']?.toString() ?? '0') ?? 0,
      shareCount: json['share_count'] is int ? json['share_count'] as int : int.tryParse(json['share_count']?.toString() ?? '0') ?? 0,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      isBookmarked: json['is_bookmarked'] == true || json['is_bookmarked'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_np': titleNp,
      'category': category,
      'source': source,
      'source_url': sourceUrl,
      'image_url': imageUrl,
      'is_verified': isVerified,
      'is_featured': isFeatured,
      'published_at': publishedAt?.toIso8601String(),
      'content': content,
      'content_np': contentNp,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
    };
  }
}

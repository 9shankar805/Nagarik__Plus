
class NotificationItem {
  final String id;
  final String title;
  final String? titleNp;
  final String body;
  final String? bodyNp;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    this.titleNp,
    required this.body,
    this.bodyNp,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.data = const {},
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? titleNp,
    String? body,
    String? bodyNp,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      titleNp: titleNp ?? this.titleNp,
      body: body ?? this.body,
      bodyNp: bodyNp ?? this.bodyNp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      titleNp: json['title_np'] as String?,
      body: json['body'] as String,
      bodyNp: json['body_np'] as String?,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_np': titleNp,
      'body': body,
      'body_np': bodyNp,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
      'data': data,
    };
  }
}

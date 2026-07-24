
class ChatMessage {
  final String id;
  final String content;
  final String? contentNp;
  final bool isUser;
  final DateTime? timestamp;
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.content,
    this.contentNp,
    required this.isUser,
    this.timestamp,
    this.isTyping = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? contentNp,
    bool? isUser,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      contentNp: contentNp ?? this.contentNp,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      contentNp: json['content_np'] as String?,
      isUser: json['is_user'] as bool,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'content_np': contentNp,
      'is_user': isUser,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

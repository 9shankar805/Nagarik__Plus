
class AiSuggestion {
  final String id;
  final String title;
  final String? titleNp;
  final String? icon;

  AiSuggestion({
    required this.id,
    required this.title,
    this.titleNp,
    this.icon,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      id: json['id'] as String,
      title: json['title'] as String,
      titleNp: json['title_np'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_np': titleNp,
      'icon': icon,
    };
  }
}

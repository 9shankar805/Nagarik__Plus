
class NewsCategory {
  final String id;
  final String name;
  final String? nameNp;

  NewsCategory({
    required this.id,
    required this.name,
    this.nameNp,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameNp: json['name_np'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_np': nameNp,
    };
  }
}

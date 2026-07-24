
class NewsCategory {
  final String id;
  final String name;
  final String? nameNp;

  NewsCategory({
    required this.id,
    required this.name,
    this.nameNp,
  });

  factory NewsCategory.fromJson(Map&lt;String, dynamic&gt; json) {
    return NewsCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameNp: json['name_np'] as String?,
    );
  }

  Map&lt;String, dynamic&gt; toJson() {
    return {
      'id': id,
      'name': name,
      'name_np': nameNp,
    };
  }
}

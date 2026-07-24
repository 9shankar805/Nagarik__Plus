
class SocialServiceModel {
  final String id;
  final String? title;
  final String? titleNp;
  final String? subtitle;
  final String? subtitleNp;
  final String? icon;
  final String? color;
  final String? imageUrl;

  SocialServiceModel({
    required this.id,
    this.title,
    this.titleNp,
    this.subtitle,
    this.subtitleNp,
    this.icon,
    this.color,
    this.imageUrl,
  });

  factory SocialServiceModel.fromJson(Map&lt;String, dynamic&gt; json) {
    return SocialServiceModel(
      id: json['id'],
      title: json['title'],
      titleNp: json['title_np'],
      subtitle: json['subtitle'],
      subtitleNp: json['subtitle_np'],
      icon: json['icon'],
      color: json['color'],
      imageUrl: json['image_url'],
    );
  }
}


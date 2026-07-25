
class VitalEventModel {
  final String id;
  final String? title;
  final String? titleNp;
  final String? imageUrl;
  final String? bgColor;

  VitalEventModel({
    required this.id,
    this.title,
    this.titleNp,
    this.imageUrl,
    this.bgColor,
  });

  factory VitalEventModel.fromJson(Map<String, dynamic> json) {
    return VitalEventModel(
      id: json['id'],
      title: json['title'],
      titleNp: json['title_np'],
      imageUrl: json['image_url'],
      bgColor: json['bg_color'],
    );
  }
}



class BannerModel {
  final int id;
  final String? title;
  final String? titleNp;
  final String? description;
  final String? imageUrl;
  final String? linkType;
  final String? linkValue;

  BannerModel({
    required this.id,
    this.title,
    this.titleNp,
    this.description,
    this.imageUrl,
    this.linkType,
    this.linkValue,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      titleNp: json['title_np'],
      description: json['description'],
      imageUrl: json['image_url'],
      linkType: json['link_type'],
      linkValue: json['link_value'],
    );
  }
}


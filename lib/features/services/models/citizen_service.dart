
class CitizenService {
  final int id;
  final String title;
  final String? titleNp;
  final String slug;
  final String? description;
  final String? descriptionNp;
  final String? category;
  final String? icon;
  final String? imageUrl;
  final Map<String, dynamic>? eligibility;
  final Map<String, dynamic>? documents;
  final Map<String, dynamic>? steps;
  final String? fee;
  final String? processingTime;
  final List<dynamic>? faqs;

  CitizenService({
    required this.id,
    required this.title,
    this.titleNp,
    required this.slug,
    this.description,
    this.descriptionNp,
    this.category,
    this.icon,
    this.imageUrl,
    this.eligibility,
    this.documents,
    this.steps,
    this.fee,
    this.processingTime,
    this.faqs,
  });

  factory CitizenService.fromJson(Map<String, dynamic> json) {
    return CitizenService(
      id: json['id'] as int,
      title: json['title'] as String,
      titleNp: json['title_np'] as String?,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      descriptionNp: json['description_np'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      imageUrl: json['image_url'] as String?,
      eligibility: json['eligibility'] as Map<String, dynamic>?,
      documents: json['documents'] as Map<String, dynamic>?,
      steps: json['steps'] as Map<String, dynamic>?,
      fee: json['fee'] as String?,
      processingTime: json['processing_time'] as String?,
      faqs: json['faqs'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_np': titleNp,
      'slug': slug,
      'description': description,
      'description_np': descriptionNp,
      'category': category,
      'icon': icon,
      'image_url': imageUrl,
      'eligibility': eligibility,
      'documents': documents,
      'steps': steps,
      'fee': fee,
      'processing_time': processingTime,
      'faqs': faqs,
    };
  }
}

class ServiceOffice {
  final int id;
  final String name;
  final String? nameNp;
  final String? address;
  final String? addressNp;
  final String? phone;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;

  ServiceOffice({
    required this.id,
    required this.name,
    this.nameNp,
    this.address,
    this.addressNp,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
  });

  factory ServiceOffice.fromJson(Map<String, dynamic> json) {
    return ServiceOffice(
      id: json['id'] as int,
      name: json['name'] as String,
      nameNp: json['name_np'] as String?,
      address: json['address'] as String?,
      addressNp: json['address_np'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_np': nameNp,
      'address': address,
      'address_np': addressNp,
      'phone': phone,
      'email': email,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

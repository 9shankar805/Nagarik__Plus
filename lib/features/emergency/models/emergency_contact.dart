
class EmergencyContact {
  final int id;
  final String name;
  final String? nameNp;
  final String? phone;
  final String? description;
  final String? descriptionNp;
  final String? icon;
  final String? category;

  EmergencyContact({
    required this.id,
    required this.name,
    this.nameNp,
    this.phone,
    this.description,
    this.descriptionNp,
    this.icon,
    this.category,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as int,
      name: json['name'] as String,
      nameNp: json['name_np'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      descriptionNp: json['description_np'] as String?,
      icon: json['icon'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_np': nameNp,
      'phone': phone,
      'description': description,
      'description_np': descriptionNp,
      'icon': icon,
      'category': category,
    };
  }
}

class Hospital {
  final int id;
  final String name;
  final String? nameNp;
  final String? address;
  final String? addressNp;
  final String? phone;
  final String? type;
  final double? latitude;
  final double? longitude;

  Hospital({
    required this.id,
    required this.name,
    this.nameNp,
    this.address,
    this.addressNp,
    this.phone,
    this.type,
    this.latitude,
    this.longitude,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as int,
      name: json['name'] as String,
      nameNp: json['name_np'] as String?,
      address: json['address'] as String?,
      addressNp: json['address_np'] as String?,
      phone: json['phone'] as String?,
      type: json['type'] as String?,
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
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

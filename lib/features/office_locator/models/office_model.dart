import 'package:flutter/material.dart';

class OfficeModel {
  final int id;
  final String name;
  final String? nameNp;
  final String category;
  final String? address;
  final String? addressNp;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? openingHours;

  OfficeModel({
    required this.id,
    required this.name,
    this.nameNp,
    required this.category,
    this.address,
    this.addressNp,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.openingHours,
  });

  String displayName(bool isNepali) =>
      (isNepali && nameNp != null && nameNp!.isNotEmpty) ? nameNp! : name;
  String displayAddress(bool isNepali) =>
      (isNepali && addressNp != null && addressNp!.isNotEmpty)
          ? addressNp!
          : (address ?? 'Nepal');

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      nameNp: json['name_np']?.toString(),
      category: json['category']?.toString() ?? 'General',
      address: json['address']?.toString(),
      addressNp: json['address_np']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : (json['lat'] != null ? double.tryParse(json['lat'].toString()) : null),
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : (json['lng'] != null ? double.tryParse(json['lng'].toString()) : null),
      openingHours: json['opening_hours']?.toString() ?? json['hours']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_np': nameNp,
      'category': category,
      'address': address,
      'address_np': addressNp,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours,
    };
  }
}

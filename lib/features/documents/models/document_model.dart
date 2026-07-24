import 'dart:convert';

class DocumentModel {
  final String id;
  final String title;
  final String subtitle;
  final String type;      // matches AppAssets.forDocType()
  final String category;
  final String? assetImagePath;   // bundled asset (always shown)
  final String? localFilePath;    // user-uploaded file on device (Front image)
  final String? localBackFilePath; // user-uploaded Back image file on device
  final DateTime? expiryDate;
  final bool isUploaded;
  final Map<String, String> fields; // e.g. {'Number': '1234-5678'}

  const DocumentModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.category,
    this.assetImagePath,
    this.localFilePath,
    this.localBackFilePath,
    this.expiryDate,
    required this.isUploaded,
    this.fields = const {},
  });

  DocumentModel copyWith({
    String? localFilePath,
    String? localBackFilePath,
    bool? isUploaded,
    Map<String, String>? fields,
    String? subtitle,
    DateTime? expiryDate,
  }) {
    return DocumentModel(
      id: id,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      type: type,
      category: category,
      assetImagePath: assetImagePath,
      localFilePath: localFilePath ?? this.localFilePath,
      localBackFilePath: localBackFilePath ?? this.localBackFilePath,
      expiryDate: expiryDate ?? this.expiryDate,
      isUploaded: isUploaded ?? this.isUploaded,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'category': category,
        'assetImagePath': assetImagePath,
        'localFilePath': localFilePath,
        'localBackFilePath': localBackFilePath,
        'expiryDate': expiryDate?.toIso8601String(),
        'isUploaded': isUploaded,
        'fields': fields,
      };

  static String _categoryForType(String type) {
    switch (type.toLowerCase()) {
      case 'citizenship':
      case 'national_id':
      case 'passport':
      case 'voter_id':
        return 'Identity';
      case 'driving_license':
      case 'vehicle_bluebook':
        return 'Vehicle';
      case 'pan':
      case 'insurance':
      case 'property':
        return 'Finance';
      case 'academic':
        return 'Education';
      default:
        return 'Personal';
    }
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'other';
    final rawExpiry = json['expiryDate'] ?? json['expiry_date'];
    DateTime? expDate;
    if (rawExpiry != null) {
      expDate = DateTime.tryParse(rawExpiry.toString());
    }

    return DocumentModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Document',
      subtitle: json['subtitle']?.toString() ??
          json['document_number']?.toString() ??
          json['issue_date']?.toString() ??
          'Official Document',
      type: typeStr,
      category: json['category']?.toString() ?? _categoryForType(typeStr),
      assetImagePath: json['assetImagePath']?.toString(),
      localFilePath: json['localFilePath']?.toString() ?? json['file_path']?.toString() ?? json['file_url']?.toString(),
      localBackFilePath: json['localBackFilePath']?.toString(),
      expiryDate: expDate,
      isUploaded: json['isUploaded'] as bool? ?? (json['has_file'] as bool? ?? false),
      fields: (json['fields'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory DocumentModel.fromJsonString(String s) =>
      DocumentModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

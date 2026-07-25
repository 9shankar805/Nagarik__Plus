
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? dob;
  final String? address;
  final String? citizenshipNumber;
  final String? loginProvider;
  final bool pinSet;
  final bool biometricEnabled;
  final DateTime? createdAt;
  final int? documentCount;
  final int? reminderCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.dob,
    this.address,
    this.citizenshipNumber,
    this.loginProvider,
    required this.pinSet,
    this.biometricEnabled = false,
    this.createdAt,
    this.documentCount,
    this.reminderCount,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? dob,
    String? address,
    String? citizenshipNumber,
    String? loginProvider,
    bool? pinSet,
    bool? biometricEnabled,
    DateTime? createdAt,
    int? documentCount,
    int? reminderCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      citizenshipNumber: citizenshipNumber ?? this.citizenshipNumber,
      loginProvider: loginProvider ?? this.loginProvider,
      pinSet: pinSet ?? this.pinSet,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
      documentCount: documentCount ?? this.documentCount,
      reminderCount: reminderCount ?? this.reminderCount,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dob: json['dob'] as String?,
      address: json['address'] as String?,
      citizenshipNumber: json['citizenship_number'] as String?,
      loginProvider: json['login_provider'] as String?,
      pinSet: json['pin_set'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      documentCount: json['document_count'] as int?,
      reminderCount: json['reminder_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'dob': dob,
      'address': address,
      'citizenship_number': citizenshipNumber,
      'login_provider': loginProvider,
      'pin_set': pinSet,
      'biometric_enabled': biometricEnabled,
      'created_at': createdAt?.toIso8601String(),
      'document_count': documentCount,
      'reminder_count': reminderCount,
    };
  }
}


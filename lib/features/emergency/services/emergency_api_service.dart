import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/emergency_contact.dart';

class EmergencyData {
  final List<EmergencyContact> contacts;
  final List<Hospital> hospitals;

  EmergencyData({
    required this.contacts,
    required this.hospitals,
  });

  factory EmergencyData.fromJson(Map<String, dynamic> json) {
    final contactsRaw = (json['contacts'] ?? json['data']?['contacts']) as List?;
    final hospitalsRaw = (json['hospitals'] ?? json['data']?['hospitals']) as List?;

    return EmergencyData(
      contacts: contactsRaw != null
          ? contactsRaw
              .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      hospitals: hospitalsRaw != null
          ? hospitalsRaw
              .map((h) => Hospital.fromJson(h as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class EmergencyApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<EmergencyData>> getEmergencyData() async {
    return await _apiClient.get(
      '/emergency',
      fromJsonT: (json) {
        final Map<String, dynamic> rawMap =
            (json is Map && json['data'] != null && json['data'] is Map)
                ? json['data'] as Map<String, dynamic>
                : (json is Map ? json as Map<String, dynamic> : <String, dynamic>{});
        return EmergencyData.fromJson(rawMap);
      },
    );
  }
}

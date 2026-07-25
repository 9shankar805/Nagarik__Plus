import 'package:hive_flutter/hive_flutter.dart';
import '../services/emergency_api_service.dart';
import '../models/emergency_contact.dart';

class EmergencyRepository {
  final EmergencyApiService _apiService;
  final Box<EmergencyContact>? _contactsBox;
  final Box<Hospital>? _hospitalsBox;

  EmergencyRepository({
    EmergencyApiService? apiService,
    Box<EmergencyContact>? contactsBox,
    Box<Hospital>? hospitalsBox,
  })  : _apiService = apiService ?? EmergencyApiService(),
        _contactsBox = contactsBox,
        _hospitalsBox = hospitalsBox;

  Future<Map<String, List<dynamic>>> getEmergencyData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _contactsBox != null &&
        _contactsBox.isNotEmpty &&
        _hospitalsBox != null &&
        _hospitalsBox.isNotEmpty) {
      return {
        'contacts': _contactsBox.values.toList(),
        'hospitals': _hospitalsBox.values.toList(),
      };
    }

    try {
      final response = await _apiService.getEmergencyData();
      final emergencyData = response.data;
      final contacts = emergencyData?.contacts ?? <EmergencyContact>[];
      final hospitals = emergencyData?.hospitals ?? <Hospital>[];

      if (_contactsBox != null) {
        await _contactsBox.clear();
        await _contactsBox.addAll(contacts);
      }
      if (_hospitalsBox != null) {
        await _hospitalsBox.clear();
        await _hospitalsBox.addAll(hospitals);
      }

      return {
        'contacts': contacts,
        'hospitals': hospitals,
      };
    } catch (e) {
      if (_contactsBox != null &&
          _contactsBox.isNotEmpty &&
          _hospitalsBox != null &&
          _hospitalsBox.isNotEmpty) {
        return {
          'contacts': _contactsBox.values.toList(),
          'hospitals': _hospitalsBox.values.toList(),
        };
      }
      rethrow;
    }
  }
}

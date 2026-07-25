
import 'package:hive_flutter/hive_flutter.dart';
import '../services/citizen_service_api.dart';
import '../models/citizen_service.dart';

class ServicesRepository {
  final CitizenServiceApi _apiService;
  final Box<CitizenService>? _servicesBox;

  ServicesRepository({
    CitizenServiceApi? apiService,
    Box<CitizenService>? servicesBox,
    Box<ServiceOffice>? officesBox, // reserved for future use
  })  : _apiService = apiService ?? CitizenServiceApi(),
        _servicesBox = servicesBox;

  Future<List<CitizenService>> getServices({bool forceRefresh = false}) async {
    if (!forceRefresh && _servicesBox != null && _servicesBox.isNotEmpty) {
      return _servicesBox.values.toList();
    }

    try {
      final response = await _apiService.getServices();
      final services = response.data ?? [];
      if (_servicesBox != null) {
        await _servicesBox.clear();
        await _servicesBox.addAll(services);
      }
      return services;
    } catch (e) {
      if (_servicesBox != null && _servicesBox.isNotEmpty) {
        return _servicesBox.values.toList();
      }
      rethrow;
    }
  }

  Future<CitizenService> getService(String slug) async {
    try {
      final response = await _apiService.getService(slug);
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ServiceOffice>> getServiceOffices(String slug) async {
    try {
      final response = await _apiService.getServiceOffices(slug);
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }
}

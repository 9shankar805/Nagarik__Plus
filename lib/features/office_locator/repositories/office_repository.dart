import 'package:hive_flutter/hive_flutter.dart';
import '../models/office_model.dart';
import '../services/office_api_service.dart';

class OfficeRepository {
  final OfficeApiService _apiService;
  final Box<OfficeModel>? _officeBox;

  OfficeRepository({
    OfficeApiService? apiService,
    Box<OfficeModel>? officeBox,
  })  : _apiService = apiService ?? OfficeApiService(),
        _officeBox = officeBox;

  Future<List<OfficeModel>> getOffices({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _officeBox != null &&
        _officeBox.isNotEmpty &&
        category == null &&
        search == null) {
      return _officeBox.values.toList();
    }

    try {
      final response = await _apiService.getOffices(
        category: category,
        search: search,
        latitude: latitude,
        longitude: longitude,
      );
      final offices = response.data ?? [];
      if (_officeBox != null && category == null && search == null) {
        await _officeBox.clear();
        await _officeBox.addAll(offices);
      }
      return offices;
    } catch (e) {
      if (_officeBox != null && _officeBox.isNotEmpty) {
        return _officeBox.values.toList();
      }
      rethrow;
    }
  }
}

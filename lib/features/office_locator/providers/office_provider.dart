import 'package:flutter/foundation.dart';
import '../models/office_model.dart';
import '../repositories/office_repository.dart';

enum OfficeStatus { initial, loading, loaded, error }

class OfficeProvider extends ChangeNotifier {
  final OfficeRepository _repository;

  OfficeStatus _status = OfficeStatus.initial;
  List<OfficeModel> _offices = [];
  String? _errorMessage;

  OfficeStatus get status => _status;
  List<OfficeModel> get offices => _offices;
  String? get errorMessage => _errorMessage;

  OfficeProvider({OfficeRepository? repository})
      : _repository = repository ?? OfficeRepository();

  Future<void> loadOffices({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    bool forceRefresh = false,
  }) async {
    _status = OfficeStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _offices = await _repository.getOffices(
        category: category,
        search: search,
        latitude: latitude,
        longitude: longitude,
        forceRefresh: forceRefresh,
      );
      _status = OfficeStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = OfficeStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshOffices() async {
    await loadOffices(forceRefresh: true);
  }
}

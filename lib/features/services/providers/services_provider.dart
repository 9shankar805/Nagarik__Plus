
import 'package:flutter/foundation.dart';
import '../models/citizen_service.dart';
import '../repositories/services_repository.dart';

enum ServicesStatus { initial, loading, loaded, error }

class ServicesProvider extends ChangeNotifier {
  final ServicesRepository _repository;

  ServicesStatus _status = ServicesStatus.initial;
  List<CitizenService> _services = [];
  String? _errorMessage;

  ServicesStatus get status => _status;
  List<CitizenService> get services => _services;
  String? get errorMessage => _errorMessage;

  ServicesProvider({ServicesRepository? repository})
      : _repository = repository ?? ServicesRepository();

  Future<void> loadServices({bool forceRefresh = false}) async {
    _status = ServicesStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _services = await _repository.getServices(forceRefresh: forceRefresh);
      _status = ServicesStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ServicesStatus.error;
    }
    notifyListeners();
  }

  Future<CitizenService> loadService(String slug) async {
    try {
      return await _repository.getService(slug);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<List<ServiceOffice>> loadServiceOffices(String slug) async {
    try {
      return await _repository.getServiceOffices(slug);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }
}

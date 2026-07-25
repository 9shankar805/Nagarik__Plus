
import 'package:flutter/foundation.dart';
import '../models/emergency_contact.dart';
import '../repositories/emergency_repository.dart';

enum EmergencyStatus { initial, loading, loaded, error }

class EmergencyProvider extends ChangeNotifier {
  final EmergencyRepository _repository;

  EmergencyStatus _status = EmergencyStatus.initial;
  List<EmergencyContact> _contacts = [];
  List<Hospital> _hospitals = [];
  String? _errorMessage;

  EmergencyStatus get status => _status;
  List<EmergencyContact> get contacts => _contacts;
  List<Hospital> get hospitals => _hospitals;
  String? get errorMessage => _errorMessage;

  EmergencyProvider({EmergencyRepository? repository})
      : _repository = repository ?? EmergencyRepository();

  Future<void> loadEmergencyData({bool forceRefresh = false}) async {
    _status = EmergencyStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _repository.getEmergencyData(forceRefresh: forceRefresh);
      _contacts = (data['contacts'])?.cast<EmergencyContact>() ?? [];
      _hospitals = (data['hospitals'])?.cast<Hospital>() ?? [];
      _status = EmergencyStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = EmergencyStatus.error;
    }
    notifyListeners();
  }
}

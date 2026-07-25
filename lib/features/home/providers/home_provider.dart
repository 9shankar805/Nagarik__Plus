
import 'package:flutter/foundation.dart';
import '../models/banner_model.dart';
import '../models/social_service_model.dart';
import '../models/vital_event_model.dart';
import '../repositories/home_repository.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository;

  HomeStatus _status = HomeStatus.initial;
  List<BannerModel> _banners = [];
  List<SocialServiceModel> _socialServices = [];
  List<VitalEventModel> _vitalEvents = [];
  String? _errorMessage;

  HomeStatus get status => _status;
  List<BannerModel> get banners => _banners;
  List<SocialServiceModel> get socialServices => _socialServices;
  List<VitalEventModel> get vitalEvents => _vitalEvents;
  String? get errorMessage => _errorMessage;

  HomeProvider({HomeRepository? repository})
      : _repository = repository ?? HomeRepository();

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    _status = HomeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _banners = await _repository.getBanners();
      _socialServices = await _repository.getSocialServices();
      _vitalEvents = await _repository.getVitalEvents();
      _status = HomeStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = HomeStatus.error;
    }
    notifyListeners();
  }
}


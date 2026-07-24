import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../auth/models/user_model.dart';
import '../repositories/profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileStatus _status = ProfileStatus.initial;
  User? _user;
  String? _errorMessage;

  ProfileStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  ProfileProvider({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _repository.getProfile();
      _user = user;
      _status = ProfileStatus.loaded;
    } catch (e) {
      _status = ProfileStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final updatedUser = await _repository.updateProfile(data);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadAvatar(File file) async {
    try {
      final updatedUser = await _repository.uploadAvatar(file);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

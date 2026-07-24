
import 'package:flutter/foundation.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final isAuthenticated = await _repository.isAuthenticated();
      if (isAuthenticated) {
        _user = await _repository.getProfile();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      _user = response.user;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );
      _user = response.user;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> changePin({required String currentPin, required String newPin}) async {
    await _repository.changePin(currentPin: currentPin, newPin: newPin);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
}


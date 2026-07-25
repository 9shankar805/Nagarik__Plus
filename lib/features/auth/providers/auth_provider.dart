
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isNewUser = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isNewUser => _isNewUser;

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

  Future<bool> loginWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _isNewUser = false;
    notifyListeners();
    try {
      final response = await _repository.loginWithGoogle();
      if (response != null) {
        _user = response.user;
        _isNewUser = response.isNewUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _isNewUser = false;
    notifyListeners();
    try {
      final response = await _repository.loginWithApple();
      if (response != null) {
        _user = response.user;
        _isNewUser = response.isNewUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
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

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.forgotPassword(email: email);
      _status = AuthStatus.initial;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return {};
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.resetPassword(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _status = AuthStatus.initial;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }
}


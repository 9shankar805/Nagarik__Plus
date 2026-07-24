
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  bool _isConnected = false;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _isConnected = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
    _connectionController.add(_isConnected);
  }

  void dispose() {
    _connectionController.close();
  }
}


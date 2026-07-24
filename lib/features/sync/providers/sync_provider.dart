import 'package:flutter/foundation.dart';
import '../../../core/services/sync_service.dart';
import '../services/sync_api_service.dart';

enum SyncStatusState { initial, syncing, synced, error }

class SyncProvider extends ChangeNotifier {
  final SyncApiService _apiService;
  final SyncService _syncService;

  SyncStatusState _state = SyncStatusState.initial;
  SyncStatus _status = SyncStatus(
    isSyncing: false,
    autoSyncEnabled: true,
    lastSyncedAt: null,
    pendingMutationsCount: 0,
  );
  String? _errorMessage;

  SyncStatusState get state => _state;
  SyncStatus get status => _status;
  bool get autoSyncEnabled => _status.autoSyncEnabled;
  bool get isSyncing => _status.isSyncing || _syncService.isSyncing;
  String? get lastSyncedAt => _status.lastSyncedAt;
  int get pendingMutationsCount => _status.pendingMutationsCount;
  String? get errorMessage => _errorMessage;

  SyncProvider({
    SyncApiService? apiService,
    SyncService? syncService,
  })  : _apiService = apiService ?? SyncApiService(),
        _syncService = syncService ?? SyncService();

  Future<void> fetchStatus() async {
    _state = SyncStatusState.syncing;
    notifyListeners();
    try {
      final response = await _apiService.getSyncStatus();
      if (response.data != null) {
        _status = response.data!;
      }
      _state = SyncStatusState.synced;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SyncStatusState.error;
    }
    notifyListeners();
  }

  Future<void> toggleAutoSync(bool enable) async {
    _state = SyncStatusState.syncing;
    notifyListeners();
    try {
      final response = enable
          ? await _apiService.enableSync()
          : await _apiService.disableSync();
      if (response.data != null) {
        _status = response.data!;
      }
      if (enable) {
        _syncService.startPeriodicSync();
      } else {
        _syncService.stopPeriodicSync();
      }
      _state = SyncStatusState.synced;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SyncStatusState.error;
    }
    notifyListeners();
  }

  Future<void> performManualSync() async {
    _state = SyncStatusState.syncing;
    _status = SyncStatus(
      isSyncing: true,
      autoSyncEnabled: _status.autoSyncEnabled,
      lastSyncedAt: _status.lastSyncedAt,
      pendingMutationsCount: _status.pendingMutationsCount,
    );
    notifyListeners();

    try {
      await _syncService.triggerSync();
      final response = await _apiService.triggerSync();
      if (response.data != null) {
        _status = response.data!;
      } else {
        _status = SyncStatus(
          isSyncing: false,
          autoSyncEnabled: _status.autoSyncEnabled,
          lastSyncedAt: DateTime.now().toIso8601String(),
          pendingMutationsCount: 0,
        );
      }
      _state = SyncStatusState.synced;
    } catch (e) {
      _status = SyncStatus(
        isSyncing: false,
        autoSyncEnabled: _status.autoSyncEnabled,
        lastSyncedAt: DateTime.now().toIso8601String(),
        pendingMutationsCount: 0,
      );
      _state = SyncStatusState.synced;
    }
    notifyListeners();
  }
}

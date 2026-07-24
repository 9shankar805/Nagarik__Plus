import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class SyncStatus {
  final bool isSyncing;
  final bool autoSyncEnabled;
  final String? lastSyncedAt;
  final int pendingMutationsCount;

  SyncStatus({
    required this.isSyncing,
    required this.autoSyncEnabled,
    this.lastSyncedAt,
    required this.pendingMutationsCount,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      isSyncing: json['is_syncing'] is bool ? json['is_syncing'] as bool : false,
      autoSyncEnabled: json['auto_sync_enabled'] is bool ? json['auto_sync_enabled'] as bool : true,
      lastSyncedAt: json['last_synced_at']?.toString(),
      pendingMutationsCount: (json['pending_mutations_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_syncing': isSyncing,
      'auto_sync_enabled': autoSyncEnabled,
      'last_synced_at': lastSyncedAt,
      'pending_mutations_count': pendingMutationsCount,
    };
  }
}

class SyncApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<SyncStatus>> getSyncStatus() async {
    return await _apiClient.get(
      '/sync/status',
      fromJsonT: (json) {
        final rawMap = (json is Map && json['data'] != null)
            ? json['data'] as Map<String, dynamic>
            : json as Map<String, dynamic>;
        return SyncStatus.fromJson(rawMap);
      },
    );
  }

  Future<ApiResponse<SyncStatus>> enableSync() async {
    return await _apiClient.post(
      '/sync/enable',
      fromJsonT: (json) {
        final rawMap = (json is Map && json['data'] != null)
            ? json['data'] as Map<String, dynamic>
            : json as Map<String, dynamic>;
        return SyncStatus.fromJson(rawMap);
      },
    );
  }

  Future<ApiResponse<SyncStatus>> disableSync() async {
    return await _apiClient.post(
      '/sync/disable',
      fromJsonT: (json) {
        final rawMap = (json is Map && json['data'] != null)
            ? json['data'] as Map<String, dynamic>
            : json as Map<String, dynamic>;
        return SyncStatus.fromJson(rawMap);
      },
    );
  }

  Future<ApiResponse<SyncStatus>> triggerSync() async {
    return await _apiClient.post(
      '/sync/trigger',
      fromJsonT: (json) {
        final rawMap = (json is Map && json['data'] != null)
            ? json['data'] as Map<String, dynamic>
            : json as Map<String, dynamic>;
        return SyncStatus.fromJson(rawMap);
      },
    );
  }
}

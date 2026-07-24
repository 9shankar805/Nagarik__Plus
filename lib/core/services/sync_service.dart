import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../network/api_client.dart';
import '../network/offline_queue.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => triggerSync());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await drainOfflineQueue();
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> drainOfflineQueue() async {
    if (!Hive.isBoxOpen('offline_queue')) return 0;
    final box = Hive.box<QueuedRequest>('offline_queue');
    if (box.isEmpty) return 0;

    final requests = box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    int processedCount = 0;
    final ApiClient apiClient = ApiClient();

    for (final req in requests) {
      try {
        if (req.method.toUpperCase() == 'POST') {
          await apiClient.post(req.path, data: req.data);
        } else if (req.method.toUpperCase() == 'PUT') {
          await apiClient.dio.put(req.path, data: req.data);
        } else if (req.method.toUpperCase() == 'DELETE') {
          await apiClient.dio.delete(req.path);
        }
        await req.delete();
        processedCount++;
      } catch (e) {
        // If conflict or client error occurs, resolve via Last-Write-Wins (discard obsolete mutation)
        if (e.toString().contains('409') || e.toString().contains('422')) {
          await req.delete();
        } else {
          break; // Stop loop on network outage, retry next sync cycle
        }
      }
    }
    return processedCount;
  }
}

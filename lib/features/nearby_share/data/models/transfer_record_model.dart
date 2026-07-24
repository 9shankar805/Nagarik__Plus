import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum TransferDirection { sent, received }

/// Persisted history record for a completed transfer
class TransferRecord {
  final String id;
  final String fileName;
  final String category;
  final int fileSizeBytes;
  final TransferDirection direction;
  final String peerName;
  final DateTime timestamp;
  final String? localPath;
  final bool checksumVerified;

  const TransferRecord({
    required this.id,
    required this.fileName,
    required this.category,
    required this.fileSizeBytes,
    required this.direction,
    required this.peerName,
    required this.timestamp,
    this.localPath,
    this.checksumVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'category': category,
    'fileSizeBytes': fileSizeBytes,
    'direction': direction.name,
    'peerName': peerName,
    'timestamp': timestamp.toIso8601String(),
    'localPath': localPath,
    'checksumVerified': checksumVerified,
  };

  factory TransferRecord.fromJson(Map<String, dynamic> j) => TransferRecord(
    id: j['id'] as String,
    fileName: j['fileName'] as String,
    category: j['category'] as String? ?? 'file',
    fileSizeBytes: j['fileSizeBytes'] as int? ?? 0,
    direction: TransferDirection.values.byName(j['direction'] as String),
    peerName: j['peerName'] as String? ?? 'Unknown',
    timestamp: DateTime.parse(j['timestamp'] as String),
    localPath: j['localPath'] as String?,
    checksumVerified: j['checksumVerified'] as bool? ?? false,
  );

  String get sizeLabel {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}

class TransferHistoryRepository {
  static const _key = 'nagarik_share_history_v2';

  Future<List<TransferRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final records = <TransferRecord>[];
    for (final s in raw) {
      try {
        records.add(TransferRecord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  Future<void> add(TransferRecord record) async {
    final all = await loadAll();
    all.insert(0, record);
    final trimmed = all.take(200).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, trimmed.map((r) => jsonEncode(r.toJson())).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, all.map((r) => jsonEncode(r.toJson())).toList());
  }
}

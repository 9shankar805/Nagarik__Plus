import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Represents a file queued or in-progress for transfer
class TransferFileModel {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String category;   // image, video, audio, apk, document, file
  final String? checksum;  // MD5 checksum for integrity verification
  final int totalChunks;

  /// Progress fields (mutable during transfer)
  double progress;           // 0.0 – 1.0
  TransferStatus status;
  double speedBps;
  int etaSeconds;
  String? savedPath;         // final saved path on receiver

  TransferFileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.category,
    this.checksum,
    this.totalChunks = 0,
    this.progress = 0.0,
    this.status = TransferStatus.pending,
    this.speedBps = 0.0,
    this.etaSeconds = 0,
    this.savedPath,
  });

  /// Metadata JSON sent before actual file transfer
  Map<String, dynamic> toMetadata() => {
    'id': id,
    'fileName': name,
    'fileSize': sizeBytes,
    'category': category,
    'checksum': checksum ?? '',
    'totalChunks': totalChunks,
  };

  static TransferFileModel fromMetadata(Map<String, dynamic> json) {
    return TransferFileModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['fileName'] as String,
      path: '',
      sizeBytes: json['fileSize'] as int? ?? 0,
      category: json['category'] as String? ?? 'file',
      checksum: json['checksum'] as String?,
      totalChunks: json['totalChunks'] as int? ?? 0,
      status: TransferStatus.receiving,
    );
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String get speedLabel {
    if (speedBps < 1024) return '${speedBps.toStringAsFixed(0)}B/s';
    if (speedBps < 1024 * 1024) {
      return '${(speedBps / 1024).toStringAsFixed(1)}KB/s';
    }
    return '${(speedBps / (1024 * 1024)).toStringAsFixed(1)}MB/s';
  }

  static String categoryOf(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const images = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    const videos = ['mp4', 'mkv', 'avi', 'mov', '3gp', 'webm'];
    const audios = ['mp3', 'aac', 'wav', 'flac', 'm4a', 'ogg', 'opus'];
    const docs = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv'];
    if (images.contains(ext)) return 'image';
    if (videos.contains(ext)) return 'video';
    if (audios.contains(ext)) return 'audio';
    if (ext == 'apk') return 'apk';
    if (docs.contains(ext)) return 'document';
    return 'file';
  }
}

enum TransferStatus {
  pending,
  sending,
  receiving,
  verifying,
  completed,
  failed,
  cancelled,
}

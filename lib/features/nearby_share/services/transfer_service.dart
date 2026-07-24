import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/transfer_file_model.dart';
import '../data/models/transfer_record_model.dart';
import 'socket_service.dart';

const _uuid = Uuid();

/// High-level transfer engine.
/// Manages the file queue, tracks per-file progress, saves history.
class TransferService {
  static final TransferService _instance = TransferService._internal();
  factory TransferService() => _instance;
  TransferService._internal();

  final _socket  = SocketService();
  final _history = TransferHistoryRepository();

  final _filesCtrl    = StreamController<List<TransferFileModel>>.broadcast();
  final _progressCtrl = StreamController<TransferFileModel>.broadcast();

  Stream<List<TransferFileModel>> get filesStream    => _filesCtrl.stream;
  Stream<TransferFileModel>       get progressStream => _progressCtrl.stream;

  final List<TransferFileModel> _queue = [];
  bool _isSending = false;
  bool _cancelled = false;

  List<TransferFileModel> get queue => List.unmodifiable(_queue);

  // ─── SENDER ───────────────────────────────────────────────────────────────

  /// Add files to the send queue
  void addFiles(List<String> paths) {
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      final name = p.basename(path);
      _queue.add(TransferFileModel(
        id:       _uuid.v4(),
        name:     name,
        path:     path,
        sizeBytes: file.lengthSync(),
        category:  TransferFileModel.categoryOf(name),
        status:    TransferStatus.pending,
      ));
    }
    _filesCtrl.add(List.unmodifiable(_queue));
  }

  void removeFile(String id) {
    _queue.removeWhere((f) => f.id == id);
    _filesCtrl.add(List.unmodifiable(_queue));
  }

  void clearQueue() {
    _queue.clear();
    _filesCtrl.add([]);
  }

  /// Start sending all queued files to the receiver
  Future<void> sendAll({
    required String receiverIp,
    required int port,
    required String peerName,
  }) async {
    if (_isSending) return;
    _isSending = true;
    _cancelled = false;

    for (final fileModel in _queue) {
      if (_cancelled) break;
      if (fileModel.status == TransferStatus.completed) continue;

      fileModel.status = TransferStatus.sending;
      _progressCtrl.add(fileModel);

      final success = await _socket.sendFile(
        receiverIp:  receiverIp,
        port:        port,
        fileModel:   fileModel,
        onProgress: (id, transferred, total, speed, eta) {
          fileModel.progress   = total > 0 ? transferred / total : 0;
          fileModel.speedBps   = speed;
          fileModel.etaSeconds = eta;
          _progressCtrl.add(fileModel);
        },
      );

      fileModel.status = success ? TransferStatus.completed : TransferStatus.failed;
      _progressCtrl.add(fileModel);

      if (success) {
        await _history.add(TransferRecord(
          id:           _uuid.v4(),
          fileName:     fileModel.name,
          category:     fileModel.category,
          fileSizeBytes: fileModel.sizeBytes,
          direction:    TransferDirection.sent,
          peerName:     peerName,
          timestamp:    DateTime.now(),
          checksumVerified: true,
        ));
      }
    }

    _isSending = false;
    _filesCtrl.add(List.unmodifiable(_queue));
  }

  // ─── RECEIVER ─────────────────────────────────────────────────────────────

  /// Start TCP server to receive incoming files
  Future<int> startReceiveServer({required String peerName}) async {
    _cancelled = false;
    return _socket.startServer(
      onFileReceived: (file, savedPath, checksumOk) async {
        file.status    = checksumOk ? TransferStatus.completed : TransferStatus.failed;
        file.savedPath = savedPath;
        _queue.add(file);
        _filesCtrl.add(List.unmodifiable(_queue));
        _progressCtrl.add(file);

        // Trigger media scanner
        try {
          const MethodChannel('com.nagarikplus.nagarik_plus/media_scanner')
              .invokeMethod('scanFile', {'path': savedPath});
        } catch (_) {}

        if (checksumOk) {
          await _history.add(TransferRecord(
            id:           _uuid.v4(),
            fileName:     file.name,
            category:     file.category,
            fileSizeBytes: file.sizeBytes,
            direction:    TransferDirection.received,
            peerName:     peerName,
            timestamp:    DateTime.now(),
            localPath:    savedPath,
            checksumVerified: true,
          ));
        }
      },
      onProgress: (fileId, transferred, total, speed, eta) {
        final idx = _queue.indexWhere((f) => f.id == fileId);
        if (idx != -1) {
          final f = _queue[idx];
          f.progress   = total > 0 ? transferred / total : 0;
          f.speedBps   = speed;
          f.etaSeconds = eta;
          _progressCtrl.add(f);
        }
      },
    );
  }

  Future<void> stopReceiveServer() => _socket.stopServer();

  void cancelAll() {
    _cancelled = true;
    _socket.cancelTransfer();
    _isSending = false;
  }

  Future<List<TransferRecord>> loadHistory() => _history.loadAll();
  Future<void> clearHistory()                 => _history.clear();
  Future<void> deleteHistory(String id)       => _history.delete(id);
}

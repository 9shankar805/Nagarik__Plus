import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/models/transfer_file_model.dart';

const int kTransferPort = 8888;

typedef ProgressCallback = void Function(
  String fileId,
  int bytesTransferred,
  int totalBytes,
  double speedBps,
  int etaSeconds,
);

typedef FileReceivedCallback = void Function(
  TransferFileModel file,
  String savedPath,
  bool checksumOk,
);

/// TCP socket file transfer engine.
///
/// Protocol (both sides use DataInput/DataOutputStream style framing):
///   SENDER → [4-byte int: meta length][meta JSON bytes][raw file bytes]
///   RECEIVER → [4-byte int: result length][result JSON bytes]
///
/// The Kotlin side (SocketServer / SocketClient) uses the identical framing,
/// so cross-device transfers also work.
class SocketService {
  static final SocketService _i = SocketService._();
  factory SocketService() => _i;
  SocketService._();

  ServerSocket? _server;
  bool _listening = false;
  bool _cancelled = false;

  bool get isListening => _listening;

  // ── SERVER (receiver side) ─────────────────────────────────────────────────

  Future<int> startServer({
    required FileReceivedCallback onFileReceived,
    required ProgressCallback onProgress,
    int port = kTransferPort,
  }) async {
    if (_listening) await stopServer();
    _cancelled = false;

    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port)
          .catchError((_) => ServerSocket.bind(InternetAddress.anyIPv4, 0));
      _listening = true;

      _server!.listen(
        (socket) => _handleClient(socket, onFileReceived, onProgress),
        onError: (_) { _listening = false; },
        onDone:  () { _listening = false; },
      );
      return _server!.port;
    } catch (_) {
      _listening = false;
      return 0;
    }
  }

  Future<void> stopServer() async {
    _cancelled = true;
    await _server?.close();
    _server    = null;
    _listening = false;
  }

  Future<void> _handleClient(
    Socket socket,
    FileReceivedCallback onFileReceived,
    ProgressCallback onProgress,
  ) async {
    // Collect all data first via a StreamReader helper
    final reader = _SocketReader(socket);

    try {
      socket.setOption(SocketOption.tcpNoDelay, true);

      // 1. Read 4-byte length + metadata JSON
      final metaLen   = await reader.readInt32();
      if (metaLen == null || metaLen <= 0 || metaLen > 1024 * 1024) {
        socket.destroy(); return;
      }
      final metaBytes = await reader.readBytes(metaLen);
      if (metaBytes == null) { socket.destroy(); return; }

      final meta     = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;
      final fileInfo = TransferFileModel.fromMetadata(meta);
      final fileSize = fileInfo.sizeBytes;

      // 2. Send ACK  [4-byte length][JSON]
      const ackJson = '{"ack":true}';
      _sendFrame(socket, utf8.encode(ackJson));

      // 3. Prepare save location
      final base    = await getExternalStorageDirectory() ??
                      await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(base.path, 'NagarikShare'));
      await destDir.create(recursive: true);

      String destPath = p.join(destDir.path, fileInfo.name);
      if (await File(destPath).exists()) {
        final ext  = p.extension(fileInfo.name);
        final stem = p.basenameWithoutExtension(fileInfo.name);
        destPath   = p.join(destDir.path, '${stem}_${DateTime.now().millisecondsSinceEpoch}$ext');
      }

      // 4. Read exactly [fileSize] bytes → write to file
      final sink       = File(destPath).openWrite();
      int   received   = 0;
      int   lastCheck  = 0;
      var   lastTime   = DateTime.now();
      double speed     = 0;

      while (received < fileSize && !_cancelled) {
        final want  = (fileSize - received).clamp(0, 64 * 1024).toInt();
        final chunk = await reader.readBytes(want);
        if (chunk == null || chunk.isEmpty) break;

        sink.add(chunk);
        received += chunk.length;

        final now = DateTime.now();
        final ms  = now.difference(lastTime).inMilliseconds;
        if (ms >= 300) {
          speed      = (received - lastCheck) / (ms / 1000.0);
          lastCheck  = received;
          lastTime   = now;
        }
        final eta = (speed > 0 && fileSize > 0)
            ? ((fileSize - received) / speed).round() : 0;
        onProgress(fileInfo.id, received, fileSize, speed, eta);
      }

      await sink.flush();
      await sink.close();

      // 5. Verify checksum
      bool checksumOk = true;
      final expectedCs = fileInfo.checksum ?? '';
      if (expectedCs.isNotEmpty) {
        final bytes    = await File(destPath).readAsBytes();
        final computed = md5.convert(bytes).toString();
        checksumOk     = computed.toLowerCase() == expectedCs.toLowerCase();
      }

      // 6. Send result
      final resultJson = jsonEncode({'success': true, 'checksumOk': checksumOk});
      _sendFrame(socket, utf8.encode(resultJson));

      await socket.flush();
      socket.destroy();

      fileInfo.savedPath = destPath;
      fileInfo.status    = checksumOk ? TransferStatus.completed : TransferStatus.failed;
      onFileReceived(fileInfo, destPath, checksumOk);
    } catch (e, st) {
      print('NagarikShare _handleClient error: $e\n$st');
      socket.destroy();
    } finally {
      reader.dispose();
    }
  }

  // ── CLIENT (sender side) ───────────────────────────────────────────────────

  Future<bool> sendFile({
    required String receiverIp,
    required int port,
    required TransferFileModel fileModel,
    required ProgressCallback onProgress,
  }) async {
    _cancelled = false;
    Socket? socket;

    // Retry socket connection up to 10 times (10 seconds total) to allow Wi-Fi association
    for (int attempt = 1; attempt <= 10; attempt++) {
      if (_cancelled) return false;
      try {
        socket = await Socket.connect(receiverIp, port,
            timeout: const Duration(seconds: 3));
        if (socket != null) break;
      } catch (e) {
        if (attempt == 10) return false;
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    try {
      socket!.setOption(SocketOption.tcpNoDelay, true);
      final reader = _SocketReader(socket);

      try {
        final file       = File(fileModel.path);
        final totalBytes = await file.length();

        // 1. Compute MD5 for files ≤ 50 MB
        String checksum = '';
        if (totalBytes > 0 && totalBytes <= 50 * 1024 * 1024) {
          final bytes = await file.readAsBytes();
          checksum    = md5.convert(bytes).toString();
        }

        // 2. Send metadata frame
        final metaJson = jsonEncode({
          'id':          fileModel.id,
          'fileName':    fileModel.name,
          'fileSize':    totalBytes,
          'category':    fileModel.category,
          'checksum':    checksum,
          'totalChunks': (totalBytes / (256 * 1024)).ceil(),
        });
        _sendFrame(socket, utf8.encode(metaJson));
        await socket.flush();

        // 3. Wait for ACK
        final ackLen   = await reader.readInt32().timeout(
            const Duration(seconds: 15), onTimeout: () => null);
        if (ackLen == null) { socket.destroy(); return false; }
        await reader.readBytes(ackLen); // consume ACK body

        // 4. Stream file bytes
        final stream   = file.openRead();
        int   sent     = 0;
        int   lastCheck = 0;
        var   lastTime  = DateTime.now();
        double speed   = 0;

        await for (final chunk in stream) {
          if (_cancelled) { socket.destroy(); return false; }
          socket.add(chunk);
          sent += chunk.length;

          final now = DateTime.now();
          final ms  = now.difference(lastTime).inMilliseconds;
          if (ms >= 300) {
            speed      = (sent - lastCheck) / (ms / 1000.0);
            lastCheck  = sent;
            lastTime   = now;
          }
          final eta = (speed > 0)
              ? ((totalBytes - sent) / speed).round() : 0;
          onProgress(fileModel.id, sent, totalBytes, speed, eta);
        }
        await socket.flush();

        // 5. Read result (with timeout)
        bool success = true;
        try {
          final resLen = await reader.readInt32()
              .timeout(const Duration(seconds: 15), onTimeout: () => null);
          if (resLen != null && resLen > 0) {
            final resBytes = await reader.readBytes(resLen);
            if (resBytes != null) {
              final result  = jsonDecode(utf8.decode(resBytes)) as Map<String, dynamic>;
              success       = result['success'] == true && result['checksumOk'] != false;
            }
          }
        } catch (_) { /* treat timeout as success */ }

        socket.destroy();
        reader.dispose();
        return success;
      } catch (e) {
        reader.dispose();
        socket.destroy();
        return false;
      }
    } catch (_) {
      socket?.destroy();
      return false;
    }
  }

  void cancelTransfer() => _cancelled = true;

  // ── Frame helper ───────────────────────────────────────────────────────────

  /// Writes [4-byte big-endian length][data] to socket.
  void _sendFrame(Socket socket, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length, Endian.big);
    socket.add(len.buffer.asUint8List());
    socket.add(data);
  }
}

// ── Sequential socket reader ───────────────────────────────────────────────────
/// Buffers incoming socket data so we can do sequential reads
/// (read N bytes, then read M bytes) without re-listening.
class _SocketReader {
  final Socket _socket;
  final _buf = <int>[];
  final _waiters = <_ReadWaiter>[];
  StreamSubscription? _sub;
  bool _done = false;

  _SocketReader(this._socket) {
    _sub = _socket.listen(
      (data) {
        _buf.addAll(data);
        _flush();
      },
      onError: (_) {
        _done = true;
        _failAll();
      },
      onDone: () {
        _done = true;
        _flush();
        _failAll();
      },
      cancelOnError: true,
    );
  }

  void _flush() {
    while (_waiters.isNotEmpty) {
      final w = _waiters.first;
      if (_buf.length >= w.need) {
        final data = Uint8List.fromList(_buf.sublist(0, w.need));
        _buf.removeRange(0, w.need);
        _waiters.removeAt(0);
        if (!w.completer.isCompleted) w.completer.complete(data);
      } else {
        break;
      }
    }
  }

  void _failAll() {
    for (final w in _waiters) {
      if (!w.completer.isCompleted) w.completer.complete(null);
    }
    _waiters.clear();
  }

  Future<Uint8List?> readBytes(int n) {
    if (n <= 0) return Future.value(Uint8List(0));
    if (_buf.length >= n) {
      final data = Uint8List.fromList(_buf.sublist(0, n));
      _buf.removeRange(0, n);
      return Future.value(data);
    }
    if (_done) return Future.value(null);
    final w = _ReadWaiter(n);
    _waiters.add(w);
    return w.completer.future;
  }

  Future<int?> readInt32() async {
    final data = await readBytes(4);
    if (data == null || data.length < 4) return null;
    return ByteData.sublistView(data).getUint32(0, Endian.big);
  }

  void dispose() {
    _sub?.cancel();
    _failAll();
  }
}

class _ReadWaiter {
  final int need;
  final completer = Completer<Uint8List?>();
  _ReadWaiter(this.need);
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../data/models/transfer_file_model.dart';
import '../../services/connection_service.dart'
    show ConnectionService, ShareConnectionState;
import '../../services/transfer_service.dart';
import '../widgets/transfer_progress_panel.dart';
import '../widgets/connection_badge.dart';

enum _ReceivePhase { permissions, waiting, receiving, done, failed }

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  final _conn     = ConnectionService();
  final _transfer = TransferService();

  _ReceivePhase _phase = _ReceivePhase.permissions;
  String _status       = '';
  final String _peerName     = 'Sender';
  int    _serverPort   = 8888;
  String _localIp      = '';

  final List<TransferFileModel> _received = [];
  StreamSubscription? _stateSub, _progressSub;
  late AnimationController _pulse;

  static const _kBg    = Color(0xFFF0F4FF);
  static const _kGreen = Color(0xFF00C17C);
  static const _kText  = Color(0xFF0D1B34);
  static const _kSub   = Color(0xFF8A96A8);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final granted = await _requestPermissions();
    if (!granted) { setState(() => _phase = _ReceivePhase.permissions); return; }

    await _conn.initialize();

    _progressSub = _transfer.progressStream.listen((file) {
      if (!mounted) return;
      setState(() {
        final idx = _received.indexWhere((f) => f.id == file.id);
        if (idx == -1) {
          _received.add(file);
        } else {
          _received[idx] = file;
        }
        _phase = _ReceivePhase.receiving;
      });
    });

    _stateSub = _conn.stateStream.listen((s) {
      if (!mounted) return;
      if (s == ShareConnectionState.connected) {
        setState(() { _status = 'Sender connected. Waiting for files...'; });
      }
    });

    // Start TCP server so sender can push files
    _serverPort = await _transfer.startReceiveServer(peerName: _peerName);

    // Start Wi-Fi Direct discovery so sender can find us
    await _conn.discoverDevices();

    // Get local IP for display
    final info = await _conn.getConnectionInfo();
    _localIp   = info['ipAddress'] as String? ?? '';

    setState(() {
      _phase  = _ReceivePhase.waiting;
      _status = 'Waiting for sender...';
    });
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      // iOS permissions are handled via Info.plist - always return true
      return true;
    }

    int sdk = 0;
    if (Platform.isAndroid) {
      sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    }
    final perms = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    if (sdk >= 33) {
      perms.add(Permission.nearbyWifiDevices);
    } else {
      perms.add(Permission.storage);
    }
    final results = await perms.request();
    return results.values.every((s) => s.isGranted || s.isLimited);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _progressSub?.cancel();
    _pulse.dispose();
    _transfer.stopReceiveServer();
    _conn.stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Receive Files',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [const Padding(
          padding: EdgeInsets.only(right: 12),
          child: ConnectionBadge(light: true),
        )],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _ReceivePhase.permissions: return _buildPermError();
      case _ReceivePhase.waiting:     return _buildWaiting();
      case _ReceivePhase.receiving:   return _buildReceiving();
      case _ReceivePhase.done:        return _buildDone();
      case _ReceivePhase.failed:      return _buildFailed();
    }
  }

  Widget _buildPermError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_rounded, color: Colors.orange, size: 56),
        const SizedBox(height: 16),
        const Text('Permissions needed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: _kText)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async { await openAppSettings(); _bootstrap(); },
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: const Text('Open Settings'),
        ),
      ]),
    ),
  );

  Widget _buildWaiting() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => Stack(alignment: Alignment.center, children: [
          ...List.generate(3, (i) => Opacity(
            opacity: (1 - _pulse.value) * (1 - i * 0.25),
            child: Transform.scale(
              scale: 0.5 + (i * 0.25) + _pulse.value * 0.5,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGreen.withValues(alpha: 0.08),
                ),
              ),
            ),
          )),
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                color: _kGreen, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_tethering_rounded,
                color: Colors.white, size: 38),
          ),
        ]),
      ),
      const SizedBox(height: 28),
      const Text('Ready to Receive',
          style: TextStyle(color: _kText, fontSize: 22,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(_status,
          style: const TextStyle(color: _kSub, fontSize: 13)),
      if (_localIp.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4EAF4)),
          ),
          child: Column(children: [
            const Text('Device IP', style: TextStyle(
                color: _kSub, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_localIp, style: const TextStyle(
                color: _kText, fontSize: 18, fontWeight: FontWeight.w800,
                letterSpacing: 1)),
            const SizedBox(height: 2),
            Text('Port: $_serverPort', style: const TextStyle(
                color: _kSub, fontSize: 12)),
          ]),
        ),
      ],
    ]),
  );

  Widget _buildReceiving() {
    return Column(children: [
      // Header info
      Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.download_rounded, color: _kGreen, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Receiving from $_peerName',
                style: const TextStyle(color: _kText,
                    fontSize: 14, fontWeight: FontWeight.w700)),
            Text('${_received.length} file(s)',
                style: const TextStyle(color: _kSub, fontSize: 12)),
          ]),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
          itemCount: _received.length,
          itemBuilder: (_, i) => TransferProgressPanel(file: _received[i]),
        ),
      ),
    ]);
  }

  Widget _buildDone() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_rounded, color: _kGreen, size: 72),
      const SizedBox(height: 16),
      const Text('Files Received!',
          style: TextStyle(color: _kText, fontSize: 22,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('${_received.length} file(s) saved to NagarikShare folder',
          style: const TextStyle(color: _kSub, fontSize: 13)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 14)),
        child: const Text('Done',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  Widget _buildFailed() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
      const SizedBox(height: 16),
      const Text('Transfer Failed',
          style: TextStyle(color: _kText, fontSize: 18,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _bootstrap,
        style: ElevatedButton.styleFrom(backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry'),
      ),
    ]),
  );
}

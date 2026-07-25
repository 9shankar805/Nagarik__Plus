import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/connection_service.dart';
import '../../services/transfer_service.dart';
import '../../data/models/transfer_file_model.dart';
import '../widgets/transfer_progress_panel.dart';
import 'connect_to_ios_screen.dart';

/// ConnectScreen — displays the device's QR code + hotspot credentials so a
/// nearby peer can scan and join.  Mirrors SHAREit's "receive" QR card layout.
/// On open, checks that WiFi/hotspot permissions are granted.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  String _deviceName   = 'user35254021784';
  bool   _ultraFastMode = false;

  // Hotspot/WiFi readiness
  bool   _checking  = true;
  bool   _wifiReady = false;
  bool   _hotspotActive = true;
  String _localIp   = '192.168.43.1';
  int    _serverPort = 8888;

  // Receiver state
  bool   _serverStarted = false;
  final  _transfer      = TransferService();
  final  _connService   = ConnectionService();
  StreamSubscription<dynamic>? _progressSub;
  final List<TransferFileModel> _receivedFiles = [];
  bool   _receiving = false;

  static const _kGreen = Color(0xFF2DC97E);
  static const _kBlue  = Color(0xFF2196F3);
  static const _kText  = Color(0xFF0D1B34);
  static const _kSub   = Color(0xFF8A96A8);

  @override
  void initState() {
    super.initState();
    _loadDeviceName();
    _checkWifiReady();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _transfer.stopReceiveServer();
    super.dispose();
  }

  Future<void> _loadDeviceName() async {
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty) setState(() => _deviceName = host);
    } catch (_) {}
  }

  /// Called after WiFi check passes — starts the server before QR is shown
  String _customSsid = '';
  String _customPassword = '';

  Future<void> _startReceiveServer() async {
    if (_serverStarted) return;
    _serverStarted = true;

    _progressSub = _transfer.progressStream.listen((file) {
      if (!mounted) return;
      setState(() {
        final idx = _receivedFiles.indexWhere((f) => f.id == file.id);
        if (idx == -1) {
          _receivedFiles.add(file);
        } else {
          _receivedFiles[idx] = file;
        }
        _receiving = true;
      });
    });

    final port = await _transfer.startReceiveServer(peerName: _deviceName);
    if (mounted) setState(() => _serverPort = port);
  }

  /// Called after WiFi check passes — starts hotspot + TCP server before QR is shown
  Future<void> _initReceiver() async {
    try {
      final info = await _connService.createHotspot();
      if (info['ssid'] != null && (info['ssid'] as String).isNotEmpty) {
        _customSsid = info['ssid'] as String;
        if (info['password'] != null) _customPassword = info['password'] as String;
        if (info['gatewayIp'] != null && (info['gatewayIp'] as String).isNotEmpty) {
          _localIp = info['gatewayIp'] as String;
        }
      }
    } catch (_) {}

    await _startReceiveServer();
    // Rebuild so QR encodes the real port and hotspot info
    if (mounted) setState(() {});
  }

  Future<void> _checkWifiReady() async {
    bool permGranted = false;
    String ip        = '192.168.43.1';

    if (Platform.isAndroid) {
      final sdk = await _sdkInt();
      permGranted = sdk >= 33
          ? await Permission.nearbyWifiDevices.isGranted
          : await Permission.locationWhenInUse.isGranted;

      try {
        final interfaces = await NetworkInterface.list(
            type: InternetAddressType.IPv4, includeLinkLocal: false);
        String? bestIp;
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (addr.isLoopback) continue;
            bestIp ??= addr.address;
            final name = iface.name.toLowerCase();
            if (name.contains('wlan') || name.contains('ap') || name.contains('wifi')) {
              bestIp = addr.address;
              break;
            }
          }
        }
        if (bestIp != null) ip = bestIp;
      } catch (_) {}
    } else {
      permGranted = true;
    }

    if (mounted) {
      setState(() {
        _wifiReady     = permGranted;
        _hotspotActive = true;
        _localIp       = ip;
        _checking      = false;
      });
      if (permGranted) _initReceiver();
    }
  }

  Future<int> _sdkInt() async {
    try {
      return (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    } catch (_) { return 0; }
  }

  Future<void> _requestWifiPermission() async {
    if (Platform.isAndroid) {
      final sdk = await _sdkInt();
      if (sdk >= 33) {
        await Permission.nearbyWifiDevices.request();
      } else {
        await Permission.locationWhenInUse.request();
      }
    }
    await _checkWifiReady();
  }

  String get _ssid => _customSsid;

  String get _password => _customPassword;

  String get _qrData => jsonEncode({
    'ssid':     _ssid,
    'password': _password,
    'ip':       _localIp,
    'port':     _serverPort,
  });

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F3F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_wifiReady) {
      return _buildPermissionScreen();
    }
    if (!_hotspotActive) {
      return _buildHotspotOffScreen();
    }
    return _buildMainScreen();
  }

  // ── Hotspot OFF screen — WiFi/hotspot not active ───────────────────────────
  Widget _buildHotspotOffScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        elevation: 0.5,
        leading: const BackButton(color: _kText),
        title: const Text('Connect',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_tethering_off_rounded,
                  color: Color(0xFFFF9800), size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Hotspot / WiFi not active',
                style: TextStyle(color: Color(0xFF212121),
                    fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
              'To receive files, your device needs to be the hotspot.\n\nPlease turn on your mobile hotspot (Personal Hotspot) so the sender can connect to you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            // Step guide
            _HowToStep(step: '1', text: 'Go to Settings → Hotspot & Tethering'),
            const SizedBox(height: 8),
            _HowToStep(step: '2', text: 'Turn on Mobile Hotspot / WiFi Hotspot'),
            const SizedBox(height: 8),
            _HowToStep(step: '3', text: 'Come back and tap Receive again'),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open Settings',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue, foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _checking = true);
                    await _checkWifiReady();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: const BorderSide(color: Color(0xFF2196F3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Permission screen — shown when WiFi/location not granted ─────────────────
  Widget _buildPermissionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        elevation: 0.5,
        leading: const BackButton(color: _kText),
        title: const Text('Connect', style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, color: Color(0xFF2196F3), size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hotspot permission required',
                style: TextStyle(
                  color: Color(0xFF212121), fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'To act as a receiver, this device needs to create a hotspot.\n\nPlease allow the nearby devices / location permission so the sender can find and connect to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _requestWifiPermission,
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: const Text('Allow Hotspot Permission',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings instead',
                    style: TextStyle(color: Color(0xFF757575))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main screen ───────────────────────────────────────────────────────────────
  Widget _buildMainScreen() {
    // Start receive server the first time main screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) => _startReceiveServer());

    // Show loading if server hasn't started yet or port is still unknown
    if (!_serverStarted || _serverPort == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F3F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _kText,
          elevation: 0.5,
          shadowColor: const Color(0x14000000),
          leading: const BackButton(color: _kText),
          title: const Text(
            'Connect',
            style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFF2196F3)),
            SizedBox(height: 16),
            Text('Starting receiver...', style: TextStyle(color: Color(0xFF757575))),
          ]),
        ),
      );
    }

    // If files are being received, show the receive progress view
    if (_receiving && _receivedFiles.isNotEmpty) {
      return _buildReceivingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        elevation: 0.5,
        shadowColor: const Color(0x14000000),
        leading: const BackButton(color: _kText),
        title: const Text(
          'Connect',
          style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_iphone, color: _kText),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConnectToiOSScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status — waiting for sender
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(width: 8),
                    Text('Waiting for sender • Port $_serverPort',
                        style: const TextStyle(
                            color: Color(0xFF388E3C), fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),

                const SizedBox(height: 12),

                // Subtitle — floats above card, no background
                const Text(
                  'Scan my QR code or tap my Wi-Fi hotspot to connect.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kSub, fontSize: 13),
                ),

                const SizedBox(height: 20),

                // ── White QR Card ───────────────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatar(),
                        const SizedBox(height: 8),
                        Text(_deviceName,
                            style: const TextStyle(color: _kSub, fontSize: 13)),
                        const SizedBox(height: 14),
                        _buildSsidRow(),
                        const SizedBox(height: 8),
                        _buildPasswordRow(),
                        const SizedBox(height: 12),
                        _buildQrCode(),
                        const SizedBox(height: 12),
                        _buildUltraFastRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Receiving screen — shown when files start arriving ───────────────────────
  Widget _buildReceivingScreen() {
    final done  = _receivedFiles.every((f) =>
        f.status == TransferStatus.completed || f.status == TransferStatus.failed);
    final count = _receivedFiles.where((f) => f.status == TransferStatus.completed).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        elevation: 0,
        title: Text(done ? 'Received!' : 'Receiving...',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: done,
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                    : _kBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 26)
                  : const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Color(0xFF2196F3))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(done ? 'Transfer complete' : 'Receiving files...',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                      color: Color(0xFF212121))),
              Text('$count / ${_receivedFiles.length} received',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
            ])),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _receivedFiles.length,
            itemBuilder: (_, i) => TransferProgressPanel(file: _receivedFiles[i]),
          ),
        ),
      ]),
      bottomNavigationBar: done
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: _kGreen,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco, color: Colors.white, size: 34),
    );
  }

  Widget _buildSsidRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi, color: Color(0xFF1677FF), size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _ssid,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _kText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.key, color: _kSub, size: 14),
        const SizedBox(width: 6),
        Text(
          _password,
          style: const TextStyle(
            fontSize: 12,
            color: _kSub,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode() {
    return SizedBox(
      width: 220,
      height: 220,
      child: QrImageView(
        data: _qrData,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: _kText,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: _kText,
        ),
      ),
    );
  }

  Widget _buildUltraFastRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: _kGreen, size: 20),
          const SizedBox(width: 6),
          const Text(
            'Ultra Fast Mode',
            style: TextStyle(
              color: _kText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.help_outline, color: _kSub, size: 16),
          const Spacer(),
          Switch(
            value: _ultraFastMode,
            onChanged: (v) => setState(() => _ultraFastMode = v),
            activeThumbColor: _kGreen,
          ),
        ],
      ),
    );
  }
}

// ── Small helper widget for the hotspot guide ─────────────────────────────────
class _HowToStep extends StatelessWidget {
  final String step;
  final String text;
  const _HowToStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF2196F3), shape: BoxShape.circle),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFF212121), fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }
}

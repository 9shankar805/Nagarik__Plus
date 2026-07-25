import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/device_model.dart';
import '../../data/models/transfer_file_model.dart';
import '../../services/connection_service.dart'
    show ConnectionService, ShareConnectionState;
import '../../services/transfer_service.dart';
import '../widgets/device_tile.dart';
import '../widgets/file_queue_tile.dart';
import '../widgets/transfer_progress_panel.dart';
import 'file_picker_screen.dart';

enum _Phase {
  permissions,
  selectFiles,
  searching,       // Wi-Fi Direct peer discovery
  hotspot,         // Wi-Fi Direct unavailable → showing hotspot SSID+password
  connectingDirect,// Connecting via Wi-Fi Direct
  connectingHotspot,// Receiver joined hotspot, connecting
  transferring,
  done,
  failed,
}

class SendScreen extends StatefulWidget {
  final String? initialCategory;
  const SendScreen({super.key, this.initialCategory});
  @override State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen>
    with SingleTickerProviderStateMixin {
  final _conn     = ConnectionService();
  final _transfer = TransferService();

  _Phase _phase  = _Phase.permissions;
  String _status = '';

  // Hotspot credentials shown to user
  String _hotspotSsid     = '';
  String _hotspotPassword = '';
  String _hotspotIp       = '';

  List<DeviceModel>       _devices = [];
  List<TransferFileModel> _queue   = [];

  StreamSubscription? _stateSub, _deviceSub, _progressSub, _eventSub;
  late AnimationController _radar;

  static const _kBg    = Color(0xFFF0F4FF);
  static const _kBlue  = Color(0xFF3461FF);
  static const _kGreen = Color(0xFF00C17C);
  static const _kText  = Color(0xFF0D1B34);
  static const _kSub   = Color(0xFF8A96A8);
  static const _kBord  = Color(0xFFE4EAF4);

  @override
  void initState() {
    super.initState();
    _radar = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final granted = await _requestPermissions();
    if (!granted) { setState(() => _phase = _Phase.permissions); return; }
    await _conn.initialize();

    // Listen to connection state changes
    _stateSub = _conn.stateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        if (s == ShareConnectionState.searching) {
          _phase = _Phase.searching;
          _status = Platform.isIOS 
              ? 'Scanning for nearby devices via Multipeer...' 
              : 'Scanning for nearby devices via Wi-Fi Direct...';
        } else if (s == ShareConnectionState.connecting) {
          _phase = _Phase.connectingDirect;
          _status = 'Connecting...';
        } else if (s == ShareConnectionState.connected) {
          _status = 'Connected! Starting transfer...';
          _startSending();
        } else if (s == ShareConnectionState.failed) {
          _phase = _Phase.failed;
          _status = 'Connection failed. Try again.';
        } else if (s == ShareConnectionState.wifiDirectUnavailable) {
          // iOS doesn't have Wi-Fi Direct - use MultipeerConnectivity directly
          if (Platform.isIOS) {
            _phase = _Phase.searching;
            _status = 'Scanning via MultipeerConnectivity...';
          } else {
            // Android: Automatically fall back to hotspot
            _triggerHotspot();
          }
        } else if (s == ShareConnectionState.hotspotActive) {
          // Hotspot is up — devices can join now; UDP discovery will find them
          _conn.discoverDevices(); // restart discovery over LAN/UDP
        }
      });
    });

    // Listen for discovered devices
    _deviceSub = _conn.devicesStream.listen((devs) {
      if (!mounted) return;
      setState(() => _devices = devs);
      // If in hotspot phase and a device appeared, offer connection
      if (_phase == _Phase.hotspot && devs.isNotEmpty) {
        setState(() {
          _phase = _Phase.connectingHotspot;
          _status = 'Device found via hotspot. Connecting...';
        });
        _conn.connectDevice(devs.first.id);
      }
    });

    // Listen to raw events for hotspot credentials
    _eventSub = _conn.eventStream.listen((event) {
      if (!mounted) return;
      final type = event['type'] as String?;
      if (type == 'hotspotCreated') {
        setState(() {
          _hotspotSsid     = event['ssid']      as String? ?? '';
          _hotspotPassword = event['password']  as String? ?? '';
          _hotspotIp       = event['gatewayIp'] as String? ?? '';
          _phase           = _Phase.hotspot;
          _status          = 'Hotspot active — share credentials with receiver';
        });
      }
    });

    // Transfer progress
    _progressSub = _transfer.progressStream.listen((file) {
      if (!mounted) return;
      final idx = _queue.indexWhere((f) => f.id == file.id);
      if (idx != -1) setState(() => _queue[idx] = file);
      if (_queue.isNotEmpty &&
          _queue.every((f) =>
              f.status == TransferStatus.completed ||
              f.status == TransferStatus.failed)) {
        if (mounted) setState(() { _phase = _Phase.done; _status = 'All files sent!'; });
      }
    });

    setState(() => _phase = _Phase.selectFiles);
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          _openPicker(category: widget.initialCategory));
    }
  }

  Future<bool> _requestPermissions() async {
    int sdk = 0;
    if (Platform.isAndroid) sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    final perms = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
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

  Future<void> _openPicker({String? category}) async {
    final result = await Navigator.push<List<String>>(context,
        MaterialPageRoute(builder: (_) => FilePickerScreen(category: category)));
    if (result == null || result.isEmpty) return;
    _transfer.addFiles(result);
    setState(() => _queue = _transfer.queue.toList());
  }

  Future<void> _startSearch() async {
    await _conn.discoverDevices();
  }

  /// Wi-Fi Direct failed/unavailable → create hotspot automatically
  Future<void> _triggerHotspot() async {
    setState(() {
      _phase  = _Phase.hotspot;
      _status = 'Creating hotspot...';
    });
    try {
      final info = await _conn.createHotspot();
      if (mounted) {
        setState(() {
          _hotspotSsid     = info['ssid']      as String? ?? '';
          _hotspotPassword = info['password']  as String? ?? '';
          _hotspotIp       = info['gatewayIp'] as String? ?? '';
          _phase           = _Phase.hotspot;
          _status          = 'Hotspot active — share credentials with receiver';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _phase = _Phase.failed; _status = 'Hotspot failed: $e'; });
    }
  }

  Future<void> _connectTo(DeviceModel device) async {
    await _conn.stopDiscovery();
    await _conn.connectDevice(device.id);
  }

  Future<void> _startSending() async {
    if (_queue.isEmpty) return;
    setState(() => _phase = _Phase.transferring);
    final info = await _conn.getConnectionInfo();
    final ip   = info['ipAddress'] as String? ?? _conn.connectedIp ?? '';
    final port = info['port']      as int?    ?? _conn.serverPort;
    await _transfer.sendAll(
      receiverIp: ip,
      port:       port,
      peerName:   _devices.isNotEmpty ? _devices.first.name : 'Receiver',
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _deviceSub?.cancel();
    _progressSub?.cancel();
    _eventSub?.cancel();
    _radar.dispose();
    _conn.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_appBarTitle(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_phase != _Phase.done && _phase != _Phase.transferring)
            TextButton(
              onPressed: () { _transfer.clearQueue(); Navigator.pop(context); },
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottom(),
    );
  }

  String _appBarTitle() {
    switch (_phase) {
      case _Phase.hotspot: return 'Hotspot Active';
      case _Phase.transferring: return 'Sending Files';
      case _Phase.done: return 'Done';
      default: return 'Send Files';
    }
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.permissions:       return _buildPermError();
      case _Phase.selectFiles:       return _buildSelectFiles();
      case _Phase.searching:         return _buildSearching();
      case _Phase.hotspot:           return _buildHotspot();
      case _Phase.connectingDirect:  return _buildConnecting('Connecting via Wi-Fi Direct...');
      case _Phase.connectingHotspot: return _buildConnecting('Device found. Connecting...');
      case _Phase.transferring:      return _buildTransferring();
      case _Phase.done:              return _buildDone(success: true);
      case _Phase.failed:            return _buildDone(success: false);
    }
  }

  // ── Permission error ────────────────────────────────────────────────────────
  Widget _buildPermError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_rounded, color: Colors.orange, size: 56),
        const SizedBox(height: 16),
        const Text('Permissions needed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 8),
        const Text('Wi-Fi, Bluetooth and Location are required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kSub, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async { await openAppSettings(); _bootstrap(); },
          style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Open Settings'),
        ),
      ]),
    ),
  );

  // ── File selection ──────────────────────────────────────────────────────────
  Widget _buildSelectFiles() {
    return Column(children: [
      Container(
        height: 68, color: Colors.white,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            _chip('Photos',    Icons.image_rounded,       const Color(0xFF4E8FFF)),
            _chip('Videos',    Icons.videocam_rounded,    const Color(0xFFFF4E6A)),
            _chip('Music',     Icons.music_note_rounded,  const Color(0xFF9B6BFF)),
            _chip('Apps',      Icons.android_rounded,     const Color(0xFF2DC97E)),
            _chip('Documents', Icons.description_rounded, const Color(0xFFFF9B2F)),
            _chip('Contacts',  Icons.contacts_rounded,    const Color(0xFF3BBFFF)),
            _chip('All Files', Icons.folder_open_rounded, const Color(0xFF455A64)),
          ],
        ),
      ),
      Expanded(
        child: _queue.isEmpty ? _buildEmptyQueue() :
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
              itemCount: _queue.length,
              itemBuilder: (_, i) => FileQueueTile(
                file: _queue[i],
                onRemove: () {
                  _transfer.removeFile(_queue[i].id);
                  setState(() => _queue = _transfer.queue.toList());
                },
              ),
            ),
      ),
    ]);
  }

  Widget _chip(String label, IconData icon, Color color) => GestureDetector(
    onTap: () => _openPicker(category: label),
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _buildEmptyQueue() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF3461FF), Color(0xFF5B8BFF)]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
      ),
      const SizedBox(height: 16),
      const Text('Pick files to share',
          style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Tap a category above to add files',
          style: TextStyle(color: _kSub, fontSize: 13)),
    ]),
  );

  // ── Wi-Fi Direct scanning radar ─────────────────────────────────────────────
  Widget _buildSearching() {
    return Column(children: [
      Expanded(child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _radar,
            builder: (_, _) => Stack(alignment: Alignment.center, children: [
              ...List.generate(3, (i) => Transform.scale(
                scale: 0.4 + (i * 0.3) + _radar.value * 0.3,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _kBlue.withValues(alpha: (0.3 - i * 0.08).clamp(0.0, 1.0)),
                        width: 1.5),
                  ),
                ),
              )),
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                child: const Icon(Icons.radar_rounded, color: Colors.white, size: 34),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Text(_status,
              style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Make sure receiver is on Receive screen',
              style: TextStyle(color: _kSub, fontSize: 12)),
          const SizedBox(height: 20),
          // Hotspot fallback button — always visible while searching
          TextButton.icon(
            onPressed: _triggerHotspot,
            icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
            label: const Text('Use Hotspot Instead'),
            style: TextButton.styleFrom(foregroundColor: _kBlue),
          ),
        ]),
      )),
      if (_devices.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            const Text('Nearby Devices',
                style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_devices.length} found',
                style: const TextStyle(color: _kSub, fontSize: 12)),
          ]),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _devices.length,
            itemBuilder: (_, i) => DeviceTile(
              device: _devices[i],
              onTap: () => _connectTo(_devices[i]),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
    ]);
  }

  // ── Hotspot screen: QR code + SSID + password as plain text ──────────────────
  Widget _buildHotspot() {
    final isEmpty = _hotspotSsid.isEmpty;
    // Standard Android Wi-Fi QR format — scannable by Android camera or any QR reader
    final wifiQrData = isEmpty
        ? ''
        : 'WIFI:T:WPA;S:$_hotspotSsid;P:$_hotspotPassword;;';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Hotspot Active',
              style: TextStyle(color: _kText, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Receiver scans QR code to connect automatically,\nor enters the credentials manually.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSub, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),

          // ── QR Code ─────────────────────────────────────────────────────────
          if (isEmpty)
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBord),
              ),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBord),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16, offset: const Offset(0, 4),
                )],
              ),
              child: Column(children: [
                // The actual QR widget
                QrImageView(
                  data: wifiQrData,
                  version: QrVersions.auto,
                  size: 180,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0D1B34),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0D1B34),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.qr_code_scanner_rounded, color: _kGreen, size: 14),
                    SizedBox(width: 6),
                    Text('Scan with receiver camera',
                        style: TextStyle(color: _kGreen,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),

          const SizedBox(height: 24),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or enter manually',
                  style: TextStyle(color: _kSub, fontSize: 12)),
            ),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 20),

          // ── Text credentials ─────────────────────────────────────────────────
          _credCard(
            label: 'Network Name (SSID)',
            value: isEmpty ? 'Creating hotspot...' : _hotspotSsid,
            icon: Icons.wifi_rounded,
            color: _kBlue,
            canCopy: !isEmpty,
          ),
          const SizedBox(height: 12),
          _credCard(
            label: 'Password',
            value: isEmpty ? '—' : (_hotspotPassword.isEmpty ? 'No password' : _hotspotPassword),
            icon: Icons.lock_rounded,
            color: const Color(0xFF9B6BFF),
            canCopy: !isEmpty && _hotspotPassword.isNotEmpty,
          ),
          if (_hotspotIp.isNotEmpty) ...[
            const SizedBox(height: 12),
            _credCard(
              label: 'IP Address',
              value: _hotspotIp,
              icon: Icons.router_rounded,
              color: const Color(0xFFFF9B2F),
              canCopy: true,
            ),
          ],

          const SizedBox(height: 28),

          // ── Status ──────────────────────────────────────────────────────────
          if (_devices.isEmpty) ...[
            const CircularProgressIndicator(strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_kGreen)),
            const SizedBox(height: 12),
            const Text('Waiting for receiver to connect...',
                style: TextStyle(color: _kSub, fontSize: 13)),
          ] else ...[
            const Icon(Icons.check_circle_rounded, color: _kGreen, size: 28),
            const SizedBox(height: 8),
            Text('${_devices.first.name} connected!',
                style: const TextStyle(color: _kGreen,
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ],

          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _conn.disconnect();
              setState(() { _phase = _Phase.selectFiles; _status = ''; });
            },
            child: const Text('Cancel Hotspot',
                style: TextStyle(color: Colors.red)),
          ),
        ]),
      ),
    );
  }

  Widget _credCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool canCopy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: _kSub, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
              color: _kText, fontSize: 18, fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
        ])),
        if (canCopy)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied'),
                    duration: const Duration(seconds: 1)),
              );
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.copy_rounded, color: color, size: 18),
            ),
          ),
      ]),
    );
  }

  // ── Connecting spinner ──────────────────────────────────────────────────────
  Widget _buildConnecting(String msg) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: _kBlue),
      const SizedBox(height: 20),
      Text(msg, style: const TextStyle(
          color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── Transfer progress list ──────────────────────────────────────────────────
  Widget _buildTransferring() => Column(children: [
    Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
        itemCount: _queue.length,
        itemBuilder: (_, i) => TransferProgressPanel(file: _queue[i]),
      ),
    ),
  ]);

  // ── Done / Failed ───────────────────────────────────────────────────────────
  Widget _buildDone({required bool success}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: (success ? const Color(0xFF10B981) : Colors.red).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: success ? const Color(0xFF10B981) : Colors.red,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(success ? 'Transfer Complete!' : 'Transfer Failed',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 8),
        Text(_status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSub, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () { _transfer.clearQueue(); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        if (!success) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() { _phase = _Phase.selectFiles; _status = ''; }),
            child: const Text('Try Again'),
          ),
        ],
      ]),
    ),
  );

  // ── Bottom bar (file count + find receiver button) ──────────────────────────
  Widget? _buildBottom() {
    if (_phase == _Phase.selectFiles && _queue.isNotEmpty) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
                color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text('${_queue.length}',
                  style: const TextStyle(
                      color: _kBlue, fontSize: 16, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('files selected',
                style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600))),
            GestureDetector(
              onTap: _startSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3461FF), Color(0xFF5B8BFF)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Find Receiver',
                    style: TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      );
    }
    return null;
  }
}

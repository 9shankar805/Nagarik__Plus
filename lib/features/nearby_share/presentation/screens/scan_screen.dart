import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/connection_service.dart';
import '../../services/transfer_service.dart';
import '../widgets/device_tile.dart';
import '../widgets/transfer_progress_panel.dart';
import '../../data/models/transfer_file_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late final AnimationController _lineController;

  bool _cameraGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _checkCameraPermission();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      await ConnectionService().initialize();
      await ConnectionService().discoverDevices();
    } catch (_) {}
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraGranted = status.isGranted;
      _permissionChecked = true;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _cameraGranted = true);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ip       = data['ip']       as String?;
      final ssid     = data['ssid']     as String? ?? '';
      final password = data['password'] as String? ?? '';
      final port     = data['port']     as int?    ?? 8888;

      if (ip == null || ip.isEmpty) return;

      _scannerController.stop();

      // Show connection info dialog before connecting
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _ConnectInfoDialog(
            receiverIp:   ip,
            ssid:         ssid,
            password:     password,
            port:         port,
            onConnect: () async {
              Navigator.pop(context); // close dialog
              // Show connecting overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Connecting to receiver...',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              if (ssid.isNotEmpty) {
                await ConnectionService().connectToWifi(ssid: ssid, password: password);
              }
              await ConnectionService().connectDevice(ip);
              if (!mounted) return;
              Navigator.pop(context); // close connecting overlay
              // Navigate to transfer progress screen — replaces scan screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => _TransferSendScreen(
                    receiverIp: ip,
                    port:       port,
                    peerName:   ssid.isNotEmpty ? ssid : ip,
                  ),
                ),
              );
            },
            onCancel: () {
              Navigator.pop(context); // close dialog
              _scannerController.start(); // restart scanner
            },
          ),
        );
      }
    } catch (_) {
      // Not a valid JSON QR — ignore
    }
  }

  @override
  void dispose() {
    ConnectionService().stopDiscovery();
    _scannerController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  // ── Shared AppBar ──────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      title: const Text(
        'Scan',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.phone_iphone, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  // ── No-permission state ────────────────────────────────────────────────────

  Widget _buildNoCameraPermission() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phone silhouette with scan-frame icon inside
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Icon(
                      Icons.smartphone,
                      size: 120,
                      color: Color(0x40FFFFFF), // white24
                    ),
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: Color(0x61FFFFFF), // white38
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'camera permission needs to be given to use the scan code function.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _requestCameraPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4D9B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OPEN NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scanner + bottom sheet ─────────────────────────────────────────────────

  Widget _buildScanner() {
    const double frameSize = 260;
    const double bottomSheetHeight = 180;
    const double hintAreaHeight = 36; // hint text + spacing above sheet

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Camera viewfinder — fills the area above the bottom sheet ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomSheetHeight + hintAreaHeight,
            child: Stack(
              children: [
                // Live camera feed
                Positioned.fill(
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onQrDetected,
                  ),
                ),
                // Dark overlay OUTSIDE the QR frame
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OutsideFrameDimmer(frameSize: frameSize),
                  ),
                ),
                // QR corner-bracket frame
                Positioned.fill(
                  child: CustomPaint(
                    painter: _QrFramePainter(frameSize: frameSize),
                  ),
                ),
                // Animated scan line (clipped inside the frame)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _lineController,
                    builder: (_, _) {
                      return CustomPaint(
                        painter: _ScanLinePainter(
                          progress: _lineController.value,
                          frameSize: frameSize,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Hint text ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomSheetHeight + 10,
            child: const Text(
              'Align QR code within frame to connect',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),

          // ── Bottom white sheet ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: bottomSheetHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Searching for receivers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<dynamic>>(
                        stream: ConnectionService().devicesStream,
                        builder: (context, snapshot) {
                          final devices = snapshot.data ?? [];
                          if (devices.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              return DeviceTile(
                                device: device,
                                onTap: () {
                                  ConnectionService()
                                      .connectDevice(device.id);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return _cameraGranted ? _buildScanner() : _buildNoCameraPermission();
  }
}

// ── Outside-frame dimmer ───────────────────────────────────────────────────────
// Paints a semi-transparent dark overlay covering the area OUTSIDE the QR frame.

class _OutsideFrameDimmer extends CustomPainter {
  final double frameSize;

  const _OutsideFrameDimmer({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = frameSize / 2;

    final left = cx - half;
    final top = cy - half;
    final right = cx + half;
    final bottom = cy + half;

    // Top strip
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    // Bottom strip
    canvas.drawRect(
        Rect.fromLTWH(0, bottom, size.width, size.height - bottom), paint);
    // Left strip (between top & bottom strips)
    canvas.drawRect(Rect.fromLTWH(0, top, left, frameSize), paint);
    // Right strip (between top & bottom strips)
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, frameSize),
        paint);
  }

  @override
  bool shouldRepaint(covariant _OutsideFrameDimmer old) =>
      old.frameSize != frameSize;
}

// ── Corner-bracket QR frame painter ───────────────────────────────────────────

class _QrFramePainter extends CustomPainter {
  final double frameSize;
  static const double _cornerLength = 28;
  static const Color _cornerColor = Color(0xFF1677FF);

  const _QrFramePainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _cornerColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = frameSize / 2;

    final left = cx - half;
    final top = cy - half;
    final right = cx + half;
    final bottom = cy + half;
    const cl = _cornerLength;

    // Top-left
    canvas.drawLine(Offset(left, top + cl), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cl, top), paint);

    // Top-right
    canvas.drawLine(Offset(right - cl, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cl), paint);

    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cl), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cl, bottom), paint);

    // Bottom-right
    canvas.drawLine(Offset(right - cl, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cl), paint);
  }

  @override
  bool shouldRepaint(covariant _QrFramePainter old) =>
      old.frameSize != frameSize;
}

// ── Animated scan-line painter ─────────────────────────────────────────────────

class _ScanLinePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final double frameSize;

  const _ScanLinePainter({required this.progress, required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = frameSize / 2;

    final frameTop = cy - half;
    final frameLeft = cx - half;
    final frameRight = cx + half;

    // Solid blue line that travels from frameTop to frameBottom
    final y = frameTop + frameSize * progress;

    final paint = Paint()
      ..color = const Color(0xFF1677FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(frameLeft, y), Offset(frameRight, y), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.progress != progress || old.frameSize != frameSize;
}

// ── Connection info dialog — shown after QR scan ──────────────────────────────
// Tells the sender which hotspot to join and confirms before connecting.

class _ConnectInfoDialog extends StatelessWidget {
  final String receiverIp;
  final String ssid;
  final String password;
  final int port;
  final VoidCallback onConnect;
  final VoidCallback onCancel;

  const _ConnectInfoDialog({
    required this.receiverIp,
    required this.ssid,
    required this.password,
    required this.port,
    required this.onConnect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi, color: Color(0xFF2196F3), size: 32),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Connect to Receiver',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Role explanation
            Text(
              'This device (Sender) will join the receiver\'s hotspot to transfer files.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Info rows
            if (ssid.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.wifi_rounded,
                iconColor: const Color(0xFF2196F3),
                label: 'Hotspot (Receiver)',
                value: ssid,
              ),
              const SizedBox(height: 10),
            ],
            if (password.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.lock_rounded,
                      iconColor: const Color(0xFF757575),
                      label: 'Password',
                      value: password,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            _InfoRow(
              icon: Icons.router_rounded,
              iconColor: const Color(0xFFFF9800),
              label: 'Receiver IP',
              value: receiverIp,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.cable_rounded,
              iconColor: const Color(0xFF9C27B0),
              label: 'Port',
              value: '$port',
            ),

            const SizedBox(height: 24),

            // Role info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF2196F3), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Color(0xFF757575), height: 1.4),
                    children: [
                      TextSpan(text: 'YOUR PHONE → Sender\n',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF212121))),
                      TextSpan(text: 'OTHER PHONE → Receiver (creates hotspot)',),
                    ],
                  )),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF757575),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(
            fontSize: 13, color: Color(0xFF212121), fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }
}

// ── Transfer Send Screen ───────────────────────────────────────────────────────
// Shown after QR scan + connect. Starts sending files and shows live progress.

class _TransferSendScreen extends StatefulWidget {
  final String receiverIp;
  final int    port;
  final String peerName;

  const _TransferSendScreen({
    required this.receiverIp,
    required this.port,
    required this.peerName,
  });

  @override
  State<_TransferSendScreen> createState() => _TransferSendScreenState();
}

class _TransferSendScreenState extends State<_TransferSendScreen> {
  final _transfer = TransferService();

  List<TransferFileModel> _files = [];
  bool _started = false;
  bool _allDone = false;

  static const _kBlue  = Color(0xFF2196F3);
  static const _kGreen = Color(0xFF4CAF50);
  static const _kText  = Color(0xFF212121);

  @override
  void initState() {
    super.initState();
    _files = _transfer.queue.toList();
    _startSending();
  }

  Future<void> _startSending() async {
    if (_started) return;
    _started = true;

    // Listen to progress updates
    _transfer.progressStream.listen((file) {
      if (!mounted) return;
      final idx = _files.indexWhere((f) => f.id == file.id);
      if (idx != -1) {
        setState(() => _files[idx] = file);
      }
      // Check if all done
      final done = _files.every((f) =>
          f.status == TransferStatus.completed ||
          f.status == TransferStatus.failed);
      if (done && !_allDone) {
        setState(() => _allDone = true);
      }
    });

    await _transfer.sendAll(
      receiverIp: widget.receiverIp,
      port:       widget.port,
      peerName:   widget.peerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentCount   = _files.where((f) => f.status == TransferStatus.completed).length;
    final failedCount = _files.where((f) => f.status == TransferStatus.failed).length;

    return PopScope(
      canPop: _allDone,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_allDone) {
          final nav = Navigator.of(context);
          final cancel = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Cancel Transfer?'),
              content: const Text('Files are still transferring. Cancel?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continue')),
                TextButton(onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cancel', style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (cancel == true && mounted) {
            _transfer.cancelAll();
            nav.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _kText,
          elevation: 0,
          title: Text(_allDone ? 'Transfer Complete' : 'Sending Files...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          automaticallyImplyLeading: _allDone,
        ),
        body: Column(children: [
          // Header status bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _allDone
                      ? _kGreen.withValues(alpha: 0.1)
                      : _kBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _allDone
                    ? const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 26)
                    : const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Color(0xFF2196F3))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_allDone ? 'Done!' : 'Sending to ${widget.peerName}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                        color: Color(0xFF212121))),
                Text('$sentCount / ${_files.length} sent'
                    '${failedCount > 0 ? ', $failedCount failed' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
              ])),
            ]),
          ),

          // File list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _files.length,
              itemBuilder: (_, i) => TransferProgressPanel(file: _files[i]),
            ),
          ),
        ]),

        // Done button
        bottomNavigationBar: _allDone
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        _transfer.clearQueue();
                        // Pop back to home — remove all routes until ShareHomeScreen
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst || r.settings.name == '/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue, foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final cancel = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Cancel Transfer?'),
                            content: const Text('Stop all transfers?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Continue')),
                              TextButton(onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (cancel == true && mounted) {
                          _transfer.cancelAll();
                          nav.popUntil((r) => r.isFirst || r.settings.name == '/');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel Transfer',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

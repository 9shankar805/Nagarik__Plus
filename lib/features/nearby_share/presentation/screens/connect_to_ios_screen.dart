import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ConnectToiOSScreen extends StatefulWidget {
  const ConnectToiOSScreen({super.key});

  @override
  State<ConnectToiOSScreen> createState() => _ConnectToiOSScreenState();
}

class _ConnectToiOSScreenState extends State<ConnectToiOSScreen> {
  String _deviceName = 'user35254021784';
  bool _checking = true;
  bool _wifiReady = false;
  String _localIp = '192.168.43.1';

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

  Future<void> _loadDeviceName() async {
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty) setState(() => _deviceName = host);
    } catch (_) {}
  }

  Future<int> _sdkInt() async {
    try { return (await DeviceInfoPlugin().androidInfo).version.sdkInt; }
    catch (_) { return 0; }
  }

  Future<void> _checkWifiReady() async {
    bool ready = false;
    String ip   = '192.168.43.1';
    if (Platform.isAndroid) {
      final sdk = await _sdkInt();
      final granted = sdk >= 33
          ? await Permission.nearbyWifiDevices.isGranted
          : await Permission.locationWhenInUse.isGranted;
      if (granted) {
        try {
          final ifaces = await NetworkInterface.list(
              type: InternetAddressType.IPv4, includeLinkLocal: false);
          String? bestIp;
          for (final iface in ifaces) {
            for (final addr in iface.addresses) {
              if (addr.isLoopback) continue;
              bestIp ??= addr.address;
              final n = iface.name.toLowerCase();
              if (n.contains('wlan') || n.contains('ap') || n.contains('wifi')) {
                bestIp = addr.address;
              }
            }
          }
          if (bestIp != null) ip = bestIp;
        } catch (_) {}
        ready = true;
      }
    } else {
      ready = true;
    }
    if (mounted) setState(() { _wifiReady = ready; _localIp = ip; _checking = false; });
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

  String get _ssid => 'NagarikShare_$_deviceName';
  String get _password => 'nagarik${_deviceName.hashCode.abs() % 9000 + 1000}';

  String get _qrData => jsonEncode({
    'ssid':     _ssid,
    'password': _password,
    'ip':       _localIp,
    'port':     45678,
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
      return Scaffold(
        backgroundColor: const Color(0xFFF2F3F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _kText,
          elevation: 0.5,
          leading: const BackButton(color: _kText),
          title: const Text('Connect to iOS',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [IconButton(icon: const Icon(Icons.help_outline, color: _kText), onPressed: () {})],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, color: Color(0xFF2196F3), size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Hotspot permission required',
                  style: TextStyle(color: Color(0xFF212121), fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text(
                'Please allow the nearby devices / location permission so the iOS device can find and connect to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: _requestWifiPermission,
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: const Text('Allow Hotspot Permission',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings instead',
                    style: TextStyle(color: Color(0xFF757575))),
              ),
            ]),
          ),
        ),
      );
    }
    // WiFi ready — show the main QR screen
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        elevation: 0.5,
        shadowColor: const Color(0x14000000),
        leading: const BackButton(color: _kText),
        title: const Text(
          'Connect to iOS',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: _kText),
            onPressed: () {
              // TODO: show iOS connection help dialog
            },
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
                // Subtitle — floats above card, no background
                const Text(
                  'Use NagarikShare for iOS to scan the QR code to connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kSub,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Card with blue arc decoration behind avatar top ──────
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Decorative light-blue semicircle arc — sits behind card top
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 160,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD6EAF8),
                          borderRadius: BorderRadius.all(Radius.circular(80)),
                        ),
                      ),
                    ),

                    // White QR Card
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
                            // Circular avatar — green circle with white leaf icon
                            _buildAvatar(),

                            const SizedBox(height: 8),

                            // Username
                            Text(
                              _deviceName,
                              style: const TextStyle(
                                color: _kSub,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // SSID row
                            _buildSsidRow(),

                            const SizedBox(height: 8),

                            // Password row
                            _buildPasswordRow(),

                            const SizedBox(height: 12),

                            // QR code
                            _buildQrCode(),

                            // No Ultra Fast Mode row for iOS
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
}

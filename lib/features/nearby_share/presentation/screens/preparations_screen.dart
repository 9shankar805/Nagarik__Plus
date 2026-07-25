import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'select_files_screen.dart';

/// PreparationsScreen — permission checklist shown before Send / Receive flows.
/// Auto-skips to SelectFilesScreen if both permissions are already granted.
class PreparationsScreen extends StatefulWidget {
  const PreparationsScreen({super.key});

  @override
  State<PreparationsScreen> createState() => _PreparationsScreenState();
}

class _PreparationsScreenState extends State<PreparationsScreen> {
  bool _nearbyGranted = false;
  bool _notificationGranted = false;
  bool _checked = false; // true once both checks complete

  static const _kBlue       = Color(0xFF1677FF);
  static const _kBg         = Color(0xFFF2F3F5);
  static const _kDark       = Color(0xFF212121);
  static const _kGrey       = Color(0xFF9E9E9E);
  static const _kCardBg     = Color(0xFFFFFFFF);
  static const _kIllustBg   = Color(0xFFEEF4FB);
  static const _kDivider    = Color(0xFFF0F0F0);
  static const _kYellow     = Color(0xFFFFCC02);
  static const _kOrange     = Color(0xFFFF6D00);
  static const _kGreen      = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    await Future.wait([
      _checkNearbyPermission(),
      _checkNotificationPermission(),
    ]);
    if (!mounted) return;
    setState(() => _checked = true);
    // Auto-skip if both are already granted
    if (_nearbyGranted && _notificationGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectFilesScreen(initialTab: 0)),
      );
    }
  }

  Future<void> _checkNearbyPermission() async {
    final bool granted;
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      if (sdk >= 33) {
        granted = await Permission.nearbyWifiDevices.isGranted;
      } else {
        granted = await Permission.locationWhenInUse.isGranted;
      }
    } else {
      granted = await Permission.locationWhenInUse.isGranted;
    }
    _nearbyGranted = granted;
  }

  Future<int> _androidSdk() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _requestNearbyPermission() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      status = sdk >= 33
          ? await Permission.nearbyWifiDevices.request()
          : await Permission.locationWhenInUse.request();
    } else {
      status = await Permission.locationWhenInUse.request();
    }
    if (!mounted) return;
    setState(() => _nearbyGranted = status.isGranted);
    _tryAutoNavigate();
  }

  Future<void> _checkNotificationPermission() async {
    bool granted = true;
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      if (sdk >= 33) {
        granted = await Permission.notification.isGranted;
      }
    }
    _notificationGranted = granted;
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      if (sdk >= 33) {
        final status = await Permission.notification.request();
        if (!mounted) return;
        setState(() => _notificationGranted = status.isGranted);
        _tryAutoNavigate();
        return;
      }
    }
    // Android < 13: notifications always on — mark as granted and auto-navigate
    if (mounted) {
      setState(() => _notificationGranted = true);
      _tryAutoNavigate();
    }
  }

  /// Navigate to SelectFilesScreen if both permissions are now granted.
  void _tryAutoNavigate() {
    if (_nearbyGranted && _notificationGranted && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectFilesScreen(initialTab: 0)),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show spinner while initial permission checks are running
    if (!_checked) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F3F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Preparations',
          style: TextStyle(
            color: _kDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIllustration(),
            const SizedBox(height: 20),
            _buildPermissionCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Top illustration ─────────────────────────────────────────────────────────

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      height: 200,
      color: _kIllustBg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Green leaves bottom-left ──────────────────────────────────────
          Positioned(
            bottom: 8,
            left: 16,
            child: Icon(Icons.eco, size: 36, color: _kGreen),
          ),
          Positioned(
            bottom: 20,
            left: 40,
            child: Icon(Icons.eco, size: 24, color: _kGreen.withValues(alpha: 0.7)),
          ),

          // ── Tablet UI (white rounded rectangle) centred-right ────────────
          Positioned(
            right: 52,
            top: 20,
            child: Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blue toggle at top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _kBlue,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Form-field lines
                  _fieldLine(width: double.infinity),
                  const SizedBox(height: 10),
                  _fieldLine(width: double.infinity),
                  const SizedBox(height: 10),
                  _fieldLine(width: 80),
                ],
              ),
            ),
          ),

          // ── Person: yellow head ───────────────────────────────────────────
          Positioned(
            left: 72,
            top: 44,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Person: orange body ───────────────────────────────────────────
          Positioned(
            left: 76,
            top: 86,
            child: Container(
              width: 32,
              height: 72,
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLine({required double width}) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── Grouped permission card (both rows in one white container) ───────────────

  Widget _buildPermissionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Row 1 — Nearby device permission
          _buildNearbyRow(),
          // Grey divider
          Container(
            height: 1,
            color: _kDivider,
            margin: const EdgeInsets.symmetric(horizontal: 0),
          ),
          // Row 2 — Notification
          _buildNotificationRow(),
        ],
      ),
    );
  }

  // ── Row 1 ────────────────────────────────────────────────────────────────────

  Widget _buildNearbyRow() {
    return GestureDetector(
      onTap: _requestNearbyPermission,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue badge
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _kBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grant nearby device permission',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Help you connect with friends faster.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _kGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Show checkmark when granted, Allow button when not
            if (_nearbyGranted)
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
            else
              GestureDetector(
                onTap: _requestNearbyPermission,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Row 2 ────────────────────────────────────────────────────────────────────

  Widget _buildNotificationRow() {
    return GestureDetector(
      onTap: _requestNotificationPermission,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue badge
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _kBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sharing progress notification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Check Real-time sharing progress and time remaining in the notification bar',
                    style: TextStyle(
                      fontSize: 12,
                      color: _kGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Show checkmark if granted, otherwise chevron + OPEN
            if (_notificationGranted)
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.expand_less_rounded, color: _kBlue, size: 22),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _requestNotificationPermission,
                    child: const Text(
                      'OPEN',
                      style: TextStyle(
                        color: _kBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

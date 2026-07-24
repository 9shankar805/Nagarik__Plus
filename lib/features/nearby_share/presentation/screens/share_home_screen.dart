import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'receive_screen.dart';
import 'history_screen.dart';
import 'select_files_screen.dart';
import 'connect_screen.dart';
import 'preparations_screen.dart';

/// Root NagarikShare home — SHAREit-style layout (tasks 1.1–1.7)
class ShareHomeScreen extends StatefulWidget {
  const ShareHomeScreen({super.key});

  @override
  State<ShareHomeScreen> createState() => _ShareHomeScreenState();
}

class _ShareHomeScreenState extends State<ShareHomeScreen> {
  // ── 1.6 Bottom nav state ────────────────────────────────────────────────────
  int _tab = 0;

  // ── 1.5 Storage state ───────────────────────────────────────────────────────
  double _usedGb = 0;
  double _totalGb = 0;

  // ── Theme colours ────────────────────────────────────────────────────────────
  static const _kBg    = Color(0xFFF2F3F5); // light grey page background
  static const _kBlue  = Color(0xFF2196F3);
  static const _kText  = Color(0xFF212121);
  static const _kSub   = Color(0xFF757575);
  static const _kWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadStorage(); // 1.5
  }

  // ── 1.5 Storage reader ───────────────────────────────────────────────────────
  Future<void> _loadStorage() async {
    try {
      final dir = Directory('/storage/emulated/0');
      if (await dir.exists()) {
        final result = await Process.run('df', ['-k', '/storage/emulated/0']);
        final lines = (result.stdout as String).split('\n');
        if (lines.length > 1) {
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final total = double.tryParse(parts[1]) ?? 0;
            final used  = double.tryParse(parts[2]) ?? 0;
            if (mounted) {
              setState(() {
                _totalGb = total / (1024 * 1024);
                _usedGb  = used  / (1024 * 1024);
              });
            }
            return;
          }
        }
      }
    } catch (_) {
      // graceful fallback — leave at 0
    }
    try {
      final dir = Directory('/storage/emulated/0');
      if (await dir.exists()) {
        if (mounted) setState(() { _totalGb = 0; _usedGb = 0; });
      }
    } catch (_) {
      // no-op
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _kBg,
        body: _buildTabBody(),
        bottomNavigationBar: _buildBottomNav(), // 1.6
      ),
    );
  }

  // ── 1.6 Tab body dispatcher ───────────────────────────────────────────────────
  Widget _buildTabBody() {
    switch (_tab) {
      case 0:  return _buildHomePage();
      default: return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() => const Center(
    child: Text('Coming Soon',
        style: TextStyle(fontSize: 18, color: Color(0xFF757575))),
  );

  // ── 1.6 Bottom navigation bar ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(
          top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _BottomNavItem(
                icon: Icons.satellite_alt_rounded,
                label: 'Discover',
                active: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              _BottomNavItem(
                icon: Icons.sports_esports_rounded,
                label: 'Games',
                active: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
              _BottomNavItem(
                icon: Icons.face_rounded,
                label: 'Me',
                active: _tab == 3,
                onTap: () => setState(() => _tab = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Home page ─────────────────────────────────────────────────────────────────
  Widget _buildHomePage() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(), // 1.1
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildActionRow(),       // 1.2 — sits directly on grey bg
                  const SizedBox(height: 20),
                  _buildBannerCard(),      // 1.3
                  const SizedBox(height: 20),
                  _buildVideoDownloader(), // 1.4
                  const SizedBox(height: 20),
                  _buildStorageCard(),     // 1.5
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1.1 AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          const Text(
            'NagarikShare',
            style: TextStyle(
              color: _kText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          // Green dollar-circle icon — plain, no bg circle
          _AppBarIconButton(
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFF4CAF50),
            badgeColor: const Color(0xFF4CAF50),
            badgeDot: true,
          ),
          const SizedBox(width: 4),
          // Bell with red badge "1"
          _AppBarIconButton(
            icon: Icons.notifications_none_rounded,
            iconColor: _kText,
            badgeCount: 1,
          ),
          const SizedBox(width: 4),
          // Plus-circle icon
          _AppBarIconButton(
            icon: Icons.add_circle_outline_rounded,
            iconColor: _kText,
          ),
        ],
      ),
    );
  }

  // ── 1.2 Three blue circle action buttons — NO card wrapper ───────────────────
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1.7 Send → PreparationsScreen
          _CircleActionButton(
            icon: Icons.near_me_rounded,
            label: 'Send',
            color: _kBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreparationsScreen()),
            ),
          ),
          // 1.7 Receive → ConnectScreen
          _CircleActionButton(
            icon: Icons.move_to_inbox_rounded,
            label: 'Receive',
            color: _kBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConnectScreen()),
            ),
          ),
          // 1.7 Files → SelectFilesScreen
          _CircleActionButton(
            icon: Icons.folder_rounded,
            label: 'Files',
            color: _kBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SelectFilesScreen(initialTab: 2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1.3 Banner card — full-width edge-to-edge feel ───────────────────────────
  Widget _buildBannerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFCCCCCC),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Grey gradient base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF555555), Color(0xFF999999)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Dark overlay on left side
          Positioned(
            left: 0, top: 0, bottom: 0,
            width: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Color(0x00000000)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Content row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Newspaper icon box
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.newspaper_rounded, color: _kWhite, size: 24),
                ),
                const SizedBox(width: 10),
                // Text column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Trending News of Tech',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'AD You must know!',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFCCCCCC),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Blue "Click" button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: _kWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Click',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1.4 VIDEO DOWNLOADER card ─────────────────────────────────────────────────
  Widget _buildVideoDownloader() {
    final apps = [
      _AppIconData(
        label: 'WhatsApp',
        bgColor: const Color(0xFF25D366),
        iconColor: Colors.white,
        icon: Icons.chat_bubble_rounded,
      ),
      _AppIconData(
        label: 'Instagram',
        gradientColors: const [Color(0xFFf9ce34), Color(0xFFee2a7b), Color(0xFF6228d7)],
        iconColor: Colors.white,
        icon: Icons.camera_alt_rounded,
      ),
      _AppIconData(
        label: 'Facebook',
        bgColor: const Color(0xFF1877F2),
        iconColor: Colors.white,
        icon: Icons.facebook_rounded,
      ),
      _AppIconData(
        label: 'FB Watch',
        bgColor: const Color(0xFF1877F2),
        iconColor: Colors.white,
        icon: Icons.play_circle_fill_rounded,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VIDEO DOWNLOADER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                  letterSpacing: 0.5,
                ),
              ),
              // MORE pill button
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MORE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kSub,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // App icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: apps.map((app) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // App icon circle / gradient
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: app.bgColor,
                              gradient: app.gradientColors != null
                                  ? LinearGradient(
                                      colors: app.gradientColors!,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(app.icon, color: app.iconColor, size: 26),
                          ),
                          // Download arrow badge (bottom-right)
                          Positioned(
                            right: -2, bottom: -2,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _kWhite,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: _kBlue,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 1.5 Storage meter card ────────────────────────────────────────────────────
  Widget _buildStorageCard() {
    if (_totalGb == 0) return const SizedBox.shrink();

    final usedPct = (_usedGb / _totalGb).clamp(0.0, 1.0);
    final pctInt  = (usedPct * 100).round();
    final freeGb  = _totalGb - _usedGb;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Large circular arc progress ~60×60
          SizedBox(
            width: 60, height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: usedPct,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                ),
                Text(
                  '$pctInt%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Storage text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available ${freeGb.toStringAsFixed(2)}GB',
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Total ${_totalGb.toStringAsFixed(2)}GB',
                  style: const TextStyle(color: _kSub, fontSize: 12),
                ),
              ],
            ),
          ),
          // CLEAN — plain TextButton, no border
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _kSub,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'CLEAN',
              style: TextStyle(
                color: _kSub,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

/// AppBar icon button — plain icon, no background circle, optional badge
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int badgeCount;
  final bool badgeDot;
  final Color badgeColor;

  const _AppBarIconButton({
    required this.icon,
    required this.iconColor,
    this.badgeCount = 0,
    this.badgeDot = false,
    this.badgeColor = const Color(0xFFF44336),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        // Red numeric badge
        if (badgeCount > 0)
          Positioned(
            right: 2, top: 2,
            child: Container(
              width: 15, height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFFF44336),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        // Small dot badge (green)
        if (badgeDot && badgeCount == 0)
          Positioned(
            right: 4, top: 4,
            child: Container(
              width: 9, height: 9,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// 72×72 solid blue circle action button with label below (Send / Receive / Files)
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF212121),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation tab item
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2196F3) : const Color(0xFF757575);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for VIDEO DOWNLOADER app icons (task 1.4)
class _AppIconData {
  final String label;
  final Color? bgColor;
  final List<Color>? gradientColors;
  final Color iconColor;
  final IconData icon;

  const _AppIconData({
    required this.label,
    this.bgColor,
    this.gradientColors,
    required this.iconColor,
    required this.icon,
  });
}

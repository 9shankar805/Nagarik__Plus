import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../home/screens/home_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../scanner/screens/camera_scanner_screen.dart';
import '../../scanner/controllers/scanner_controller.dart';
import '../../learning/screens/tutorials_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/l10n_extension.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      NewsScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
      const TutorialsScreen(),
      const ProfileScreen(),
    ];
  }

  void _openScanner() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ScannerController(),
          child: const CameraScannerScreen(),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF2F4F8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _currentIndex == 1
          ? null
          : _NavBar(
              currentIndex: _currentIndex,
              onTap: _onTap,
              onScanTap: _openScanner,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav bar — floating pill with a raised center scan button
// ─────────────────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanTap;

  const _NavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      // Outer container — sets the background color the pill floats on
      color: const Color(0xFFF2F4F8),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPad > 0 ? bottomPad - 16 : 0,
        top: 0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Pill bar ────────────────────────────────────────────
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Home
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: context.l10n.home,
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),

                // Divider
                _Divider(),

                // Samachar (News & Shorts)
                _NavItem(
                  icon: Icons.newspaper_outlined,
                  activeIcon: Icons.newspaper_rounded,
                  label: Localizations.localeOf(context).languageCode == 'ne' ? 'समाचार' : 'News',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),

                // Center space — no dividers, just room for the floating circle
                const Expanded(child: SizedBox()),

                // Tutorials
                _NavItem(
                  icon: Icons.school_outlined,
                  activeIcon: Icons.school_rounded,
                  label: context.l10n.tutorials,
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),

                // Divider
                _Divider(),

                // Profile
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: context.l10n.profileTitle,
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),

          // ── Raised scan button — sits above the pill ────────────
          Positioned(
            top: -32, // pops above the pill
            child: _ScanButton(onTap: onScanTap),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav item — icon + label, always visible
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xFF3D4A5C);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin vertical divider between items
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFE5E9F0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Center raised scan button — blue gradient circle with white ring
// Bottom part sits inside the pill, top part floats above it
// ─────────────────────────────────────────────────────────────────────────────
class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        // Total height = circle (64) + gap (4) + label line height (~16)
        // The Positioned top: -28 pulls circle above the pill
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White ring wrapping the blue gradient circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2F4F8), // matches outer bg — acts as halo
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4), // white ring thickness
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D8EFF), Color(0xFF1A56DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    AppAssets.scanIcon,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Scan label — same baseline as other nav labels
            Text(
              Localizations.localeOf(context).languageCode == 'ne' ? 'स्क्यान' : 'Scan',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

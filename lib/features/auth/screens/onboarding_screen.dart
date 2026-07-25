import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 4 pages, each with its own background image
  static const _bgImages = [
    AppAssets.onboardingBg1,
    AppAssets.onboardingBg2,
    AppAssets.onboardingBg3,
    AppAssets.onboardingBg4,
  ];

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.lock_outlined,
      color: AppColors.primary,
      title: 'Secure Digital Locker',
      subtitle:
          'Store all your important documents safely with AES-256 encryption and biometric protection.',
    ),
    _OnboardingPage(
      icon: Icons.article_outlined,
      color: AppColors.secondary,
      title: 'Citizen Service Guides',
      subtitle:
          'Step-by-step guides for passport, PAN, National ID, driving license, and more government services.',
    ),
    _OnboardingPage(
      icon: Icons.smart_toy_outlined,
      color: AppColors.accent,
      title: 'AI-Powered Assistant',
      subtitle:
          'Ask questions about any government service and get instant, accurate answers in Nepali or English.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      color: AppColors.danger,
      title: 'Smart Reminders',
      subtitle:
          'Never miss a document expiry. Get reminders for passport, license, insurance, and more.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Image.asset(
              _bgImages[_currentPage],
              key: ValueKey(_currentPage),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: _pages[_currentPage].color,
              ),
            ),
          ),

          // ── Dark gradient overlay ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black54,
                  Colors.black87,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Swipeable PageView (behind content, no visual children) ───────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, _) => const SizedBox.expand(),
          ),

          // ── Content (on top — absorbs pointer so buttons work) ────────────
          IgnorePointer(
            ignoring: false,
            child: SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.login),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Icon circle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    key: ValueKey(_currentPage),
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white38, width: 1.5),
                    ),
                    child: Icon(
                      _pages[_currentPage].icon,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _pages[_currentPage].title,
                      key: ValueKey('title_$_currentPage'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _pages[_currentPage].subtitle,
                      key: ValueKey('sub_$_currentPage'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GradientButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    onPressed: _nextPage,
                    icon: _currentPage == _pages.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                ),

                const SizedBox(height: 20),

                // Disclaimer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    AppStrings.disclaimer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),        // SafeArea end
        ),          // IgnorePointer end
        ],          // Stack children end
      ),            // Stack end
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

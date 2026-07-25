import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    }
  }

  void _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithApple();
    if (!mounted) return;
    setState(() => _isAppleLoading = false);
    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar icons light (white) so they show on the image
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ─────────────────────────────────────────
          // 1. Full-screen background image
          // ─────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              AppAssets.loginBg,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ─────────────────────────────────────────
          // 2. Gradient overlay:
          //    • Top: nearly transparent → let the mountains breathe
          //    • Bottom: solid white-ish panel for the form area
          // ─────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.30, 0.52, 1.0],
                  colors: [
                    Color(0x00000000), // fully transparent at top
                    Color(0x1A1A3A6A), // very slight blue tint
                    Color(0xCCEFF5FF), // starts fading to light blue-white
                    Color(0xFFF0F6FF), // solid near-white at bottom
                  ],
                ),
              ),
            ),
          ),

          // ─────────────────────────────────────────
          // 3. Content — pinned to bottom with fixed heights
          // ─────────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Top hero area: logo + title (sits over the image) ──
                          SizedBox(height: screenH * 0.055),

                          // Logo
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  AppAssets.appIcon,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Welcome Back
                          Text(
                            context.l10n.welcomeBack,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                    blurRadius: 12,
                                    color: Color(0x88000000),
                                    offset: Offset(0, 3)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 5),

                          // Subtitle
                          Text(
                            context.l10n.signInToAccount,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xDDFFFFFF),
                              shadows: [
                                Shadow(
                                    blurRadius: 6,
                                    color: Color(0x66000000),
                                    offset: Offset(0, 1)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ─────────────────────────────────────────
                          // 4. Bottom sheet — form + buttons
                          // ─────────────────────────────────────────
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F6FF),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                            ),
                            padding: EdgeInsets.fromLTRB(
                                22, 28, 22, mq.padding.bottom + 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                      // ── Form card ──
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email
                              _label(context.l10n.emailAddress),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A2B4A)),
                                decoration: _deco(
                                  hint: context.l10n.enterYourEmail,
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.l10n.validationEmailRequired;
                                  }
                                  if (!v.contains('@')) {
                                    return context.l10n.validationEmailInvalid;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password
                              _label(context.l10n.password),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A2B4A)),
                                decoration: _deco(
                                  hint: context.l10n.enterYourPassword,
                                  icon: Icons.lock_outline,
                                  suffix: GestureDetector(
                                    onTap: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF8A9BB0),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.l10n.validationPasswordRequired;
                                  }
                                  if (v.length < 6) {
                                    return context.l10n.validationPasswordTooShort;
                                  }
                                  return null;
                                },
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    context.l10n.forgotPassword,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Sign In button ──
                      GradientButton(
                        label: context.l10n.signIn,
                        onPressed: _login,
                        isLoading: _isLoading,
                        icon: Icons.login_rounded,
                      ),

                      const SizedBox(height: 10),

                      // ── Biometrics button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.main),
                          icon: const Icon(Icons.fingerprint,
                              size: 21, color: Color(0xFF1A2B4A)),
                          label: Text(
                            context.l10n.signInWithBiometrics,
                            style: const TextStyle(
                              color: Color(0xFF1A2B4A),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFCDD9E8), width: 1.5),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── OR divider ──
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFCDD9E8).withValues(alpha: 0.9),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              context.l10n.orDivider,
                              style: const TextStyle(
                                color: Color(0xFF9AAABB),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFCDD9E8).withValues(alpha: 0.9),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Google / Gmail Sign In ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: (_isGoogleLoading || _isAppleLoading)
                              ? null
                              : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFCDD9E8), width: 1.5),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFEA4335),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'G',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google / Gmail',
                                      style: TextStyle(
                                        color: Color(0xFF1A2B4A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      if (Platform.isIOS || Platform.isMacOS) ...[
                        const SizedBox(height: 10),

                        // ── Apple Sign In ──
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isGoogleLoading || _isAppleLoading)
                                ? null
                                : _handleAppleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isAppleLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.apple,
                                          size: 24, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text(
                                        'Continue with Apple',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Create account ──
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${context.l10n.dontHaveAccount}  ",
                              style: const TextStyle(
                                  color: Color(0xFF5A6A80), fontSize: 13.5),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.register),
                              child: Text(
                                context.l10n.signUp,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Disclaimer ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_outlined,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l10n.appDisclaimer,
                                style: const TextStyle(
                                  color: Color(0xFF4A5A70),
                                  fontSize: 10.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF1A2B4A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFB0BEC8), fontSize: 13.5),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 19),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF4F8FD),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDE5EF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDE5EF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      );
}

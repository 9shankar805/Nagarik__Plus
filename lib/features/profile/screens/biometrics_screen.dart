import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({super.key});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen>
    with SingleTickerProviderStateMixin {
  bool _fingerprintEnabled = true;
  bool _faceIdEnabled      = false;
  bool _loginWithBio       = true;
  bool _paymentWithBio     = false;

  late AnimationController _pulseController;
  late Animation<double>    _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.biometricEnabled != null) {
        setState(() {
          _loginWithBio = user!.biometricEnabled;
          _fingerprintEnabled = user.biometricEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        title: const Text('Biometrics',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero fingerprint section
            _buildHeroCard(),
            const SizedBox(height: 24),

            // Biometric methods
            _sectionTitle('Authentication Methods'),
            const SizedBox(height: 10),
            _buildCard([
              _buildToggleTile(
                icon: Icons.fingerprint_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: AppColors.secondary,
                label: 'Fingerprint',
                subtitle: 'Use fingerprint to authenticate',
                value: _fingerprintEnabled,
                onChanged: (v) async {
                  setState(() => _fingerprintEnabled = v);
                  await _updateBiometricEnabled(v);
                },
              ),
              const Divider(height: 1, indent: 68, color: Color(0xFFF0F4FA)),
              _buildToggleTile(
                icon: Icons.face_rounded,
                iconBg: const Color(0xFFE3EEFF),
                iconColor: AppColors.primary,
                label: 'Face ID',
                subtitle: 'Use face recognition to authenticate',
                value: _faceIdEnabled,
                onChanged: (v) async {
                  setState(() => _faceIdEnabled = v);
                  await _updateBiometricEnabled(v);
                },
              ),
            ]),
            const SizedBox(height: 24),

            // Usage settings
            _sectionTitle('Usage'),
            const SizedBox(height: 10),
            _buildCard([
              _buildToggleTile(
                icon: Icons.login_rounded,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: AppColors.info,
                label: 'App Login',
                subtitle: 'Use biometrics to unlock the app',
                value: _loginWithBio,
                onChanged: (v) async {
                  setState(() => _loginWithBio = v);
                  await _updateBiometricEnabled(v);
                },
              ),
              const Divider(height: 1, indent: 68, color: Color(0xFFF0F4FA)),
              _buildToggleTile(
                icon: Icons.payment_rounded,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF9A825),
                label: 'Payment Confirmation',
                subtitle: 'Confirm payments with biometrics',
                value: _paymentWithBio,
                onChanged: (v) => setState(() => _paymentWithBio = v),
              ),
            ]),
            const SizedBox(height: 24),

            // Enroll button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enrollBiometric,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Enroll New Biometric',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biometric data is stored locally on your device and is never shared with our servers.',
                      style: TextStyle(
                          color: Color(0xFF5A6A80),
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _fingerprintEnabled || _faceIdEnabled
                ? 'Biometrics Active'
                : 'Biometrics Inactive',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _fingerprintEnabled || _faceIdEnabled
                ? 'Your account is protected with biometric authentication'
                : 'Enable biometric authentication for added security',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _statusChip(
                Icons.fingerprint_rounded,
                'Fingerprint',
                _fingerprintEnabled),
            const SizedBox(width: 10),
            _statusChip(Icons.face_rounded, 'Face ID', _faceIdEnabled),
          ]),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0.5 : 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 5),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.greenAccent : Colors.white30,
            shape: BoxShape.circle,
          ),
        ),
      ]),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B4A))),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9AAABB))),
          ]),
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A2B4A)));

  Future<void> _updateBiometricEnabled(bool enabled) async {
    try {
      await context.read<ProfileProvider>().updateProfile({
        'biometric_enabled': enabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enabled ? 'Biometrics enabled' : 'Biometrics disabled'),
          backgroundColor: AppColors.secondary,
        ));
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $msg'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) {
        // loading done
      }
    }
  }

  // ── Enroll flow ────────────────────────────────────────────────────────────
  void _enrollBiometric() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.fingerprint_rounded,
              color: AppColors.secondary, size: 56),
          const SizedBox(height: 14),
          const Text('Enroll Biometric',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Place your finger on the sensor or look at the camera to enroll your biometric.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8A9BB0), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric enrolled successfully'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary),
                child: const Text('Enroll',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

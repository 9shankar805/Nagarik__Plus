import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SecurityPinScreen extends StatefulWidget {
  const SecurityPinScreen({super.key});

  @override
  State<SecurityPinScreen> createState() => _SecurityPinScreenState();
}

class _SecurityPinScreenState extends State<SecurityPinScreen> {
  // PIN change state
  final _currentPin  = TextEditingController();
  final _newPin      = TextEditingController();
  final _confirmPin  = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _pinLoading  = false;

  // Two-factor auth toggle
  bool _twoFactor = false;

  @override
  void dispose() {
    _currentPin.dispose();
    _newPin.dispose();
    _confirmPin.dispose();
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
        title: const Text('Security & PIN',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security overview card
            _buildSecurityStatus(),
            const SizedBox(height: 24),

            // Change PIN section
            _sectionTitle('Change PIN'),
            const SizedBox(height: 10),
            _buildChangePinCard(),
            const SizedBox(height: 24),

            // Two-factor auth
            _sectionTitle('Login Security'),
            const SizedBox(height: 10),
            _buildCard([
              _buildToggleTile(
                icon: Icons.security_rounded,
                iconBg: const Color(0xFFE3EEFF),
                iconColor: AppColors.primary,
                label: 'Two-Factor Authentication',
                subtitle: 'Extra security for your account',
                value: _twoFactor,
                onChanged: (v) => setState(() => _twoFactor = v),
              ),
              const Divider(height: 1, indent: 68, color: Color(0xFFF0F4FA)),
              _buildNavTile(
                icon: Icons.devices_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: AppColors.secondary,
                label: 'Active Sessions',
                subtitle: '2 devices logged in',
                onTap: () => _showActiveSessions(context),
              ),
            ]),
            const SizedBox(height: 24),

            // Danger zone
            _sectionTitle('Danger Zone'),
            const SizedBox(height: 10),
            _buildCard([
              _buildNavTile(
                icon: Icons.lock_reset_rounded,
                iconBg: const Color(0xFFFFEDE3),
                iconColor: const Color(0xFFE65100),
                label: 'Reset PIN',
                subtitle: 'Reset via email verification',
                onTap: () => _showResetConfirm(context),
              ),
              const Divider(height: 1, indent: 68, color: Color(0xFFF0F4FA)),
              _buildNavTile(
                icon: Icons.no_accounts_rounded,
                iconBg: const Color(0xFFFFEBEE),
                iconColor: AppColors.danger,
                label: 'Deactivate Account',
                subtitle: 'Temporarily disable your account',
                onTap: () => _showDeactivateConfirm(context),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Security overview ──────────────────────────────────────────────────────
  Widget _buildSecurityStatus() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_rounded,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Secured',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('PIN is set · Last changed 30 days ago',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Strong',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // ── Change PIN card ────────────────────────────────────────────────────────
  Widget _buildChangePinCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildPinField(
              controller: _currentPin,
              label: 'Current PIN',
              show: _showCurrent,
              onToggle: () =>
                  setState(() => _showCurrent = !_showCurrent)),
          const Divider(height: 20, color: Color(0xFFF0F4FA)),
          _buildPinField(
              controller: _newPin,
              label: 'New PIN',
              show: _showNew,
              onToggle: () =>
                  setState(() => _showNew = !_showNew)),
          const Divider(height: 20, color: Color(0xFFF0F4FA)),
          _buildPinField(
              controller: _confirmPin,
              label: 'Confirm New PIN',
              show: _showConfirm,
              onToggle: () =>
                  setState(() => _showConfirm = !_showConfirm)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pinLoading ? null : _changePin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _pinLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Update PIN',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Color(0xFF9AAABB), fontSize: 13),
        counterText: '',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: Icon(
              show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: const Color(0xFFCCD5E0),
              size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }

  // ── Reusable tile builders ─────────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              activeColor: AppColors.primary,
              onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCCD5E0), size: 20),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A2B4A)));

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _changePin() async {
    if (_currentPin.text.length < 4) {
      _snack('Enter your current PIN', isError: true);
      return;
    }
    if (_newPin.text.length < 4) {
      _snack('New PIN must be at least 4 digits', isError: true);
      return;
    }
    if (_newPin.text != _confirmPin.text) {
      _snack('PINs do not match', isError: true);
      return;
    }
    setState(() => _pinLoading = true);
    try {
      await context.read<AuthProvider>().changePin(
        currentPin: _currentPin.text,
        newPin: _newPin.text,
      );
      _currentPin.clear();
      _newPin.clear();
      _confirmPin.clear();
      _snack('PIN updated successfully');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack('Failed: $msg', isError: true);
    } finally {
      setState(() => _pinLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.secondary,
    ));
  }

  void _showActiveSessions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Active Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _sessionTile('This device', 'Android · Kathmandu', true),
          const Divider(height: 1, color: Color(0xFFF0F4FA)),
          _sessionTile('iPhone 13', 'iOS · Last active 2h ago', false),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger)),
              child: const Text('Logout All Other Devices'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sessionTile(String device, String info, bool current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFE3EEFF),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.smartphone_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text(info,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9AAABB))),
        ])),
        if (current)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Current',
                style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset PIN',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'A reset link will be sent to your registered email address.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _snack('Reset link sent to your email');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Send Link',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeactivateConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate Account',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.danger)),
        content: const Text(
            'Your account will be temporarily disabled. You can reactivate it by logging in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Deactivate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/biometric_service.dart';

/// Wraps any screen with biometric / PIN authentication.
/// Shows a lock screen until auth succeeds, then renders [child].
class BiometricLockGate extends StatefulWidget {
  final Widget child;
  final String reason;

  const BiometricLockGate({
    super.key,
    required this.child,
    this.reason = 'Authenticate to access your vault',
  });

  @override
  State<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends State<BiometricLockGate> {
  final _bio    = BiometricService.instance;
  bool _unlocked = false;
  bool _checking = true;
  String? _error;

  // PIN fallback
  bool _showPin  = false;
  final _pinCtrl = TextEditingController();
  int _attempts  = 0;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    setState(() { _checking = true; _error = null; });
    final available = await _bio.isBiometricAvailable();
    if (available) {
      final ok = await _bio.authenticate(reason: widget.reason);
      if (ok) {
        setState(() { _unlocked = true; _checking = false; });
        return;
      }
    }
    // Fall back to PIN if biometric fails / not available
    setState(() { _checking = false; _showPin = true; });
  }

  Future<void> _verifyPin() async {
    final input = _pinCtrl.text.trim();
    final hasPin = await _bio.hasPin();
    if (!hasPin) {
      // First time: set PIN
      if (input.length >= 4) {
        await _bio.setPin(input);
        setState(() => _unlocked = true);
      } else {
        setState(() => _error = 'PIN must be at least 4 digits.');
      }
      return;
    }

    final ok = await _bio.verifyPin(input);
    if (ok) {
      setState(() => _unlocked = true);
    } else {
      _attempts++;
      _pinCtrl.clear();
      setState(() => _error = _attempts >= 5
          ? 'Too many attempts. Please try again later.'
          : 'Incorrect PIN. ${5 - _attempts} attempt${5 - _attempts == 1 ? '' : 's'} remaining.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: _checking
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          size: 52, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text('Document Vault',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      _showPin
                          ? 'Enter your vault PIN'
                          : 'Authenticate to continue',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    if (_showPin) ...[
                      TextField(
                        controller:    _pinCtrl,
                        obscureText:   true,
                        keyboardType:  TextInputType.number,
                        maxLength:     6,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            letterSpacing: 8),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '● ● ● ●',
                          hintStyle: const TextStyle(
                              color: Colors.white24, letterSpacing: 8),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _verifyPin(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13),
                            textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _verifyPin,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12))),
                          child: const Text('Unlock',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _tryBiometric,
                        icon: const Icon(Icons.fingerprint_rounded,
                            color: Colors.white54),
                        label: const Text('Use Biometrics',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _tryBiometric,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Authenticate'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showPin = true),
                        child: const Text('Use PIN instead',
                            style:
                                TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

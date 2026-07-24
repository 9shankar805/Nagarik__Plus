import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/advisor_model.dart';
import '../models/consultation_booking_model.dart';
import '../providers/advisor_call_provider.dart';

class AdvisorCallScreen extends StatelessWidget {
  final Advisor advisor;
  final ConsultationType callType;

  const AdvisorCallScreen({
    super.key,
    required this.advisor,
    required this.callType,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdvisorCallProvider(advisor: advisor, callType: callType),
      child: _AdvisorCallBody(advisor: advisor),
    );
  }
}

class _AdvisorCallBody extends StatelessWidget {
  final Advisor advisor;

  const _AdvisorCallBody({required this.advisor});

  void _showRatingSheet(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    double userRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 14),

                  const Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 48),
                  const SizedBox(height: 10),

                  Text(
                    isNepali ? 'परामर्श कस्तो रह्यो?' : 'Rate your Call Consultation',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isNepali ? '${advisor.name} संगको कुराकानी अनुभव दर्ता गर्नुहोस्' : 'Give feedback for ${advisor.name}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 16),

                  // Star rating bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= userRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFFA000),
                          size: 36,
                        ),
                        onPressed: () {
                          setSheetState(() => userRating = starValue.toDouble());
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: isNepali ? 'थप प्रतिक्रिया लेख्नुहोस् (अनिवार्य छैन)...' : 'Write comments (optional)...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop(); // close rating sheet
                        Navigator.of(context).pop(); // close call screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isNepali ? 'समीक्षा बुझाइयो। धन्यवाद!' : 'Thank you for your feedback!')),
                        );
                      },
                      child: Text(
                        isNepali ? 'समीक्षा पठाउनुहोस्' : 'Submit Review',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final callProv = Provider.of<AdvisorCallProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate blue background
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () {
                      callProv.endCall();
                      _showRatingSheet(context);
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: Color(0xFF4ADE80), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          isNepali ? 'एन्क्रिप्टेड १-अन-१ कल' : 'Encrypted 1-on-1 Call',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Advisor Avatar with Pulse Animation
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Rings
                      if (callProv.callState == CallState.connected)
                        const _AudioWavePulseRing(),

                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(advisor.avatarUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    advisor.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    isNepali ? advisor.titleNp : advisor.titleEn,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),

                  // Call Status / Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: callProv.callState == CallState.connected
                          ? const Color(0xFF22C55E).withOpacity(0.15)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: callProv.callState == CallState.connected
                            ? const Color(0xFF22C55E)
                            : Colors.white30,
                      ),
                    ),
                    child: Text(
                      callProv.callState == CallState.dialing
                          ? (isNepali ? 'डायल गर्दैछ...' : 'Connecting...')
                          : callProv.callState == CallState.ringing
                              ? (isNepali ? 'घण्टी जाँदैछ...' : 'Ringing...')
                              : callProv.callState == CallState.connected
                                  ? 'Connected • ${callProv.formattedDuration}'
                                  : 'Call Ended',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: callProv.callState == CallState.connected
                            ? const Color(0xFF4ADE80)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Live Audio Wave Bars Visualizer (when connected)
            if (callProv.callState == CallState.connected)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: _LiveWaveformVisualizer(),
              ),

            // Call Action Control Buttons Bar
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute Mic Toggle
                  _CallControlButton(
                    icon: callProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: callProv.isMuted,
                    activeColor: Colors.red,
                    label: callProv.isMuted ? 'Muted' : 'Mute',
                    onTap: callProv.toggleMute,
                  ),

                  // Speaker Toggle
                  _CallControlButton(
                    icon: callProv.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    isActive: callProv.isSpeakerOn,
                    activeColor: AppColors.primary,
                    label: callProv.isSpeakerOn ? 'Speaker On' : 'Speaker Off',
                    onTap: callProv.toggleSpeaker,
                  ),

                  // Video Toggle
                  _CallControlButton(
                    icon: callProv.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    isActive: callProv.isVideoOn,
                    activeColor: AppColors.primary,
                    label: callProv.isVideoOn ? 'Video On' : 'Video Off',
                    onTap: callProv.toggleVideo,
                  ),

                  // End Call Red Circle Button
                  GestureDetector(
                    onTap: () {
                      callProv.endCall();
                      _showRatingSheet(context);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x66EF4444), blurRadius: 16, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final String label;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.label,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AudioWavePulseRing extends StatefulWidget {
  const _AudioWavePulseRing();

  @override
  State<_AudioWavePulseRing> createState() => _AudioWavePulseRingState();
}

class _AudioWavePulseRingState extends State<_AudioWavePulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          width: 140 + (_animController.value * 60),
          height: 140 + (_animController.value * 60),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF388E3C).withOpacity(1.0 - _animController.value),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

class _LiveWaveformVisualizer extends StatelessWidget {
  const _LiveWaveformVisualizer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(12, (index) {
        final height = 12.0 + Random().nextInt(28);
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

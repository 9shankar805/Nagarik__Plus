import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
      child: _AdvisorCallBody(advisor: advisor, callType: callType),
    );
  }
}

class _AdvisorCallBody extends StatefulWidget {
  final Advisor advisor;
  final ConsultationType callType;

  const _AdvisorCallBody({required this.advisor, required this.callType});

  @override
  State<_AdvisorCallBody> createState() => _AdvisorCallBodyState();
}

class _AdvisorCallBodyState extends State<_AdvisorCallBody> {
  bool _showingRating = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _showRatingSheet(BuildContext context, AdvisorCallProvider callProv) {
    if (_showingRating) return;
    _showingRating = true;
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
            return PopScope(
              canPop: false,
              child: Container(
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
                      isNepali ? '${widget.advisor.name} संगको कुराकानी अनुभव दर्ता गर्नुहोस्' : 'Give feedback for ${widget.advisor.name}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                    ),
                    const SizedBox(height: 16),
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
                          Navigator.of(ctx).pop();
                          _showingRating = false;
                          Navigator.of(context).pop();
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
              ),
            );
          },
        );
      },
    ).whenComplete(() => _showingRating = false);
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final callProv = Provider.of<AdvisorCallProvider>(context);
    final isVideo = callProv.isVideoCall && callProv.isVideoOn;

    if (callProv.errorMessage != null &&
        callProv.callState == CallState.error &&
        ScaffoldMessenger.maybeOf(context) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(callProv.errorMessage!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            if (isVideo) _buildVideoLayer(callProv),
            Column(
              children: [
                _buildTopBar(context, isNepali, callProv),
                const Spacer(),
                if (!isVideo) _buildAvatarPanel(isNepali, callProv),
                const Spacer(),
                if (callProv.callState == CallState.connected && !isVideo)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: _LiveWaveformVisualizer(),
                  ),
                _buildControlBar(context, isNepali, callProv),
              ],
            ),
            if (isVideo) _buildPiPLocalVideo(callProv),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLayer(AdvisorCallProvider callProv) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: RTCVideoView(
          callProv.remoteRenderer,
          placeholderBuilder: (_) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(widget.advisor.avatarUrl),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.advisor.name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  Localizations.localeOf(context).languageCode == 'ne' ? 'भिडियो कनेक्ट हुँदैछ...' : 'Remote video connecting...',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPiPLocalVideo(AdvisorCallProvider callProv) {
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        width: 110,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: RTCVideoView(callProv.localRenderer, mirror: callProv.isFrontCamera),
        ),
      ),
    );
  }

  Padding _buildTopBar(BuildContext context, bool isNepali, AdvisorCallProvider callProv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () async {
              await callProv.endCall();
              if (context.mounted) _showRatingSheet(context, callProv);
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
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
    );
  }

  Center _buildAvatarPanel(bool isNepali, AdvisorCallProvider callProv) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (callProv.callState == CallState.connected) const _AudioWavePulseRing(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(widget.advisor.avatarUrl, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.advisor.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isNepali ? widget.advisor.titleNp : widget.advisor.titleEn,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: callProv.callState == CallState.connected
                  ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                  : callProv.callState == CallState.error
                      ? AppColors.danger.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: callProv.callState == CallState.connected
                    ? const Color(0xFF22C55E)
                    : callProv.callState == CallState.error
                        ? AppColors.danger
                        : Colors.white30,
              ),
            ),
            child: Text(
              callProv.callState == CallState.dialing
                  ? (isNepali ? 'डायल गर्दैछ...' : 'Calling...')
                  : callProv.callState == CallState.ringing
                      ? (isNepali ? 'घण्टी जाँदैछ...' : 'Ringing...')
                      : callProv.callState == CallState.connected
                          ? 'Connected • ${callProv.formattedDuration}'
                          : callProv.callState == CallState.error
                              ? (isNepali ? 'त्रुटि भयो' : 'Call Error')
                              : 'Call Ended',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: callProv.callState == CallState.connected
                    ? const Color(0xFF4ADE80)
                    : callProv.callState == CallState.error
                        ? Colors.redAccent
                        : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildControlBar(BuildContext context, bool isNepali, AdvisorCallProvider callProv) {
    final isVideoCall = widget.callType == ConsultationType.videoCall;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CallControlButton(
            icon: callProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: callProv.isMuted,
            activeColor: Colors.red,
            label: callProv.isMuted ? (isNepali ? 'म्युट' : 'Muted') : (isNepali ? 'माइक' : 'Mute'),
            onTap: callProv.toggleMute,
          ),
          _CallControlButton(
            icon: callProv.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            isActive: callProv.isSpeakerOn,
            activeColor: AppColors.primary,
            label: callProv.isSpeakerOn ? (isNepali ? 'स्पिकर' : 'Speaker') : (isNepali ? 'अफ' : 'Off'),
            onTap: callProv.toggleSpeaker,
          ),
          if (isVideoCall)
            _CallControlButton(
              icon: callProv.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              isActive: callProv.isVideoOn,
              activeColor: AppColors.primary,
              label: callProv.isVideoOn ? (isNepali ? 'भिडियो' : 'Video') : (isNepali ? 'अफ' : 'Off'),
              onTap: callProv.toggleVideo,
            ),
          if (isVideoCall)
            _CallControlButton(
              icon: Icons.flip_camera_ios_rounded,
              isActive: false,
              activeColor: AppColors.primary,
              label: isNepali ? 'फ्लिप' : 'Flip',
              onTap: callProv.switchCamera,
            ),
          GestureDetector(
            onTap: () async {
              await callProv.endCall();
              if (context.mounted) _showRatingSheet(context, callProv);
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
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final String label;
  final Future<void> Function() onTap;

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
      onTap: () => onTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white.withValues(alpha: 0.1),
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
              color: const Color(0xFF388E3C).withValues(alpha: 1.0 - _animController.value),
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

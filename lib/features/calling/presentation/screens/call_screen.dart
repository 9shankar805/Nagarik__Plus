import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nagarik_plus/core/constants/app_colors.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_api_service.dart';
import '../../models/call_model.dart';

class CallScreen extends StatefulWidget {
  final int callId;
  final bool isVideoCall;
  final String? receiverName;
  final String? receiverAvatar;

  const CallScreen({
    required this.callId,
    required this.isVideoCall,
    this.receiverName,
    this.receiverAvatar,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late WebRTCService _webRTCService;
  late CallApiService _callApiService;
  
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  bool _isInitialized = false;
  String _callDuration = '00:00';
  DateTime? _callStartTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _webRTCService = WebRTCService();
    _callApiService = CallApiService();

    _webRTCService.onCallEnded = (reason) {
      _endCall();
    };

    _webRTCService.onCallError = (error) {
      _showError(error);
    };

    await _initializeRenderers();
    await _startCall();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _startCall() async {
    try {
      await _webRTCService.initializePeerConnection();
      final stream = await _webRTCService.getUserMedia(widget.isVideoCall);
      _localRenderer.srcObject = stream;
      
      await _webRTCService.createOffer();
      
      if (mounted) {
        setState(() {
          _callStartTime = DateTime.now();
        });
        _startTimer();
      }
    } catch (e) {
      _showError('Failed to start call: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) {
          setState(() {
            _callDuration = '$minutes:$seconds';
          });
        }
      }
    });
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    try {
      await _callApiService.endCall(widget.callId);
    } catch (e) {
      // Ignore error if call already ended
    }
    await _webRTCService.dispose();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _webRTCService.toggleAudio(!_isMuted);
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    await _webRTCService.toggleVideo(!_isVideoOff);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    // TODO: Implement speaker toggle using flutter_sound or similar
  }

  Future<void> _switchCamera() async {
    await _webRTCService.switchCamera();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? _buildCallUI()
          : const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
    );
  }

  Widget _buildCallUI() {
    return Stack(
      children: [
        // Remote video (full screen)
        if (widget.isVideoCall)
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer),
          )
        else
          Positioned.fill(
            child: Container(
              color: AppColors.primaryDark,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: widget.receiverAvatar != null
                          ? NetworkImage(widget.receiverAvatar!)
                          : null,
                      child: widget.receiverAvatar == null
                          ? Text(
                              widget.receiverName?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.receiverName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _callDuration,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Local video (picture-in-picture)
        if (widget.isVideoCall)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),
          ),
        
        // Top bar
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _callDuration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Caller info
              if (!widget.isVideoCall)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    widget.receiverName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    backgroundColor: _isMuted ? Colors.grey : Colors.white.withOpacity(0.3),
                    onPressed: _toggleMute,
                  ),
                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      backgroundColor: _isVideoOff ? Colors.grey : Colors.white.withOpacity(0.3),
                      onPressed: _toggleVideo,
                    ),
                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      onPressed: _switchCamera,
                    ),
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    backgroundColor: _isSpeakerOn ? Colors.white.withOpacity(0.3) : Colors.grey,
                    onPressed: _toggleSpeaker,
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    backgroundColor: AppColors.danger,
                    onPressed: _endCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webRTCService.dispose();
    super.dispose();
  }
}

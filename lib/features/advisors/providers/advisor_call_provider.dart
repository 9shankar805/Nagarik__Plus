import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../calling/services/call_api_service.dart';
import '../../calling/services/webrtc_service.dart';
import '../models/advisor_model.dart';
import '../models/consultation_booking_model.dart';

enum CallState {
  dialing,
  ringing,
  connected,
  ended,
  error,
}

class AdvisorCallProvider extends ChangeNotifier {
  final Advisor advisor;
  final ConsultationType callType;

  AdvisorCallProvider({
    required this.advisor,
    required this.callType,
  }) {
    _initRenderers();
    _startCallFlow();
  }

  final CallApiService _callApi = CallApiService();
  final WebRTCService _webRTC = WebRTCService();

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  CallState _callState = CallState.dialing;
  int _callId = 0;
  int _durationSeconds = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOn = true;
  bool _isFrontCamera = true;
  String? _errorMessage;
  bool _usingFallbackCall = false;

  CallState get callState => _callState;
  int get callId => _callId;
  int get durationSeconds => _durationSeconds;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoOn => _isVideoOn;
  bool get isFrontCamera => _isFrontCamera;
  String? get errorMessage => _errorMessage;
  bool get isVideoCall => callType == ConsultationType.videoCall;
  bool get usingFallbackCall => _usingFallbackCall;

  String get formattedDuration {
    final mins = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_durationSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> _startCallFlow() async {
    _callState = CallState.dialing;
    _errorMessage = null;
    notifyListeners();

    _webRTC.onCallEnded = (_) => endCall();
    _webRTC.onCallError = (err) {
      _errorMessage ??= err;
      notifyListeners();
    };

    final receiverId = int.tryParse(advisor.id) ?? 0;
    final typeStr = callType == ConsultationType.videoCall ? 'video' : 'audio';

    try {
      await _webRTC.initializePeerConnection();
      final stream = await _webRTC.getUserMedia(isVideoCall);
      localRenderer.srcObject = stream;
      notifyListeners();

      if (receiverId > 0) {
        final resp = await _callApi.initiateCall(receiverId, typeStr);
        _callId = resp.data?.callId ?? 0;
        if (_callId == 0) _usingFallbackCall = true;
      } else {
        _usingFallbackCall = true;
      }

      _callState = CallState.ringing;
      notifyListeners();

      await _webRTC.createOffer();

      _connectTimer = Timer(const Duration(seconds: 3), () {
        _callState = CallState.connected;
        notifyListeners();
        _startTimer();
      });
    } catch (e) {
      _handleError('Call setup failed: $e');
    }
  }

  void _handleError(String msg) {
    _errorMessage = msg;
    _callState = CallState.error;
    notifyListeners();
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationSeconds++;
      notifyListeners();
    });
  }

  Future<void> toggleMute() async {
    try {
      await _webRTC.toggleAudio(_isMuted);
      _isMuted = !_isMuted;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Mute toggle failed: $e';
      notifyListeners();
    }
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    try {
      await _webRTC.toggleVideo(_isVideoOn);
      _isVideoOn = !_isVideoOn;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Video toggle failed: $e';
      notifyListeners();
    }
  }

  Future<void> switchCamera() async {
    try {
      await _webRTC.switchCamera();
      _isFrontCamera = !_isFrontCamera;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Camera switch failed: $e';
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    if (_callState == CallState.ended) return;
    _callTimer?.cancel();
    _connectTimer?.cancel();
    _callTimer = null;
    _connectTimer = null;

    try {
      if (_callId > 0 && !_usingFallbackCall) {
        await _callApi.endCall(_callId);
      }
    } catch (_) {}

    try {
      await _webRTC.dispose();
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}

    _callState = CallState.ended;
    notifyListeners();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    _webRTC.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}

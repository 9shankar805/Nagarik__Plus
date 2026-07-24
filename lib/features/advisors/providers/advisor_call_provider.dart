import 'dart:async';
import 'package:flutter/material.dart';
import '../models/advisor_model.dart';
import '../models/consultation_booking_model.dart';

enum CallState {
  dialing,
  ringing,
  connected,
  ended,
}

class AdvisorCallProvider extends ChangeNotifier {
  final Advisor advisor;
  final ConsultationType callType;

  AdvisorCallProvider({
    required this.advisor,
    required this.callType,
  }) {
    _startCallFlow();
  }

  CallState _callState = CallState.dialing;
  int _durationSeconds = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOn = true;
  bool _isFrontCamera = true;

  CallState get callState => _callState;
  int get durationSeconds => _durationSeconds;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoOn => _isVideoOn;
  bool get isFrontCamera => _isFrontCamera;

  String get formattedDuration {
    final mins = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_durationSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _startCallFlow() {
    _callState = CallState.dialing;
    notifyListeners();

    _connectTimer = Timer(const Duration(seconds: 2), () {
      _callState = CallState.ringing;
      notifyListeners();

      _connectTimer = Timer(const Duration(seconds: 3), () {
        _callState = CallState.connected;
        notifyListeners();
        _startTimer();
      });
    });
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationSeconds++;
      notifyListeners();
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOn = !_isVideoOn;
    notifyListeners();
  }

  void switchCamera() {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  void endCall() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    _callState = CallState.ended;
    notifyListeners();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    super.dispose();
  }
}

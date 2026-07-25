import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/network/api_client.dart';

class WebRTCService {
  static const String _defaultTurnServer = 'nagarikplus.techprocod.com.np';
  static const String _defaultTurnPort = '3478';
  static const String _defaultTurnUsername = 'nagarikplus';
  static const String _defaultTurnCredential =
      '3ab3f55b3097002ccfa53e721a6430576293f43d8bc21638b85e472920edfcd8';

  static String get _turnServer => const String.fromEnvironment(
        'TURN_SERVER',
        defaultValue: _defaultTurnServer,
      );
  static String get _turnPort => const String.fromEnvironment(
        'TURN_PORT',
        defaultValue: _defaultTurnPort,
      );
  static String get _turnUsername => const String.fromEnvironment(
        'TURN_USERNAME',
        defaultValue: _defaultTurnUsername,
      );
  static String get _turnCredential => const String.fromEnvironment(
        'TURN_CREDENTIAL',
        defaultValue: _defaultTurnCredential,
      );

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final ApiClient _apiClient = ApiClient();

  Function(RTCVideoRenderer)? onLocalStream;
  Function(RTCVideoRenderer)? onRemoteStream;
  Function(String)? onCallEnded;
  Function(String)? onCallError;

  WebRTCService();

  Future<void> initializePeerConnection() async {
    final config = await _getIceServers();

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      _sendIceCandidate(candidate);
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {}
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onCallEnded?.call('Connection ended');
      }
    };
  }

  Future<Map<String, dynamic>> _getIceServers() async {
    try {
      final response = await _apiClient.get(
        '/calls/turn',
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      final data = response.data;
      if (data != null && data['iceServers'] != null) {
        return data;
      }
      onCallError?.call('Empty ICE servers response, using fallback');
    } catch (e) {
      onCallError?.call('Failed to get ICE servers: $e');
    }
    final turnHost = '$_turnServer:$_turnPort';
    return {
      'iceServers': [
        {
          'urls': 'stun:stun.l.google.com:19302',
        },
        {
          'urls': [
            'turn:$turnHost?transport=udp',
            'turn:$turnHost?transport=tcp',
          ],
          'username': _turnUsername,
          'credential': _turnCredential,
        },
      ],
    };
  }

  Future<MediaStream> getUserMedia(bool video) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': video
          ? <String, dynamic>{'facingMode': 'user'}
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      return _localStream!;
    } catch (e) {
      onCallError?.call('Failed to get user media: $e');
      rethrow;
    }
  }

  Future<void> createOffer() async {
    if (_peerConnection == null) return;

    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _sendOffer(offer);
    } catch (e) {
      onCallError?.call('Failed to create offer: $e');
    }
  }

  Future<void> createAnswer(RTCSessionDescription offer) async {
    if (_peerConnection == null) return;

    try {
      await _peerConnection!.setRemoteDescription(offer);
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _sendAnswer(answer);
    } catch (e) {
      onCallError?.call('Failed to create answer: $e');
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        onCallError?.call('Failed to add ICE candidate: $e');
      }
    }
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {}

  void _sendOffer(RTCSessionDescription offer) {}

  void _sendAnswer(RTCSessionDescription answer) {}

  Future<void> toggleAudio(bool enabled) async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = enabled;
    }
  }

  Future<void> toggleVideo(bool enabled) async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      videoTrack.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
  }
}

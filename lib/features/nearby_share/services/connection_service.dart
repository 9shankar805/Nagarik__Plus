import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../data/models/device_model.dart';

/// Connection states — named ShareConnectionState to avoid conflict with Flutter's ConnectionState
enum ShareConnectionState {
  idle,
  searching,
  connecting,
  connected,
  transferring,
  completed,
  failed,
  wifiDirectUnavailable, // Wi-Fi Direct not supported / permissions denied → trigger hotspot
  hotspotActive,         // hotspot created, waiting for receiver to join
}

/// Central service bridging Flutter ↔ Kotlin via MethodChannel + EventChannel
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  static const _methodChannel = MethodChannel('nagarik.share.connection');
  static const _eventChannel  = EventChannel('nagarik.share.events');

  final _stateCtrl   = StreamController<ShareConnectionState>.broadcast();
  final _devicesCtrl = StreamController<List<DeviceModel>>.broadcast();
  final _eventCtrl   = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ShareConnectionState>      get stateStream   => _stateCtrl.stream;
  Stream<List<DeviceModel>>         get devicesStream  => _devicesCtrl.stream;
  Stream<Map<String, dynamic>>      get eventStream    => _eventCtrl.stream;

  final List<DeviceModel> _devices = [];
  ShareConnectionState _state = ShareConnectionState.idle;
  StreamSubscription<dynamic>? _eventSub;
  String? _connectedIp;
  int _serverPort = 8888;

  ShareConnectionState get state       => _state;
  String?              get connectedIp => _connectedIp;
  int                  get serverPort  => _serverPort;

  Future<void> initialize() async {
    try {
      // iOS uses MultipeerConnectivity, Android uses Wi-Fi Direct/Hotspot
      if (Platform.isIOS) {
        await _methodChannel.invokeMethod<void>('initialize');
        _listenToNativeEvents();
      } else if (Platform.isAndroid) {
        await _methodChannel.invokeMethod<void>('initialize');
        _listenToNativeEvents();
      } else {
        throw Exception('Platform not supported for offline sharing');
      }
    } on PlatformException catch (e) {
      _setState(ShareConnectionState.failed);
      throw Exception('Failed to initialize: ${e.message}');
    }
  }

  void _listenToNativeEvents() {
    _eventSub?.cancel();
    _eventSub = _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .listen((raw) {
      final event = raw.cast<String, dynamic>();
      _handleEvent(event);
      _eventCtrl.add(event);
    }, onError: (_) {});
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    switch (type) {
      case 'deviceFound':
        final device = DeviceModel(
          id:             event['deviceId']       as String? ?? '',
          name:           event['deviceName']     as String? ?? 'Unknown Device',
          connectionType: event['connectionType'] as String? ?? 'Wi-Fi Direct',
          ipAddress:      event['ipAddress']      as String?,
        );
        if (!_devices.any((d) => d.id == device.id)) {
          _devices.add(device);
          _devicesCtrl.add(List.unmodifiable(_devices));
        }
        break;

      case 'deviceLost':
        final id = event['deviceId'] as String?;
        _devices.removeWhere((d) => d.id == id);
        _devicesCtrl.add(List.unmodifiable(_devices));
        break;

      case 'deviceConnected':
        _connectedIp = event['ipAddress'] as String?;
        _serverPort  = event['port'] as int? ?? 8888;
        _setState(ShareConnectionState.connected);
        final id  = event['deviceId'] as String?;
        final idx = _devices.indexWhere((d) => d.id == id);
        if (idx != -1) {
          _devices[idx] = _devices[idx].copyWith(
            isConnected: true,
            ipAddress:   _connectedIp,
          );
          _devicesCtrl.add(List.unmodifiable(_devices));
        }
        break;

      case 'connectionFailed':
        _setState(ShareConnectionState.failed);
        break;

      case 'disconnected':
        _connectedIp = null;
        _setState(ShareConnectionState.idle);
        _devices.clear();
        _devicesCtrl.add([]);
        break;

      case 'searching':
        _setState(ShareConnectionState.searching);
        break;

      case 'connecting':
        _setState(ShareConnectionState.connecting);
        break;

      // Wi-Fi Direct not available → signal hotspot fallback needed
      case 'wifiDirectUnavailable':
        _setState(ShareConnectionState.wifiDirectUnavailable);
        break;

      case 'hotspotCreated':
        _connectedIp = event['gatewayIp'] as String?;
        _serverPort  = event['port'] as int? ?? 8888;
        _setState(ShareConnectionState.hotspotActive);
        break;
    }
  }

  Future<void> discoverDevices() async {
    _devices.clear();
    _devicesCtrl.add([]);
    _setState(ShareConnectionState.searching);
    try {
      if (Platform.isIOS) {
        // iOS uses MultipeerConnectivity for discovery
        await _methodChannel.invokeMethod<void>('discoverDevices');
      } else if (Platform.isAndroid) {
        // Android uses Wi-Fi Direct + NSD/UDP discovery
        await _methodChannel.invokeMethod<void>('discoverDevices');
      }
    } on PlatformException catch (e) {
      _setState(ShareConnectionState.failed);
      throw Exception('Discovery failed: ${e.message}');
    }
  }

  Future<void> connectDevice(String deviceId) async {
    _setState(ShareConnectionState.connecting);
    try {
      await _methodChannel.invokeMethod<void>('connectDevice', {'deviceId': deviceId});
    } on PlatformException catch (e) {
      _setState(ShareConnectionState.failed);
      throw Exception('Connection failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createHotspot() async {
    try {
      if (Platform.isIOS) {
        // iOS doesn't support programmatic hotspot creation
        // Return manual hotspot info for user to set up
        final info = {
          'ssid': 'NagarikShare',
          'password': 'nagarik123',
          'gatewayIp': '192.168.43.1',
          'port': _serverPort,
        };
        _connectedIp = info['gatewayIp'] as String?;
        return info;
      } else if (Platform.isAndroid) {
        final result = await _methodChannel
            .invokeMethod<Map<Object?, Object?>>('createHotspot');
        final info   = result?.cast<String, dynamic>() ?? {};
        _connectedIp = info['gatewayIp'] as String?;
        _serverPort  = info['port'] as int? ?? 8888;
        return info;
      }
      return {};
    } on PlatformException catch (e) {
      throw Exception('Hotspot creation failed: ${e.message}');
    }
  }

  Future<bool> connectToWifi({required String ssid, required String password}) async {
    try {
      if (Platform.isIOS) {
        // iOS doesn't support programmatic Wi-Fi connection
        // User must manually connect to hotspot
        return false;
      } else if (Platform.isAndroid) {
        final result = await _methodChannel.invokeMethod<bool>('connectToWifi', {
          'ssid': ssid,
          'password': password,
        });
        return result ?? false;
      }
      return false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkHardwareState() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<Object?, Object?>>('checkHardwareState');
      return res?.cast<String, dynamic>() ?? {};
    } catch (_) { return {}; }
  }

  Future<bool> enableWifi() async {
    try { return await _methodChannel.invokeMethod<bool>('enableWifi') ?? false; }
    catch (_) { return false; }
  }

  Future<bool> enableBluetooth() async {
    try { return await _methodChannel.invokeMethod<bool>('enableBluetooth') ?? false; }
    catch (_) { return false; }
  }

  Future<bool> enableLocation() async {
    try { return await _methodChannel.invokeMethod<bool>('enableLocation') ?? false; }
    catch (_) { return false; }
  }

  Future<bool> requestSharePermissions() async {
    try { return await _methodChannel.invokeMethod<bool>('requestSharePermissions') ?? false; }
    catch (_) { return false; }
  }

  Future<String?> getApkPath(String packageName) async {
    try {
      return await _methodChannel.invokeMethod<String>('getApkPath', {
        'packageName': packageName,
      });
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> getConnectionInfo() async {
    try {
      final result = await _methodChannel
          .invokeMethod<Map<Object?, Object?>>('getConnectionInfo');
      return result?.cast<String, dynamic>() ?? {};
    } on PlatformException catch (_) {
      return {};
    }
  }

  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod<void>('disconnect');
    } on PlatformException catch (_) {}
    _connectedIp = null;
    _devices.clear();
    _devicesCtrl.add([]);
    _setState(ShareConnectionState.idle);
  }

  Future<void> stopDiscovery() async {
    try {
      await _methodChannel.invokeMethod<void>('stopDiscovery');
    } on PlatformException catch (_) {}
  }

  void _setState(ShareConnectionState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void dispose() {
    _eventSub?.cancel();
    _stateCtrl.close();
    _devicesCtrl.close();
    _eventCtrl.close();
  }
}

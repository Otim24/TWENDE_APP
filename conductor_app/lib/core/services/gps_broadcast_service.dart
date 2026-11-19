import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:twende_conductor_app/core/api/api_client.dart';
import 'package:twende_conductor_app/core/api/api_endpoints.dart';

class GpsCoordinate {
  final double lat;
  final double lng;
  final double speed;
  final double heading;

  const GpsCoordinate({
    required this.lat,
    required this.lng,
    this.speed = 62.0,
    this.heading = 0.0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
      };
}

class GpsBroadcastService extends ChangeNotifier {
  WebSocket? _socket;
  Timer? _broadcastTimer;
  int? _activeTripId;
  bool _isBroadcasting = false;
  String? _lastError;
  int _waypointIndex = 0;
  GpsCoordinate? _lastSentCoordinate;

  // Kampala -> Bombo -> Luwero -> Nakasongola -> Karuma -> Gulu highway corridor
  static const List<GpsCoordinate> _kampalaGuluCorridor = <GpsCoordinate>[
    GpsCoordinate(lat: 0.3476, lng: 32.5825, speed: 40.0, heading: 350.0),
    GpsCoordinate(lat: 0.4530, lng: 32.5360, speed: 58.0, heading: 345.0),
    GpsCoordinate(lat: 0.5833, lng: 32.5167, speed: 68.0, heading: 348.0),
    GpsCoordinate(lat: 0.8492, lng: 32.4956, speed: 72.0, heading: 352.0),
    GpsCoordinate(lat: 1.3089, lng: 32.4564, speed: 75.0, heading: 355.0),
    GpsCoordinate(lat: 1.6820, lng: 32.3350, speed: 70.0, heading: 342.0),
    GpsCoordinate(lat: 2.2490, lng: 32.2900, speed: 65.0, heading: 358.0),
    GpsCoordinate(lat: 2.7724, lng: 32.2881, speed: 35.0, heading: 0.0),
  ];

  bool get isBroadcasting => _isBroadcasting;
  int? get activeTripId => _activeTripId;
  String? get lastError => _lastError;
  GpsCoordinate? get lastSentCoordinate => _lastSentCoordinate;

  Future<bool> toggleBroadcast(int tripId) async {
    if (_isBroadcasting && _activeTripId == tripId) {
      await stopBroadcast();
      return false;
    }
    return startBroadcast(tripId);
  }

  Future<bool> startBroadcast(int tripId) async {
    await stopBroadcast();

    final String? token = AuthSession.token;
    if (token == null || token.isEmpty) {
      _lastError = 'Missing conductor authentication token.';
      notifyListeners();
      return false;
    }

    final String wsBase = ApiEndpoints.wsUrl.endsWith('/')
        ? ApiEndpoints.wsUrl.substring(0, ApiEndpoints.wsUrl.length - 1)
        : ApiEndpoints.wsUrl;
    final String url = '$wsBase/ws/$tripId?token=${Uri.encodeQueryComponent(token)}';

    try {
      _socket = await WebSocket.connect(url).timeout(
        const Duration(seconds: 8),
      );
      _activeTripId = tripId;
      _isBroadcasting = true;
      _lastError = null;
      _waypointIndex = 0;

      _socket!.listen(
        (dynamic message) {
          try {
            final dynamic decoded = jsonDecode(message.toString());
            if (decoded is Map && decoded['error'] != null) {
              _lastError = decoded['error'].toString();
              stopBroadcast();
            }
          } catch (_) {}
        },
        onError: (Object error) {
          _lastError = 'Live GPS disconnected.';
          stopBroadcast();
        },
        onDone: () {
          if (_isBroadcasting) {
            _isBroadcasting = false;
            notifyListeners();
          }
        },
      );

      _emitNextCoordinate();
      _broadcastTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _emitNextCoordinate(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Could not connect GPS stream to server.';
      _isBroadcasting = false;
      _activeTripId = null;
      notifyListeners();
      return false;
    }
  }

  void _emitNextCoordinate() {
    if (!_isBroadcasting || _socket == null) return;
    final GpsCoordinate coord =
        _kampalaGuluCorridor[_waypointIndex % _kampalaGuluCorridor.length];
    _waypointIndex = (_waypointIndex + 1) % _kampalaGuluCorridor.length;
    _lastSentCoordinate = coord;

    try {
      _socket!.add(jsonEncode(coord.toJson()));
      notifyListeners();
    } catch (_) {
      stopBroadcast();
    }
  }

  Future<void> stopBroadcast() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _isBroadcasting = false;
    _activeTripId = null;
    final WebSocket? oldSocket = _socket;
    _socket = null;
    try {
      await oldSocket?.close();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _broadcastTimer?.cancel();
    _socket?.close();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TrackingScreen({super.key, required this.tripData});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  MapLibreMapController? _mapController;
  WebSocketChannel? _channel;
  final LatLng _center = const LatLng(0.3476, 32.5825); // Kampala
  LatLng? _lastLocation;
  double? _lastSpeedKmh;
  bool _isConnected = false;

  int get _tripId =>
      int.tryParse((widget.tripData['id'] ?? '1').toString()) ?? 1;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final String wsBase = ApiEndpoints.wsUrl;
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsBase/ws/$_tripId'));
      _channel!.stream.listen(
        (message) {
          try {
            final dynamic data = jsonDecode(message.toString());
            if (data is Map && data['lat'] != null && data['lng'] != null) {
              final double? lat = double.tryParse(data['lat'].toString());
              final double? lng = double.tryParse(data['lng'].toString());
              final double? speed = data['speed'] != null
                  ? double.tryParse(data['speed'].toString())
                  : null;
              if (lat != null && lng != null) {
                final LatLng pos = LatLng(lat, lng);
                if (mounted) {
                  setState(() {
                    _isConnected = true;
                    _lastLocation = pos;
                    _lastSpeedKmh = speed;
                  });
                }
                _updateBusLocation(pos);
              }
            }
          } catch (_) {}
        },
        onError: (_) {
          if (mounted) setState(() => _isConnected = false);
        },
        onDone: () {
          if (mounted) setState(() => _isConnected = false);
        },
      );
    } catch (e) {
      debugPrint('WebSocket Error: $e');
    }
  }

  void _updateBusLocation(LatLng position) {
    if (_mapController != null) {
      _mapController!.clearCircles();
      _mapController!.addCircle(
        CircleOptions(
          geometry: position,
          circleColor: '#FF0000',
          circleRadius: 10,
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    if (_lastLocation != null) {
      _updateBusLocation(_lastLocation!);
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String routeName = (widget.tripData['route_name'] ??
            widget.tripData['route'] ??
            'Kampala - Gulu')
        .toString();
    final String busPlate =
        (widget.tripData['bus_plate'] ?? 'Twende Coach').toString();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            onMapCreated: _onMapCreated,
            styleString: 'https://demotiles.maplibre.org/style.json',
            myLocationEnabled: false,
          ),

          // Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
              ),
            ),
          ),

          // Bottom Telemetry Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Live Bus Tracking • $busPlate',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? AppTokens.success.withValues(alpha: 0.25)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isConnected ? 'LIVE GPS' : 'LISTENING',
                          style: GoogleFonts.poppins(
                            color: _isConnected
                                ? Colors.greenAccent
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    routeName,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lastLocation != null
                        ? 'Position: ${_lastLocation!.latitude.toStringAsFixed(4)}, ${_lastLocation!.longitude.toStringAsFixed(4)}${_lastSpeedKmh != null ? ' • ${_lastSpeedKmh!.toStringAsFixed(0)} km/h' : ''}'
                        : 'Waiting for conductor GPS stream on Trip #$_tripId...',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFeatures: AppTokens.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

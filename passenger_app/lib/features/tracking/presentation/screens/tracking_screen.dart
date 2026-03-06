import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TrackingScreen({super.key, required this.tripData});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  MaplibreMapController? _mapController;
  WebSocketChannel? _channel;
  
  // Default: Kampala
  final LatLng _center = const LatLng(0.3476, 32.5825); 

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }
  
  void _connectWebSocket() {
    // In real app, use environmental config for IP
    // Using 10.0.2.2 for Android Emulator to localhost, or 172.20.37.30 for device
    // For now assuming Android Emulator loopback or explicit IP
    const wsUrl = 'ws://172.20.37.30:8000/api/v1/tracking'; 
    final tripId = widget.tripData['id'] ?? 1;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/$tripId'));
      
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['lat'] != null && data['lng'] != null) {
          _updateBusLocation(LatLng(data['lat'], data['lng']));
        }
      });
    } catch (e) {
      debugPrint("WebSocket Error: $e");
    }
  }

  void _updateBusLocation(LatLng position) {
    if (_mapController != null) {
      _mapController!.addSymbol(SymbolOptions(
        geometry: position,
        iconImage: "bus-icon", // Ensure this icon is loaded
        iconSize: 1.5,
      ));
      
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
    
    // Add Route Polyline if available
    if (widget.tripData['route'] != null && widget.tripData['route']['polyline'] != null) {
      // Decode or use raw points. For MVP, assuming simple line
      // Real implementation would decode Polyline string
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MaplibreMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            onMapCreated: _onMapCreated,
            styleString: "https://demotiles.maplibre.org/style.json", // Free Demo Style
            // In prod: Use your own style URL (MapTiler/Stadia)
          ),
          
          // Custom Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Info Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    "Live Tracking",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bus is moving to next stop",
                    style: GoogleFonts.poppins(color: Colors.grey),
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

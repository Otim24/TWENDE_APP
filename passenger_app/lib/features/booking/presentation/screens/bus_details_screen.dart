import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BusDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> with SingleTickerProviderStateMixin {
  // Kampala Coordinates
  // Map & Tracking State
  MaplibreMapController? _mapController;
  WebSocketChannel? _channel;
  final LatLng _center = const LatLng(0.3476, 32.5825); // Default: Kampala

  // UI State
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late int _currentAvailableSeats;

  @override
  void initState() {
    super.initState();
    // Initialize available seats logic
    try {
      _currentAvailableSeats = int.parse(widget.bus['seats'].toString().split(' ')[0]); // Handle "4" or "4 seats"
    } catch (e) {
      _currentAvailableSeats = 4; // Fallback default
    }

    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _connectWebSocket();
  }

  void _connectWebSocket() {
    // Using dotenv for environmental config
    final wsUrl = dotenv.env['WS_URL'] ?? 'wss://127.0.0.1:8000/api/v1/tracking'; 
    final tripId = widget.bus['id'] ?? 1;
    
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

  void _onMapCreated(MaplibreMapController controller) async {
    _mapController = controller;
    // Add custom marker icon (using a simple circle or loading an asset)
    // For MVP transparency, we'll try to load a known asset or just use a default circle if possible.
    // Since we don't have a guaranteed bus asset loaded in the style, we'll try to add a CircleLayer instead for simplicity and reliability?
    // actually, addImage is better if we have an asset. Let's assume we don't and just use a Symbol with a fallback or Circle.
    // Changing to CircleLayer for maximum reliability without assets.
  }

  void _updateBusLocation(LatLng position) {
    if (_mapController != null) {
      _mapController!.clearCircles();
      _mapController!.addCircle(CircleOptions(
        geometry: position,
        circleColor: "#FF0000",
        circleRadius: 10,
        circleStrokeWidth: 2,
        circleStrokeColor: "#FFFFFF",
      ));
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Placeholder (Static Image - Google Style)
          // 1. Live Tracking Map Preview (MapLibre Entry)
          // 1. Embedded Map (MapLibre)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            width: double.infinity,
            child: MaplibreMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              onMapCreated: _onMapCreated,
              // Using Cartesian standard style (reliable for vector tiles)
              // Or use a raster style if vector fails on device
              styleString: "https://demotiles.maplibre.org/style.json",
              myLocationEnabled: false, // Don't use user location for now
              attributionButtonPosition: AttributionButtonPosition.topRight,
            ),
          ),

          // 2. Top Buttons (Back, Share, SOS)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.share, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Text("SOS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Draggable Scrollable Sheet (Details - Dark Theme)
          DraggableScrollableSheet(
            initialChildSize: 0.40, // Start lower so map is visible
            minChildSize: 0.20,     // Can be dragged down to see almost full map
            maxChildSize: 0.60,     // Max height is ~60% of screen (halfway + bit more)
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black, // Dark Wallet Style
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Stack(
                  children: [
                    // Content Column
                    ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Header Info
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeInfo("Departure", widget.bus['time'] ?? '07:00 AM'),
                              // Dotted Line
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 8, color: Colors.white54),
                                      const Expanded(child: Divider(color: Colors.white24)),
                                      Text("30 min", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                                      const Expanded(child: Divider(color: Colors.white24)),
                                      const Icon(Icons.location_on, size: 8, color: Colors.redAccent),
                                    ],
                                  ),
                                ),
                              ),
                              _buildTimeInfo("Arrival", "10:35 AM"), 
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        
                        // Seats & Price Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Pulsing "Book a Seat" Button
                              GestureDetector(
                                onTap: () async {
                                  // Navigate to Seat Selection
                                  context.push('/seat_selection', extra: widget.bus);
                                  

                                },
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced Padding
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.event_seat, color: Colors.redAccent, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Select Seats ($_currentAvailableSeats)", // Updated Text
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16), // Explicit spacing just in case
                              
                              Flexible(
                                child: Text(
                                  "Price: ${widget.bus['price']}",
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 30, color: Colors.white12),

                        // Timeline Content (4 Stops + Start/End)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimelineItem("Kampala Bus Terminal", "07:00 AM", isFirst: true),
                              _buildTimelineItem("Mukono Taxi Park", "07:45 AM"),
                              _buildTimelineItem("Jinja Bridge Stop", "08:30 AM"),
                              _buildTimelineItem("Iganga Main Stage", "09:15 AM", isCurrent: true),
                              _buildTimelineItem("Bugiri Town", "09:50 AM"),
                              _buildTimelineItem("Busia Border Post", "10:35 AM", isLast: true),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 100), // Space for bottom safe area
                      ],
                    ),


                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
        Text(time, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildTimelineItem(String station, String time, {bool isFirst = false, bool isLast = false, bool isCurrent = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Dots
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: const Color(0xFF7B1FA2))), // Deep Rich Purple Line
                Icon(
                  isFirst || isLast ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isCurrent ? Colors.white : const Color(0xFF7B1FA2), // Purple/White Dots
                  size: 16,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFF7B1FA2))), // Deep Rich Purple Line
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24), // Spacing between items
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // To fix overflow
                    child: Text(
                      station,
                      style: GoogleFonts.outfit(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: GoogleFonts.outfit(
                      color: isCurrent ? Colors.white : Colors.white54,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
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

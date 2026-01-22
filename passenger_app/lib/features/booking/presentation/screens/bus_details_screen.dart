
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> with SingleTickerProviderStateMixin {
  // Kampala Coordinates
  static const CameraPosition _kKampala = CameraPosition(
    target: LatLng(0.3476, 32.5825),
    zoom: 12.0,
  );

  late GoogleMapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Real-time State
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Placeholder (Static Image - Google Style)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            width: double.infinity,
            child: Image.asset(
              'assets/images/map_placeholder.png',
              fit: BoxFit.cover,
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
            initialChildSize: 0.60, // Increased to fit content without cutting off
            minChildSize: 0.60,
            maxChildSize: 0.75,     // Reduced further to keep map visible
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
                                  // Wait for result from Seat Selection
                                  final bookedCount = await context.push<int>('/seat_selection');
                                  
                                  if (bookedCount != null && bookedCount > 0) {
                                    setState(() {
                                      _currentAvailableSeats = (_currentAvailableSeats - bookedCount).clamp(0, 50);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Booked $bookedCount seats! ($_currentAvailableSeats remaining)", style: GoogleFonts.outfit())),
                                    );
                                  }
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
                                        const Icon(Icons.touch_app_rounded, color: Colors.redAccent, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Book a Seat ($_currentAvailableSeats)", // New Text Format
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

                    // "Buy Ticket" Button - Top Right of the Sheet (Fixed Overlay)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Payment Flow
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Payment flow starting...", style: GoogleFonts.outfit())),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)], // Purple Theme
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A148C).withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Buy Ticket",
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
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

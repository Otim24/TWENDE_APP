import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:twende_conductor_app/features/manifest/presentation/screens/trip_dashboard_screen.dart';
import 'package:twende_conductor_app/features/scan/presentation/screens/scanner_screen.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _trips = [];
  String? _error;

  // Assuming same LAN IP
  final String _baseUrl = 'http://192.168.100.19:8000/api/v1/conductor';

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final dio = Dio();
      final response = await dio.get('$_baseUrl/trips');
      
      if (response.statusCode == 200) {
        setState(() {
          _trips = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _error = "Failed to load trips. Check connection.";
           _isLoading = false;
        });
      }
      print("Error loading trips: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B1FA2)))
                    : _error != null 
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: GoogleFonts.poppins(color: Colors.red)),
                              TextButton(onPressed: _fetchTrips, child: const Text("Retry", style: TextStyle(color: Colors.white)))
                            ],
                          ))
                        : _trips.isEmpty
                            ? Center(child: Text("No scheduled trips found.", style: GoogleFonts.poppins(color: Colors.white70)))
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for Pill
                                itemCount: _trips.length,
                                itemBuilder: (context, index) {
                                  return _buildTripCard(_trips[index]);
                                },
                              ),
                ),
              ],
            ),
          ),

          // 2. Floating Pill Navigation
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _buildNavigationPill(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Overlapping Profiles
          SizedBox(
            width: 70,
            height: 40,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF7B1FA2), // Purple for Conductor
                      child: Icon(Icons.confirmation_number, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Twende Crew",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "My Trips",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    double occupancy = trip['occupied_seats'] / trip['total_seats'];
    Color statusColor = occupancy > 0.8 ? Colors.redAccent : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDashboardScreen(
                  tripId: trip['id'],
                  tripName: trip['route_name'],
                  tripStats: "${trip['occupied_seats']}/${trip['total_seats']}",
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip['route_name'] ?? 'Unknown Route',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip['status'] ?? 'SCHEDULED',
                        style: GoogleFonts.poppins(color: const Color(0xFFE040FB), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(trip['departure_time'] ?? '', style: GoogleFonts.poppins(color: Colors.grey[400])),
                    const Spacer(),
                    Icon(Icons.event_seat, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      "${trip['occupied_seats']}/${trip['total_seats']}",
                      style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Dark Grey Pill
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HOME (Active)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_filled, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text("Home", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // QR (Action)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerScreen())
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text("Scan", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

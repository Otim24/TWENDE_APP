import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/conductor_seat_grid.dart';
import 'package:twende_conductor_app/features/scan/presentation/screens/scanner_screen.dart';

class TripDashboardScreen extends StatefulWidget {
  final int tripId;
  final String tripName; // e.g., Kampala - Gulu
  final String tripStats; // e.g., 34/60

  const TripDashboardScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.tripStats,
  });

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _manifest = [];
  String? _error;

  // Assuming same LAN IP
  final String _baseUrl = 'http://172.20.11.181:8000/api/v1/conductor';

  @override
  void initState() {
    super.initState();
    _fetchManifest();
  }

  Future<void> _fetchManifest() async {
    setState(() {
       _isLoading = true;
       _error = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get('$_baseUrl/trips/${widget.tripId}/manifest');
      
      if (response.statusCode == 200) {
        setState(() {
          _manifest = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _error = "Failed to load manifest.";
           _isLoading = false;
        });
      }
      print("Error loading manifest: $e");
    }
  }

  void _handleSeatTap(Map<String, dynamic> seatData) {
    // Show Passenger Details if Booked/Occupied
    final status = seatData['status'];
    if (status == 'BOOKED' || status == 'OCCUPIED') {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent, // Transparent to show custom container
        isScrollControlled: true,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, 
                    height: 4, 
                    decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${seatData['seat_number']}",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE040FB)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seatData['passenger_name'] ?? "Unknown Passenger",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            status,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: status == 'OCCUPIED' ? Colors.green : Colors.purpleAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Info Grid
                Row(
                  children: [
                    Expanded(child: _infoCard(Icons.phone, "Phone", seatData['passenger_phone'] ?? "N/A")),
                    const SizedBox(width: 12),
                    Expanded(child: _infoCard(Icons.airplane_ticket, "Ticket", "Standard")),
                  ],
                ),
                
                const SizedBox(height: 32),

                // Actions
                if (status == 'BOOKED')
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton.icon(
                       icon: const Icon(Icons.qr_code_scanner),
                       label: const Text("Scan to Verify"),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF7B1FA2),
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 0,
                       ),
                       onPressed: () {
                         Navigator.pop(context); // Close modal
                         _openScanner();
                       },
                     ),
                   ),
                   
                if (status == 'OCCUPIED')
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton.icon(
                       icon: const Icon(Icons.check_circle_outline),
                       label: const Text("Verified Passenger"),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green.withOpacity(0.2),
                         foregroundColor: Colors.green,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 0,
                       ),
                       onPressed: () { Navigator.pop(context); },
                     ),
                   )
              ],
            ),
          );
        }
      );
    } else {
      // Available - Sell Seat
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("Manual Ticket Sale coming soon!", style: GoogleFonts.poppins(color: Colors.white)),
           backgroundColor: Colors.grey[900],
           behavior: SnackBarBehavior.floating,
         )
       );
    }
  }
  
  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white38)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen())
    );
    // Refresh manifest on return
    _fetchManifest();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    int total = _manifest.length; // Approximate from manifest items
    int occupied = _manifest.where((s) => s['status'] == 'OCCUPIED' || s['status'] == 'BOOKED').length;
    // Fallback if manifest empty but we have stats string "34/60"
    if (total == 0 && widget.tripStats.contains("/")) {
      var parts = widget.tripStats.split("/");
      occupied = int.tryParse(parts[0]) ?? 0;
      total = int.tryParse(parts[1]) ?? 60;
    }
    double progress = total > 0 ? occupied / total : 0.0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A148C), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.tripName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Balance back button
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Occupancy Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Occupancy", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      Text("$occupied/$total Seats", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                        progress > 0.9 ? Colors.redAccent : const Color(0xFF7B1FA2)
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legendItem(const Color(0xFF7B1FA2), "Booked"),
                      _legendItem(Colors.green, "Boarded"),
                      _legendItem(Colors.transparent, "Empty", border: true),
                    ],
                  ),
                ],
              ),
            ),
            
            // Grid Body
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B1FA2)))
                  : _error != null 
                      ? Center(child: TextButton(onPressed: _fetchManifest, child: Text(_error!, style: const TextStyle(color: Colors.red))))
                      : ConductorSeatGrid(
                          manifest: _manifest,
                          onSeatTap: _handleSeatTap,
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: const Color(0xFF7B1FA2),
        elevation: 10,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
  
  Widget _legendItem(Color color, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: border ? Border.all(color: Colors.white54) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

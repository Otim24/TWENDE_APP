import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultsScreen extends StatelessWidget {
  final String fromLocation;
  final String toLocation;

  const SearchResultsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              "Select Bus",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              "$fromLocation ➔ $toLocation",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildBusTicketCard(
            companyName: "Larem Safaris",
            departureTime: "07:00 AM",
            price: "35,000 UGX",
            seatsLeft: 4,
            color: Colors.orange.shade800,
          ),
          _buildBusTicketCard(
            companyName: "Makome Bus",
            departureTime: "08:30 AM",
            price: "30,000 UGX",
            seatsLeft: 12,
            color: Colors.blue.shade800,
          ),
          _buildBusTicketCard(
            companyName: "White Star",
            departureTime: "10:00 AM",
            price: "32,000 UGX",
            seatsLeft: 8,
            color: Colors.green.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildBusTicketCard({
    required String companyName,
    required String departureTime,
    required String price,
    required int seatsLeft,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Charcoal
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.directions_bus_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Direct • AC",
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                price,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF4A148C), // Brand Purple
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBadge(Icons.access_time_rounded, departureTime),
              _buildInfoBadge(Icons.event_seat_rounded, "$seatsLeft Seats"),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A148C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "Select Seat",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

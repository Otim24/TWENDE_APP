import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/conductor_seat_grid.dart';

class SeatMapTab extends StatelessWidget {
  final List<dynamic> manifest;
  final Function(Map<String, dynamic>) onSeatTap;

  const SeatMapTab({
    super.key,
    required this.manifest,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    int occupied = manifest.where((s) => s['status'] == 'OCCUPIED' || s['status'] == 'BOOKED').length;
    int available = 60 - occupied; // Assuming 60 for MVP

    return Column(
      children: [
        // Header / Search
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              decoration: InputDecoration(
                icon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Search Ticket / Name / Phone",
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        // Grid
        Expanded(
          child: ConductorSeatGrid(
            manifest: manifest,
            onSeatTap: onSeatTap,
          ),
        ),

        // Footer Stats
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _legendItem(Colors.green, "Available: $available"), // In design, Green is Available?? No, typically White/Grey is available. Design shows "Seats Available: 7" with Green Check.
                  _legendItem(Colors.red, "Seats Occupied: $occupied"),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {}, // Continue?
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Continue", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 80), // Space for Pill
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

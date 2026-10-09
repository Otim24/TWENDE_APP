import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConductorSeatGrid extends StatelessWidget {
  final List<dynamic> manifest; // List of ManifestItem maps
  final Function(Map<String, dynamic>) onSeatTap;

  const ConductorSeatGrid({
    super.key,
    required this.manifest,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    if (manifest.isEmpty) {
      return const Center(child: Text("No seat data available"));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: manifest.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12, // Increased spacing
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = manifest[index];
          // status: AVAILABLE, BOOKED, OCCUPIED
          final status = item['status'] as String;
          final seatNum = item['seat_number'] as int;

          return GestureDetector(
            onTap: () => onSeatTap(item),
            child: _buildSeatItem(seatNum, status),
          );
        },
      ),
    );
  }

  Widget _buildSeatItem(int seatNumber, String status) {
    Color bg;
    Border? border;
    IconData icon = Icons.event_seat;
    Color contentColor = Colors.white54; // Default text color

    switch (status) {
      case 'OCCUPIED':
        bg = Colors.green;
        contentColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'BOOKED':
        bg = const Color(0xFF7B1FA2); // Imperial Purple
        contentColor = Colors.white;
        break;
      case 'AVAILABLE':
      default:
        bg = const Color(0xFF1E1E1E); // Dark Grey
        border = Border.all(color: Colors.white24);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12), // Softer corners
        border: border,
        boxShadow: status != 'AVAILABLE' 
          ? [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))] 
          : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: contentColor.withOpacity(0.3), // Faint background icon
              size: 28,
            ),
          ),
          Center(
            child: Text(
              "$seatNumber",
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: contentColor, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class ConductorSeatGrid extends StatelessWidget {
  final List<dynamic> manifest;
  final void Function(Map<String, dynamic>) onSeatTap;

  const ConductorSeatGrid({
    super.key,
    required this.manifest,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    if (manifest.isEmpty) {
      return Center(
        child: Text(
          'No seat manifest available for this trip.',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: manifest.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> item =
              Map<String, dynamic>.from(manifest[index] as Map);
          final String status = AppTokens.normalizeSeatStatus(item['status']);
          final int seatNum = (item['seat_number'] as num?)?.toInt() ?? (index + 1);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSeatTap(item),
              child: _buildSeatItem(seatNum, status),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeatItem(int seatNumber, String status) {
    Color bg;
    Border? border;
    IconData icon = Icons.event_seat_rounded;
    Color contentColor = Colors.white70;

    switch (status) {
      case 'OCCUPIED':
        bg = AppTokens.occupied;
        contentColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case 'BOOKED':
        bg = AppTokens.booked;
        contentColor = Colors.white;
        icon = Icons.person_pin_circle_rounded;
        break;
      case 'AVAILABLE':
      default:
        bg = AppTokens.available;
        border = Border.all(color: Colors.white24);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Icon(
              icon,
              color: contentColor.withValues(alpha: 0.22),
              size: 28,
            ),
          ),
          Center(
            child: Text(
              '$seatNumber',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: contentColor,
                fontWeight: FontWeight.bold,
                fontFeatures: AppTokens.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/conductor_seat_grid.dart';

class SeatMapTab extends StatelessWidget {
  final List<dynamic> manifest;
  final void Function(Map<String, dynamic>) onSeatTap;

  const SeatMapTab({
    super.key,
    required this.manifest,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    final int availableCount = manifest
        .where((dynamic s) => AppTokens.normalizeSeatStatus(s['status']) == 'AVAILABLE')
        .length;
    final int bookedCount = manifest
        .where((dynamic s) => AppTokens.normalizeSeatStatus(s['status']) == 'BOOKED')
        .length;
    final int boardedCount = manifest
        .where((dynamic s) => AppTokens.normalizeSeatStatus(s['status']) == 'OCCUPIED')
        .length;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTokens.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _legendItem(
                  AppTokens.available,
                  'Free: $availableCount',
                  hasBorder: true,
                ),
                _legendItem(
                  AppTokens.booked,
                  'Booked: $bookedCount',
                ),
                _legendItem(
                  AppTokens.occupied,
                  'Boarded: $boardedCount',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Tap an empty seat to sell a walk-in ticket, or tap a booked seat to inspect & board.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ConductorSeatGrid(
            manifest: manifest,
            onSeatTap: onSeatTap,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.white38) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: AppTokens.tabularFigures,
          ),
        ),
      ],
    );
  }
}

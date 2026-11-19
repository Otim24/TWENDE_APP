import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/services/gps_broadcast_service.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, dynamic>? trip;
  final List<dynamic> manifest;
  final bool isBroadcastingGps;
  final GpsCoordinate? lastCoordinate;
  final VoidCallback onToggleTripGps;
  final void Function(int) onSwitchTab;
  final VoidCallback onManualEntry;
  final VoidCallback onSellTicket;

  const DashboardTab({
    super.key,
    required this.trip,
    required this.manifest,
    required this.isBroadcastingGps,
    this.lastCoordinate,
    required this.onToggleTripGps,
    required this.onSwitchTab,
    required this.onManualEntry,
    required this.onSellTicket,
  });

  String _formatDepartureTime(dynamic raw) {
    final String value = (raw ?? '').toString().trim();
    if (value.isEmpty) return 'Scheduled';
    try {
      final DateTime dt = DateTime.parse(value).toLocal();
      final int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final String min = dt.minute.toString().padLeft(2, '0');
      return '$hour12:$min $ampm';
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int total = (trip?['total_seats'] as num?)?.toInt() ??
        (manifest.isNotEmpty ? manifest.length : 60);
    final int bookedCount = manifest
        .where((dynamic s) => AppTokens.normalizeSeatStatus(s['status']) == 'BOOKED')
        .length;
    final int boardedCount = manifest
        .where((dynamic s) => AppTokens.normalizeSeatStatus(s['status']) == 'OCCUPIED')
        .length;
    final int totalSold = manifest.isNotEmpty
        ? (bookedCount + boardedCount)
        : ((trip?['occupied_seats'] as num?)?.toInt() ?? 0);
    final double occupancy = total > 0 ? (totalSold / total).clamp(0.0, 1.0) : 0.0;

    final String routeName = (trip?['route_name'] ?? 'Scheduled Route').toString();
    final List<String> routeParts = routeName.contains(' - ')
        ? routeName.split(' - ')
        : <String>[routeName];
    final String busPlate = (trip?['bus_plate'] ?? 'Twende Bus').toString();
    final String formattedPrice = AppTokens.formatUgx(trip?['price'] ?? 30000);
    final String formattedTime = _formatDepartureTime(trip?['departure_time']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Today's Shift",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isBroadcastingGps
                            ? AppTokens.success.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isBroadcastingGps
                              ? AppTokens.success
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            isBroadcastingGps
                                ? Icons.sensors_rounded
                                : Icons.schedule_rounded,
                            size: 14,
                            color: isBroadcastingGps
                                ? Colors.greenAccent
                                : Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBroadcastingGps ? 'LIVE GPS ON' : 'READY',
                            style: GoogleFonts.poppins(
                              color: isBroadcastingGps
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (routeParts.length >= 2)
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          routeParts[0].trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTokens.accent,
                          size: 22,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          routeParts.sublist(1).join(' - ').trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    routeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Bus: $busPlate • Dep: $formattedTime • $formattedPrice',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFeatures: AppTokens.tabularFigures,
                  ),
                ),
                if (isBroadcastingGps && lastCoordinate != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'GPS: ${lastCoordinate!.lat.toStringAsFixed(4)}, ${lastCoordinate!.lng.toStringAsFixed(4)} (${lastCoordinate!.speed.toStringAsFixed(0)} km/h)',
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontFeatures: AppTokens.tabularFigures,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _statChip(
                        icon: Icons.event_seat_rounded,
                        iconColor: AppTokens.accent,
                        label: '$totalSold/$total Sold',
                        bgColor: AppTokens.primaryDark.withValues(alpha: 0.55),
                        borderColor: AppTokens.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statChip(
                        icon: Icons.verified_user_rounded,
                        iconColor: Colors.greenAccent,
                        label: '$boardedCount Boarded',
                        bgColor: AppTokens.surfaceElevated,
                        borderColor: AppTokens.border,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statChip(
                        icon: Icons.pie_chart_rounded,
                        iconColor: occupancy > 0.85
                            ? Colors.orangeAccent
                            : Colors.cyanAccent,
                        label: '${(occupancy * 100).round()}% Full',
                        bgColor: AppTokens.surfaceElevated,
                        borderColor: AppTokens.border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onToggleTripGps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBroadcastingGps
                          ? AppTokens.danger
                          : AppTokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      isBroadcastingGps
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_fill_rounded,
                    ),
                    label: Text(
                      isBroadcastingGps
                          ? 'Stop GPS Broadcast'
                          : 'Start Trip & Broadcast GPS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildActionButton(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Sell Ticket',
                  onTap: onSellTicket,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.fact_check_outlined,
                  label: 'Manual Board',
                  onTap: onManualEntry,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildActionButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Seat Map',
                  onTap: () => onSwitchTab(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR',
                  onTap: () => onSwitchTab(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFeatures: AppTokens.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: AppTokens.accent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

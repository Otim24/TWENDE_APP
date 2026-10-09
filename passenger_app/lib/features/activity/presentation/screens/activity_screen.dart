
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _isUpcoming = true;

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return "Today";
      }
      
      final tomorrow = now.add(const Duration(days: 1));
      if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
        return "Tomorrow";
      }
      
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${date.day} ${months[date.month - 1]}";
    } catch (e) {
      return isoString;
    }
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(isoString);
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      final min = date.minute.toString().padLeft(2, '0');
      return "$hour:$min $ampm";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(myTripsProvider);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
             Text(
              "Your Activity",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Toggle Switch
            GlassContainer(
              padding: const EdgeInsets.all(4),
              borderRadius: 30,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUpcoming = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isUpcoming ? const Color(0xFF4A148C) : Colors.transparent, // Active Purple
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            "Upcoming",
                            style: GoogleFonts.poppins(
                              color: _isUpcoming ? Colors.white : Colors.white54,
                              fontWeight: _isUpcoming ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUpcoming = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isUpcoming ? const Color(0xFF4A148C) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            "History",
                            style: GoogleFonts.poppins(
                              color: !_isUpcoming ? Colors.white : Colors.white54,
                              fontWeight: !_isUpcoming ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // List
            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  final filteredTrips = trips.where((t) {
                    try {
                      final tripData = t['trip'];
                      final deptTime = DateTime.parse(tripData['departure_time']);
                      if (_isUpcoming) {
                        return deptTime.isAfter(DateTime.now());
                      } else {
                        return deptTime.isBefore(DateTime.now());
                      }
                    } catch (e) {
                      return true;
                    }
                  }).toList();

                  if (filteredTrips.isEmpty) {
                    return Center(
                      child: Text(
                        _isUpcoming ? "No upcoming trips." : "No past trips.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final booking = filteredTrips[index];
                      final trip = booking['trip'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildTripTicket(
                          date: _formatDate(trip['departure_time'] ?? ""),
                          time: _formatTime(trip['departure_time'] ?? ""),
                          route: "${trip['origin']} - ${trip['destination']}",
                          price: "UGX ${trip['price']}",
                          isUpcoming: _isUpcoming,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
                error: (error, stack) => Center(
                  child: Text("Error: $error", style: GoogleFonts.poppins(color: Colors.redAccent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTicket({
    required String date,
    required String time,
    required String route,
    required String price,
    required bool isUpcoming,
  }) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date & Time Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4A148C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Vertical Divider
            Container(
              width: 1,
              height: 40,
              color: Colors.white24,
            ),
            const SizedBox(width: 16),

            // Route Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: GoogleFonts.spaceMono(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Status Icon or Arrow
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

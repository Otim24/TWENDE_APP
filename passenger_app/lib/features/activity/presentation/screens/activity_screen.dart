
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isUpcoming = true;

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                children: [
                  _buildTripTicket(
                    date: "Tomorrow",
                    time: "8:00 AM",
                    route: "Kampala - Gulu",
                    price: "UGX 35,000",
                    isUpcoming: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTripTicket(
                    date: "Today",
                    time: "2:00 PM",
                    route: "Kampala - Jinja",
                    price: "UGX 15,000",
                    isUpcoming: true,
                  ),
                ],
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

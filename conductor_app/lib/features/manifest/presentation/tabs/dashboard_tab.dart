import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, dynamic>? trip;
  final VoidCallback onStartTrip;
  final Function(int) onSwitchTab;
  final VoidCallback onManualEntry;
  final VoidCallback onSellTicket;

  const DashboardTab({
    super.key,
    required this.trip,
    required this.onStartTrip,
    required this.onSwitchTab,
    required this.onManualEntry,
    required this.onSellTicket,
  });

  @override
  Widget build(BuildContext context) {
    // Safe Layout
    final int total = trip?['total_seats'] ?? 60;
    final int occupied = trip?['occupied_seats'] ?? 0;
    final double occupancy = total > 0 ? occupied / total : 0.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trip Card (Glassmorphism)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Dark Glassmorphism
                color: const Color(0xFF1E1E1E), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                   BoxShadow(color: const Color(0xFF7B1FA2).withOpacity(0.1), blurRadius: 20, spreadRadius: -5)
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Trip",
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((trip?['route_name'] ?? '').contains(' - ')) ...[
                        Text(
                          (trip?['route_name'] ?? '').split(' - ')[0],
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, color: Color(0xFFE040FB), size: 24), // Purple Accent
                        ),
                        Text(
                          (trip?['route_name'] ?? '').split(' - ')[1],
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ] else 
                        Text(
                          trip?['route_name'] ?? 'Kampala - Lira', // Fallback
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bus: ${trip?['bus_plate'] ?? 'UAX 345F'} • Departure: ${trip?['departure_time'] ?? '10:00 AM'}",
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A148C), // Dark Purple
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_seat, color: Color(0xFFE040FB), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "$occupied Booked",
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05), // Glass
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pie_chart, color: occupancy > 0.8 ? Colors.redAccent : Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "${(occupancy * 100).toInt()}% Full",
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Start Trip Button (Purple Gradient)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)], // Purple Gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30), // Rounded pill
                      boxShadow: [
                         BoxShadow(color: const Color(0xFF7B1FA2).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: ElevatedButton(
                      onPressed: onStartTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        "Start Trip",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Side-by-Side Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_to_photos_outlined,
                    label: "Sell Ticket",
                    onTap: onSellTicket,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit_note,
                    label: "Manual Entry",
                    onTap: onManualEntry,
                  ),
                ),
              ],
            ),
            
            // Explicit Bottom Spacer to clear Navigation Pill
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(30), // Pill Shape
        border: Border.all(color: Colors.white10),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFE040FB), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Dark Glassmorphism Tile
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased padding
            child: Row(
               children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B1FA2).withOpacity(0.2), // Purple Tint
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFFE040FB), size: 24), // Bright Purple Icon
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
               ],
            ),
          ),
        ),
      ),
    );
  }
}

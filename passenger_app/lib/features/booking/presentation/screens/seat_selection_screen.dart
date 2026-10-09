
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> busDetails;

  const SeatSelectionScreen({super.key, required this.busDetails});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // Mock Seat Data
  // 0 = Available, 1 = Booked, 2 = Selected
  final List<int> _seats = List.generate(40, (index) {
    if (index % 5 == 0) return 1; // Random booked seats
    return 0;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Select Seats",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Bus Front / Driver
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              width: double.infinity,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text("Driver / Front", style: GoogleFonts.outfit(color: Colors.white54)),
              ),
            ),
          ),

          // 2. Seat Grid
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white24),
                  right: BorderSide(color: Colors.white24),
                ),
              ),
              child: GridView.builder(
                itemCount: _seats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 2 - Aisle - 2 (Handled logic below)
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  // Add gap for aisle (Column index 2 is aisle)
                  // Visual trick: We actually use 5 columns? Or just visual padding.
                  // Simpler: Just standard 4 col grid for now.
                  
                  return GestureDetector(
                    onTap: () {
                      if (_seats[index] == 1) return; // Booked
                      setState(() {
                        if (_seats[index] == 2) {
                          _seats[index] = 0; // Deselect
                        } else {
                          _seats[index] = 2; // Select
                        }
                      });
                    },
                    child: _buildSeatItem(_seats[index]),
                  );
                },
              ),
            ),
          ),

          // 3. Legend & Checkout
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.white24, "Available"),
                    _buildLegendItem(const Color(0xFFE65100), "Selected"), // Orange/Brand
                    _buildLegendItem(Colors.redAccent.withOpacity(0.3), "Booked"),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Calculate selected seats (Status 2)
                      int selectedCount = _seats.where((s) => s == 2).length;
                      
                      if (selectedCount == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select at least one seat")),
                        );
                        return;
                      }

                      context.push('/payment', extra: {
                        'busDetails': widget.busDetails,
                        'seatCount': selectedCount,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2), // Purple Theme
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Proceed to Pay",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(int status) {
    Color color;
    if (status == 1) {
      color = Colors.redAccent.withOpacity(0.3); // Booked
    } else if (status == 2) {
      color = const Color(0xFFE65100); // Selected
    } else {
      color = Colors.white24; // Available
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: status == 0 ? Border.all(color: Colors.white38) : null,
      ),
      child: Icon(
        Icons.event_seat,
        color: status == 2 ? Colors.white : Colors.white54,
        size: 20,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.outfit(color: Colors.white70)),
      ],
    );
  }
}

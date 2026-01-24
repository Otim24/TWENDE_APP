import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class SeatSelectionModal extends StatefulWidget {
  final List<int> bookedSeats;
  final int totalSeats;
  final int? initiallySelectedSeat;

  const SeatSelectionModal({
    super.key,
    required this.bookedSeats,
    this.totalSeats = 40,
    this.initiallySelectedSeat,
  });

  @override
  State<SeatSelectionModal> createState() => _SeatSelectionModalState();
}

class _SeatSelectionModalState extends State<SeatSelectionModal> {
  int? _selectedSeat;

  @override
  void initState() {
    super.initState();
    _selectedSeat = widget.initiallySelectedSeat;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blur Effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        
        // Modal Content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Dark Theme
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Seat",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                // Driver Indicator
                Container(
                  width: 200,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text("FRONT / DRIVER", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                ),

                // Seat Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      itemCount: widget.totalSeats,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final seatNum = index + 1;
                        final isBooked = widget.bookedSeats.contains(seatNum);
                        final isSelected = _selectedSeat == seatNum;

                        return GestureDetector(
                          onTap: isBooked ? null : () {
                            setState(() {
                              _selectedSeat = isSelected ? null : seatNum;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isBooked 
                                ? const Color(0xFFB71C1C).withOpacity(0.3) // Red for Booked
                                : isSelected 
                                  ? const Color(0xFF7B1FA2) // Purple for Selected
                                  : const Color(0xFF2C2C2C), // Dark Grey for Available
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                  ? const Color(0xFFEA80FC) 
                                  : Colors.white10,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: const Color(0xFF7B1FA2).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ] : [],
                            ),
                            alignment: Alignment.center,
                            child: isBooked 
                              ? const Icon(Icons.close, color: Colors.white24, size: 20)
                              : Text(
                                  "$seatNum",
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legendItem(const Color(0xFF2C2C2C), "Available"),
                      _legendItem(const Color(0xFF7B1FA2), "Selected"),
                      _legendItem(const Color(0xFFB71C1C).withOpacity(0.3), "Booked"),
                    ],
                  ),
                ),

                // Confirm Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedSeat == null 
                        ? null 
                        : () => Navigator.pop(context, _selectedSeat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1FA2),
                        disabledBackgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Confirm Selection",
                        style: GoogleFonts.poppins(
                          color: _selectedSeat == null ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

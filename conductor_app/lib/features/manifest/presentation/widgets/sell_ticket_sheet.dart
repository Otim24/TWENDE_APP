import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'seat_selection_modal.dart';
import '../screens/conductor_ticket_receipt_screen.dart';

class SellTicketSheet extends StatefulWidget {
  final Map<String, dynamic>? trip;
  final List<dynamic> manifest; // To know occupied seats
  final VoidCallback onSuccess;

  const SellTicketSheet({
    super.key,
    required this.trip,
    required this.manifest,
    required this.onSuccess,
  });

  @override
  State<SellTicketSheet> createState() => _SellTicketSheetState();
}

class _SellTicketSheetState extends State<SellTicketSheet> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedSeat;
  String _paymentMethod = "CASH";
  bool _isLoading = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  List<int> _availableSeats = [];
  
  // LAN Url
  final String _baseUrl = 'http://172.20.11.181:8000/api/v1/conductor';

  @override
  void initState() {
    super.initState();
    _calculateAvailableSeats();
    
    // Pulse Animation for Confirm Button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Fast subtle pulse
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  void _calculateAvailableSeats() {
    // 60 seats total
    Set<int> occupied = {};
    for (var m in widget.manifest) {
      if (m['status'] != 'AVAILABLE') {
        occupied.add(m['seat_number']);
      }
    }
    
    _availableSeats = [];
    for (int i = 1; i <= 60; i++) {
      if (!occupied.contains(i)) {
        _availableSeats.add(i);
      }
    }
  }

  Future<void> _processSale() async {
    if (_selectedSeat == null || _nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final response = await dio.post('$_baseUrl/sell_ticket', data: {
        'trip_id': widget.trip?['id'] ?? 999, // Fallback for Demo
        'seat_number': _selectedSeat,
        'passenger_name': _nameController.text,
        'passenger_phone': _phoneController.text,
        'payment_method': _paymentMethod
      });
      
      if (response.data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
        
        // Show Receipt Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConductorTicketReceiptScreen(
              ticketDetails: {
                'trip_id': widget.trip?['id'] ?? 999,
                'passenger_name': _nameController.text,
                'seat_number': _selectedSeat,
                'route_name': widget.trip?['route']?['name'] ?? 'Kampala - Busia',
                'travel_date': 'Today', // Would come from real trip data
                'price': widget.trip?['price'] ?? 35000,
              }
            )
          )
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Price from Trip or Default
    final double price = (widget.trip?['price'] ?? 35000).toDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          Text("Sell New Ticket", style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Walk-in Passenger", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seat Selection
                  Text("Select Seat", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                    // New Pill Shaped Seat Selector
                    GestureDetector(
                      onTap: () async {
                        // Calculate booked seats (assuming 60 total seats to match _calculateAvailableSeats)
                        // If _availableSeats contains available ones, then (1..60) - _availableSeats = booked
                        final allSeats = List.generate(60, (i) => i + 1);
                        final bookedSeats = allSeats.where((s) => !_availableSeats.contains(s)).toList();

                        final result = await showGeneralDialog<int>(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "Seat Selection",
                          barrierColor: Colors.black.withOpacity(0.6), // Background dim
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (ctx, anim1, anim2) {
                            return SeatSelectionModal(
                              bookedSeats: bookedSeats,
                              totalSeats: 60,
                              initiallySelectedSeat: _selectedSeat,
                            );
                          },
                          transitionBuilder: (ctx, anim1, anim2, child) {
                            return FadeTransition(opacity: anim1, child: child);
                          },
                        );
                        
                        if (result != null) {
                          setState(() => _selectedSeat = result);
                        }
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(30), // Pill Shape
                          border: Border.all(
                            color: _selectedSeat != null 
                              ? const Color(0xFF7B1FA2) 
                              : Colors.white10,
                          ),
                          boxShadow: _selectedSeat != null ? [
                            BoxShadow(
                              color: const Color(0xFF7B1FA2).withOpacity(0.2),
                              blurRadius: 10,
                            )
                          ] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedSeat != null ? "Seat #$_selectedSeat" : "Choose a Seat",
                              style: GoogleFonts.poppins(
                                color: _selectedSeat != null ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.event_seat,
                              color: _selectedSeat != null ? const Color(0xFF7B1FA2) : Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Passenger Details
                  Text("Passenger Details", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: _inputDeco("Full Name", Icons.person),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: _inputDeco("Phone Number", Icons.phone),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Payment Method
                  Text("Payment Method", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _paymentOption("CASH", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("MOMO", Icons.phone_android),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                       color: const Color(0xFF7B1FA2).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.3))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Amount", style: GoogleFonts.poppins(color: Colors.white70)),
                        Text(
                          "UGX ${price.toStringAsFixed(0)}", 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Glowing Confirm Button
                  GestureDetector(
                    onTap: _isLoading ? null : _processSale,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Center(
                          child: Container(
                            width: 280, // Reduced width
                            height: 56,
                            decoration: BoxDecoration(
                              // Purple Gradient with Pulse Opacity
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4A148C).withOpacity(0.9), // Slightly opaque for button
                                  const Color(0xFF7B1FA2).withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30), // Pill Shape
                              border: Border.all(
                                color: const Color(0xFFEA80FC).withOpacity(0.8), // Bright Accent Border
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B1FA2).withOpacity(0.5 * _pulseAnimation.value), // Pulse Glow
                                  blurRadius: 15,
                                  spreadRadius: 1 + _pulseAnimation.value,
                                )
                              ],
                            ),
                            child: Center(
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.print, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Confirm Sale & Print",
                                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, IconData icon) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7B1FA2) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.transparent : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
               const SizedBox(height: 4),
              Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white38),
      prefixIcon: Icon(icon, color: const Color(0xFF7B1FA2)),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';


class GlassBookingCard extends StatefulWidget {
  final ValueChanged<bool>? onFocusChange; // Callback for greeting change
  final TextEditingController fromController;
  final TextEditingController toController;

  const GlassBookingCard({
    super.key,
    this.onFocusChange,
    required this.fromController,
    required this.toController,
  });

  @override
  State<GlassBookingCard> createState() => _GlassBookingCardState();
}

class _GlassBookingCardState extends State<GlassBookingCard> {
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();
  int _selectedDateIndex = 0; // State for selected date
  
  @override
  void initState() {
    super.initState();
    _fromFocus.addListener(_handleFocusChange);
    _toFocus.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _fromFocus.hasFocus || _toFocus.hasFocus;
    widget.onFocusChange?.call(hasFocus);
  }

  // Method to swap locations
  void _swapLocations() {
    final temp = widget.fromController.text;
    setState(() {
      widget.fromController.text = widget.toController.text;
      widget.toController.text = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black, // Pure Black to match Wallet
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Inputs (White Text on Charcoal)
          Column(
            children: [
              // FROM Input
              _buildLocationInput(
                icon: Icons.my_location_rounded,
                hint: "From",
                controller: widget.fromController,
                focusNode: _fromFocus,
                iconColor: const Color(0xFFAB47BC), // Lighter Purple for contrast
              ),
              
              // Divider & Swap Button
              Row(
                children: [
                  const SizedBox(width: 34),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))), // White Divider
                  IconButton(
                    onPressed: _swapLocations,
                    icon: const Icon(Icons.swap_vert_circle_rounded, color: Color(0xFFAB47BC)),
                  ),
                ],
              ),

              // TO Input
              _buildLocationInput(
                icon: Icons.location_on_rounded,
                hint: "To",
                controller: widget.toController,
                focusNode: _toFocus,
                iconColor: Colors.redAccent, // Red Pin
              ),
            ],
          ),


          const SizedBox(height: 24),

          // Departure Title
          Text(
            "Departure",
            style: GoogleFonts.outfit( // Switched to Outfit
              color: Colors.white70, // White Text
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Date Selector (Next 6 Days - Evenly Spaced)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = index == _selectedDateIndex; // Interactive selection
              
              final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
              final weekdayName = weekdays[date.weekday - 1];
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut, // Changed from easeOutBack to prevent negative shadow blur
                    transform: isSelected 
                      ? Matrix4.translationValues(0, -6, 0) // Lift up by 6px
                      : Matrix4.identity(),
                    margin: const EdgeInsets.symmetric(horizontal: 2), // Tiny gap
                    padding: const EdgeInsets.symmetric(vertical: 12), // Height only
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4A148C) : Colors.transparent, 
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: Colors.white12),
                      boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4A148C).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ] 
                        : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdayName,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 10, // Small text
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${date.day}",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Search Button (Purple to Pop)
          Center(
            child: GestureDetector(
                onTap: () {
                 _fromFocus.unfocus();
                 _toFocus.unfocus();
                 
                 final selectedDate = DateTime.now().add(Duration(days: _selectedDateIndex));
                 
                 context.push(
                   '/search_results',
                   extra: {
                     'from': widget.fromController.text.isEmpty ? "Kampala" : widget.fromController.text,
                     'to': widget.toController.text.isEmpty ? "Gulu" : widget.toController.text,
                     'date': selectedDate.toString(), // Passing the date
                   },
                 );
                },
              child: Container(
                width: 200, // Shortened width
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A148C).withOpacity(0.9),
                      const Color(0xFF4A148C).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30), // Pill shape
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A148C).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Search Buses",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500), // Switched to Outfit
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white38),
              filled: false, // EXPLICITLY FALSE to remove any default background
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

}

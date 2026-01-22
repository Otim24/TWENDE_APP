
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultsScreen extends StatefulWidget {
  final String fromLocation;
  final String toLocation;

  const SearchResultsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  // State for dynamic content
  late String _fromLocation;
  late String _toLocation;

  final List<String> _ugandanDistricts = [
    "Kampala", "Jinja", "Mbarara", "Gulu", "Lira", "Mbale", "Masaka",
    "Arua", "Soroti", "Fort Portal", "Entebbe", "Hoima", "Kabale", 
    "Kasese", "Tororo", "Busia", "Mukono", "Iganga", "Kitgum", "Moroto"
  ];

  @override
  void initState() {
    super.initState();
    _fromLocation = widget.fromLocation.isEmpty ? "Current Location" : widget.fromLocation;
    _toLocation = widget.toLocation;
  }

  // Mock Data conforming to user request
  final List<Map<String, dynamic>> _buses = [
    {
      "company": "Link Bus",
      "route": "Kampala ➔ Jinja",
      "time": "07:00 AM",
      "price": "15,000 UGX",
      "eta": "in 15 min",
      "seats": 4,
      "distance": "2 km away",
    },
    {
      "company": "Global Coaches",
      "route": "Masaka ➔ Mbarara",
      "time": "08:45 AM",
      "price": "25,000 UGX",
      "eta": "in 30 min",
      "seats": 12,
      "distance": "5 km away",
    },
    {
      "company": "Larem Safaris",
      "route": "Gulu ➔ Lira",
      "time": "10:15 AM",
      "price": "35,000 UGX",
      "eta": "in 45 min",
      "seats": 8,
      "distance": "12 km away",
    },
    {
      "company": "YY Coaches",
      "route": "Kampala ➔ Mbale",
      "time": "12:00 PM",
      "price": "30,000 UGX",
      "eta": "Arrived",
      "seats": 2,
      "distance": "At Station",
    },
  ];

  void _showLocationPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Modal Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  isFrom ? "Select Departure" : "Select Destination",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ugandanDistricts.length,
                  itemBuilder: (context, index) {
                    final district = _ugandanDistricts[index];
                    return ListTile(
                      onTap: () {
                        setState(() {
                          if (isFrom) {
                            _fromLocation = district;
                          } else {
                            _toLocation = district;
                          }
                        });
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        Icons.location_city_rounded, 
                        color: Colors.white54,
                      ),
                      title: Text(
                        district,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filter Options", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort_rounded, color: Colors.white),
                title: Text("Sort by Price (Low to High)", style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded, color: Colors.white),
                title: Text("Sort by Departure Time", style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Curved Header Background (Matching App Theme)
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)], // Deep Purple Gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Results",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Timeline Inputs Area (Dark Glass Style)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black, // Dark Theme
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // From Field
                      GestureDetector(
                        onTap: () => _showLocationPicker(true),
                        child: Row(
                          children: [
                            const Icon(Icons.radio_button_unchecked, color: Color(0xFF7C4DFF), size: 20), // Lighter Purple
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fromLocation,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // White Text
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_location_alt_rounded, color: Colors.white54, size: 18),
                          ],
                        ),
                      ),
                      
                      // Connector Line
                      Padding(
                        padding: const EdgeInsets.only(left: 9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 20,
                            width: 2,
                            color: Colors.white24, // Darker Line
                          ),
                        ),
                      ),

                      // To Field
                      GestureDetector(
                        onTap: () => _showLocationPicker(false),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF7C4DFF), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _toLocation,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // White Text
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_location_alt_rounded, color: Colors.white54, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      const Divider(color: Colors.white12),
                      
                      // Options Row
                      Row(
                        children: [
                          _buildOptionChip(Icons.history, "Today, 12:00 PM", () {}),
                          const SizedBox(width: 12),
                          _buildOptionChip(Icons.filter_list_rounded, "Options", _showOptionsModal),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 4. "Recommended Buses" Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Recommended Buses",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // 5. Scrollable List of Buses
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _buses.length,
                    itemBuilder: (context, index) {
                      final bus = _buses[index];
                      return _buildBusCard(bus);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1)), // White Opacity Border
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white70), // White Icon
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white, // White Text
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark Card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Row 1: Icon + Name + Arrival
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A148C).withOpacity(0.2), // Brand BG
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_bus, color: Color(0xFF7B1FA2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus['company'],
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      bus['route'],
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Arriving",
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    bus['eta'], // e.g., "in 15 min"
                    style: GoogleFonts.outfit(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Row 2: Distance & Seat Info
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                bus['distance'],
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.event_seat_outlined, size: 16, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                "${bus['seats']} seats left",
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 3: Action Button & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Price",
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    bus['price'],
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  context.push('/bus_details', extra: bus);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100), // Orange Action Button (Like Image)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Select Bus",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

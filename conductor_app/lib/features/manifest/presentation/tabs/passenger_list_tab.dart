import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PassengerListTab extends StatefulWidget {
  final List<dynamic> manifest;
  final Function(int) onBoardPassenger;

  const PassengerListTab({
    super.key,
    required this.manifest,
    required this.onBoardPassenger,
  });

  @override
  State<PassengerListTab> createState() => _PassengerListTabState();
}

class _PassengerListTabState extends State<PassengerListTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final allPassengers = widget.manifest.where((p) => p['passenger_name'] != null).toList();
    final notBoarded = allPassengers.where((p) => p['status'] != 'USED' && p['status'] != 'OCCUPIED').toList();
    final boarded = allPassengers.where((p) => p['status'] == 'USED' || p['status'] == 'OCCUPIED').toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search",
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: const Icon(Icons.mic, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),

        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Not Boarded"),
                Tab(text: "Boarded"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${allPassengers.length} Passengers", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              Text("${boarded.length}/${allPassengers.length} Boarded", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // List View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(allPassengers),
              _buildList(notBoarded),
              _buildList(boarded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<dynamic> passengers) {
    // Search Filter
    final query = _searchController.text.toLowerCase();
    final filtered = passengers.where((p) {
      final name = (p['passenger_name'] ?? "").toLowerCase();
      final phone = (p['passenger_phone'] ?? "").toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text("No passengers found", style: GoogleFonts.poppins(color: Colors.white24)));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = filtered[index];
        bool isBoarded = p['status'] == 'USED' || p['status'] == 'OCCUPIED';
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['passenger_name'] ?? "Unknown",
                      style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['passenger_phone'] ?? "No Phone",
                      style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              if (isBoarded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Light Green
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Boarded",
                    style: GoogleFonts.poppins(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              else
                 SizedBox(
                   height: 36,
                   child: ElevatedButton(
                     onPressed: () => widget.onBoardPassenger(p['booking_id']),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFFE0E0E0), // Light Grey
                       foregroundColor: Colors.black,
                       elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     ),
                     child: Text("Board", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                   ),
                 ),
            ],
          ),
        );
      },
    );
  }
}

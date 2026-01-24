import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManualEntrySheet extends StatefulWidget {
  final List<dynamic> manifest;
  final Function(int) onBoardPassenger;

  const ManualEntrySheet({
    super.key, 
    required this.manifest, 
    required this.onBoardPassenger
  });

  @override
  State<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<ManualEntrySheet> {
  String _searchQuery = "";
  List<dynamic> _searchResults = [];

  void _search(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = widget.manifest.where((p) {
          final q = query.toLowerCase();
          final name = (p['passenger_name'] ?? '').toString().toLowerCase();
          final phone = (p['passenger_phone'] ?? '').toString().toLowerCase();
          final ticket = (p['booking_id'] ?? '').toString().toLowerCase();
          final seat = (p['seat_number'] ?? '').toString().toLowerCase(); // User also mentioned seat

          return name.contains(q) || phone.contains(q) || ticket.contains(q) || seat == q;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          // Title
          Text(
            "Manual Verification",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Search by Name, Phone, Ticket # or Seat",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: _search,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type to search...",
                hintStyle: GoogleFonts.poppins(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7B1FA2)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Results
          Expanded(
            child: _searchQuery.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const Icon(Icons.touch_app, color: Colors.white24, size: 48),
                       const SizedBox(height: 12),
                       Text("Enter details to verify", style: GoogleFonts.poppins(color: Colors.white24)),
                    ],
                  )
                )
              : _searchResults.isEmpty 
                  ? Center(child: Text("No passengers found", style: GoogleFonts.poppins(color: Colors.white54)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_,__) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final p = _searchResults[index];
                        final bool isBoarded = p['status'] == 'USED';
                        final bool isPaid = p['status'] == 'OCCUPIED' || isBoarded;
                        
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isBoarded ? Colors.green[900] : const Color(0xFF7B1FA2),
                            child: Icon(
                               isBoarded ? Icons.check : Icons.person, 
                               color: Colors.white, size: 20
                            ),
                          ),
                          title: Text(
                            p['passenger_name'] ?? "Unknown",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Seat ${p['seat_number']} • ${p['passenger_phone'] ?? 'No Phone'}", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                              Text("Ticket #${p['booking_id']}", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          trailing: isBoarded 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () {
                                    widget.onBoardPassenger(p['booking_id']);
                                    Navigator.pop(context); 
                                    // Optional: Keep open? User said "Conductor taps Mark as Boarded. That's it."
                                    // Closing feels better for flow, or toast. Let's close for now.
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Text("Board", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

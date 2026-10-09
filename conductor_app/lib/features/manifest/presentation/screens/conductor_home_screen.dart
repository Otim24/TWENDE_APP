import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:twende_conductor_app/features/manifest/presentation/tabs/dashboard_tab.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/manual_entry_sheet.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/sell_ticket_sheet.dart';
import 'package:twende_conductor_app/features/manifest/presentation/tabs/passenger_list_tab.dart';
import 'package:twende_conductor_app/features/manifest/presentation/tabs/seat_map_tab.dart';
import 'package:twende_conductor_app/features/scan/presentation/screens/scanner_screen.dart';
import 'package:flutter/rendering.dart';
class ConductorHomeScreen extends StatefulWidget {
  final String userName;
  const ConductorHomeScreen({super.key, required this.userName});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;
  
  // Data State
  List<dynamic> _manifest = [];
  Map<String, dynamic>? _activeTrip; // Computed from manifest for now

  // LAN Connection
final String _baseUrl = 'http://192.168.1.65:8000/api/v1/conductor';
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = Dio();
      
      // 1. Fetch Trips (for Dashboard)
      final tripsResponse = await dio.get('$_baseUrl/trips');
      if (tripsResponse.statusCode == 200 && (tripsResponse.data as List).isNotEmpty) {
        _activeTrip = tripsResponse.data[0]; 
      } else {
        // DEMO MODE: Force UI to show "Kampala - Lira" if no API data exists
        _activeTrip = {
          'id': 999,
          'route_name': 'Kampala - Lira',
          'bus_plate': 'UAX 345F',
          'departure_time': '10:00 AM',
          'total_seats': 60,
          'occupied_seats': 47,
          'status': 'SCHEDULED'
        };
      }

      // 2. Fetch Manifest (if we have a trip)
      if (_activeTrip != null) {
        final id = _activeTrip!['id'];
        
        if (id == 999) {
          // DEMO MODE: Generate Fake Manifest
          _manifest = _generateDemoManifest();
        } else {
          final manifestResponse = await dio.get('$_baseUrl/trips/$id/manifest');
          if (manifestResponse.statusCode == 200) {
            _manifest = manifestResponse.data;
          }
        }
      }
      
      setState(() => _isLoading = false);

    } catch (e) {
      if (mounted) {
        setState(() {
           _error = "Err: ${e.toString()}";
           _isLoading = false;
        });
      }
      print("Error loading data: $e");
    }
  }

  // Action: Manual Board (From List or Map)
  Future<void> _manualBoard(int bookingId) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/verify_ticket', 
        data: {'ticket_data': bookingId.toString()}
      );
      
      if (response.data['valid'] == true) {
        // Optimistic Update
        setState(() {
           final index = _manifest.indexWhere((p) => p['booking_id'] == bookingId);
           if (index != -1) {
             _manifest[index]['status'] = 'USED'; // Mark as Used/Boarded
           }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passenger Boarded Successfully"), backgroundColor: Colors.green)
        );
        // Refresh to be safe
        _fetchData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red)
      );
    }
  }

  List<dynamic> _generateDemoManifest() {
    List<dynamic> list = [];
    // Generate 60 seats
    for (int i = 1; i <= 60; i++) {
      String status = "AVAILABLE";
      String? name;
      String? phone;
      
      // Fake some data
      if (i <= 45) { // 45 Occupied
         if (i % 2 == 0) {
           status = "USED"; // Boarded
           name = "Passenger $i";
           phone = "+256 700 0000$i";
         } else {
           status = "OCCUPIED"; // Booked/Paid
           name = "Passenger $i"; 
           phone = "+256 700 0000$i";
         }
      }
      
      list.add({
        'seat_number': i,
        'status': status,
        'passenger_name': name,
        'passenger_phone': phone,
        'booking_id': 1000 + i // Fake IDs
      });
    }
    return list;
  }

  void _onSwitchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  bool _isNavVisible = true;
  
  void _onScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse && _isNavVisible) {
      if (mounted) setState(() => _isNavVisible = false);
    } else if (notification.direction == ScrollDirection.forward && !_isNavVisible) {
      if (mounted) setState(() => _isNavVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          _onScroll(notification);
          return true;
        },
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B1FA2)))
                      : _error != null 
                          ? Center(child: TextButton(onPressed: _fetchData, child: Text(_error!, style: const TextStyle(color: Colors.red))))
                          : IndexedStack(
                              index: _selectedIndex,
                              children: [
                                // Tab 0: Dashboard
                                DashboardTab(
                                  trip: _activeTrip, 
                                  onStartTrip: () {}, 
                                  onSwitchTab: _onSwitchTab,
                                  onManualEntry: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => ManualEntrySheet(
                                        manifest: _manifest,
                                        onBoardPassenger: _manualBoard,
                                      ),
                                    );
                                  },
                                  onSellTicket: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => SellTicketSheet(
                                        trip: _activeTrip,
                                        manifest: _manifest,
                                        onSuccess: () {
                                          _fetchData(); // Refresh manifest
                                        },
                                      ),
                                    );
                                  },
                                ),
                                
                                // Tab 1: Passenger List
                                PassengerListTab(
                                  manifest: _manifest,
                                  onBoardPassenger: _manualBoard,
                                ),
                                
                                // Tab 2: Seat Map
                                SeatMapTab(
                                  manifest: _manifest,
                                  onSeatTap: (seat) {}, 
                                ),
                                
                                // Tab 3: Scanner Placeholder
                                Center(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text("Open Camera"),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                  ),
                ],
              ),
            ),
            
            // Bottom Pill Navigation (Animated)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _isNavVisible ? 30 : -100, // Hide below screen
              left: 20,
              right: 20,
              child: _buildPillNav(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    String title = "Conductor App";
    if (_selectedIndex == 1) title = "Passenger List";
    if (_selectedIndex == 2) title = "Seat Map";
    if (_selectedIndex == 3) title = "Scan Ticket";
    
    // Only show Welcome header on Home Tab (0)
    if (_selectedIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Profile Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF7B1FA2), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF1E1E1E),
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Back!",
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      widget.userName,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            
            // Notification Bell
            GestureDetector(
              onTap: () {
                // Functional Bell
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("No new notifications", style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF1E1E1E),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(label: "Dismiss", onPressed: () {}, textColor: const Color(0xFFE040FB)),
                  )
                );
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  ),
                  Positioned(
                    right: 10, 
                    top: 10, 
                    child: Container(
                      width: 8, height: 8, 
                      decoration: const BoxDecoration(color: Color(0xFFE040FB), shape: BoxShape.circle)
                    )
                  )
                ],
              ),
            )
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               if (_selectedIndex != 0)
                 IconButton(
                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                   onPressed: () => _onSwitchTab(0),
                 ),
               const Icon(Icons.directions_bus, color: Colors.white),
               const SizedBox(width: 10),
               Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Stack(
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              Positioned(
                right: 0, 
                top: 0, 
                child: Container(
                  width: 8, height: 8, 
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)
                )
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPillNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.dashboard, "Home"),
          _navItem(1, Icons.people, "List"),
          _navItem(2, Icons.grid_view, "Map"),
          _navItem(3, Icons.qr_code_scanner, "Scan"),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onSwitchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected 
          ? BoxDecoration(
              color: const Color(0xFF7B1FA2),
              borderRadius: BorderRadius.circular(20),
            )
          : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
            if (isSelected) 
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}

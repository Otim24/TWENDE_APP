
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/features/account/presentation/screens/account_screen.dart';
import 'package:twende_passenger_app/features/activity/presentation/screens/activity_screen.dart';
import 'package:twende_passenger_app/features/home/presentation/screens/home_content.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeContent(),
    ActivityScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Charcoal Black / Pure Black
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ), // Switch body based on index
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.directions_car_filled_rounded, "Twende"),
              _buildNavItem(1, Icons.receipt_long_rounded, "Activity"),
              _buildNavItem(2, Icons.person_outline_rounded, "My Account"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4A148C) : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C).withOpacity(0.2), // Pill Activity
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A148C),
                ),
              ),
            )
          else
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
        ],
      ),
    );
  }
}

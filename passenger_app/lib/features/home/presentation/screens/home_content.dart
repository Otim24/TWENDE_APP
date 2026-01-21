
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/action_button.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_booking_card.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_wallet_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isSearching = false;

  void _onSearchFocusChange(bool hasFocus) {
    setState(() {
      _isSearching = hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Purple Curved Header Background
        Container(
          height: MediaQuery.of(context).size.height * 0.42, // Covers Header + Inputs
          decoration: const BoxDecoration(
            color: Color(0xFF4A148C), // Deep Rich Purple
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(36), // The Curve
            ),
          ),
        ),

        // Main Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Dynamic)
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSearching
                        ? Text(
                            "Where are you travelling to Today?",
                            key: const ValueKey("Searching"),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : RichText(
                            key: const ValueKey("Greeting"),
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: "Good Afternoon, "),
                                TextSpan(
                                  text: "Caine!",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // White against purple
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Booking Card (Hero)
                GlassBookingCard(onFocusChange: _onSearchFocusChange),

                const SizedBox(height: 24),

            // Wallet Section
            Text(
              "My Wallet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            const GlassWalletCard(), // Compacted wallet
            
            const Spacer(),
          ],
        ),
      ),
      ),
    ],
  );
  }
}

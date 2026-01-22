
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/action_button.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_booking_card.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/promo_carousel.dart';
import 'package:go_router/go_router.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_wallet_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isSearching = false;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

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

        // Main Content (Scrollable)
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), // Reduced from 16
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
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : RichText(
                            key: const ValueKey("Greeting"),
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: "Good Afternoon, "),
                                TextSpan(
                                  text: "Caine!",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // White against purple
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 10), // Reduced from 16

                // Wallet Access Button (Glass Pill)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      GoRouter.of(context).push('/wallet/deposit');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black, // Deep Dark Black
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "My Wallet",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16), // Reduced from 24

                // Booking Card (Hero)
                GlassBookingCard(
                  onFocusChange: _onSearchFocusChange,
                  fromController: _fromController,
                  toController: _toController,
                ),

                const SizedBox(height: 200), // Increased Spacing to clear Button + Carousel
              ],
            ),
          ),
        ),

        // Pay for Ticket Button (Shifted Up)
        Positioned(
          bottom: 120, // Shifted up to make room for Carousel (100px + 20px padding)
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (_fromController.text.isEmpty || _toController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Please enter 'From' and 'To' locations first.",
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                context.push(
                  '/search_results',
                  extra: {
                    'from': _fromController.text,
                    'to': _toController.text,
                  },
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6, 
                height: 50, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A148C),
                      const Color(0xFF7B1FA2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A148C).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Pay for Ticket",
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
        ),

        // Ads / Promo Carousel (Fixed at Absolute Bottom)
        Positioned(
          bottom: 16, // Near bottom (above Nav Bar visual area)
          left: 0,
          right: 0,
          child: const Center(
            child: PromoCarousel(),
          ),
        ),
      ],
    );
  }

}

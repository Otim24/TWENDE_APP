
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/action_button.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_booking_card.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/promo_carousel.dart';
import 'package:go_router/go_router.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_wallet_card.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/wallet_options_sheet.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowBlurAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shadowBlurAnimation = Tween<double>(begin: 8.0, end: 16.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _pulseController.dispose();
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

        // Main Content (Fit to Screen, Scrollable only on Overflow/Keyboard)
        SafeArea(
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(), // Locks the screen (No Scroll)
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // --- TOP CONTENT ---
                      Column(
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
                                              color: Colors.white, 
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 10),

                          // Wallet Buttons Row
                          Row(
                            children: [
                              // My Wallet Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    GoRouter.of(context).push('/wallet');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black, 
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "My Wallet",
                                          style: GoogleFonts.poppins(
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

                              const SizedBox(width: 12),

                              // Wallet Options Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent, // Let sheet handle its own radius/color
                                      isScrollControlled: true, // Allow full height if needed
                                      builder: (context) => const WalletOptionsSheet(),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black, 
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Wallet Options",
                                          style: GoogleFonts.poppins(
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
                            ],
                          ),
                          
                          const SizedBox(height: 16),

                          // Booking Card
                          GlassBookingCard(
                            onFocusChange: _onSearchFocusChange,
                            fromController: _fromController,
                            toController: _toController,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16), // Reduced gap between Card and Services

                      // --- BOTTOM CONTENT ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Text
                          Text(
                            "Our Services",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced gap below header

                          // Pulsing Buttons Row
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Row(
                                  children: [
                                    // Pay for Ticket Button
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_fromController.text.isEmpty || _toController.text.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Please enter 'From' and 'To' locations first.",
                                                  style: GoogleFonts.poppins(color: Colors.white),
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
                                          height: 50, 
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF4A148C),
                                                Color(0xFF7B1FA2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF4A148C).withOpacity(0.5),
                                                blurRadius: _shadowBlurAnimation.value,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Pay Ticket",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),

                                    // Cargo Button
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Cargo Service Coming Soon!", style: GoogleFonts.poppins()),
                                              backgroundColor: Colors.blueGrey,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 50, 
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF4A148C),
                                                Color(0xFF7B1FA2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF4A148C).withOpacity(0.5),
                                                blurRadius: _shadowBlurAnimation.value,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Cargo",
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const Spacer(), // Pushes Carousel to the absolute bottom

                      // Ads / Promo Carousel
                      const Center(
                        child: PromoCarousel(),
                      ),
                      
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

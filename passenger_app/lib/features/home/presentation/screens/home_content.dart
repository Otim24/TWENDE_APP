
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/action_button.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_booking_card.dart';
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

        // Main Content
        SafeArea(
          child: SingleChildScrollView(
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
                
                const SizedBox(height: 16),

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
                
                const SizedBox(height: 24),

                // Booking Card (Hero)
                GlassBookingCard(
                  onFocusChange: _onSearchFocusChange,
                  fromController: _fromController,
                  toController: _toController,
                ),

                const SizedBox(height: 16),
                
                 // Pay for Ticket Button (Centered, Glassmorphic)
                Center(
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
                      width: 200,
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
                        borderRadius: BorderRadius.circular(30),
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

                const SizedBox(height: 32),

                // Recent Search Heading
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Search",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "See all",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFF8C00), // Orange accent like ref image
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent Search List
                Column(
                  children: [
                    _buildRecentSearchItem("Kampala", "Jinja"),
                    _buildRecentSearchItem("Entebbe", "Gulu"),
                    _buildRecentSearchItem("Mbarara", "Kabale"),
                  ],
                ),
                
                const SizedBox(height: 24), // Bottom Padding
              ],
            ),
          ),
        ), // Closes SafeArea
      ],
    );
  }

  Widget _buildRecentSearchItem(String from, String to) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1), // Light grey circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "From - To",
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "$from - $to",
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.1)),
        ],
      ),
    );
  }
}

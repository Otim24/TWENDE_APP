import 'dart:async';
import 'dart:ui' as import_ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> busDetails;
  final int seatCount;

  const PaymentScreen({
    super.key,
    required this.busDetails,
    required this.seatCount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  String _selectedMethod = "wallet"; // Default to Wallet now
  bool _isProcessing = false;
  bool _isSummaryFocused = false; // New State for Hover Effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Fast subtle pulse
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Total
    final priceString = widget.busDetails['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
    final pricePerSeat = int.tryParse(priceString) ?? 0;
    final totalAmount = pricePerSeat * widget.seatCount;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Payment Method",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Payment Methods Section
                Text(
                  "Select Payment Method",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // Pulsing Wallet Option
                _buildWalletPaymentOption(),
                
                const SizedBox(height: 24),
                
                Text(
                  "Other Methods",
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                
                // Carousel for Other Methods
                PaymentMethodCarousel(
                  selectedMethod: _selectedMethod,
                  onMethodSelected: (id) => setState(() => _selectedMethod = id),
                ),

                const SizedBox(height: 32),

                // 2. Review Summary Section
                Text(
                  "Review Summary",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // The Summary Card (Normal State)
                GestureDetector(
                  onTap: () => setState(() => _isSummaryFocused = true),
                  child: Hero(
                    tag: 'summary_card',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow("Trip", "Kampala - Busia"), 
                          const Divider(color: Colors.white10, height: 24),
                          _buildSummaryRow("Bus", widget.busDetails['company'] ?? 'Bus'),
                          const Divider(color: Colors.white10, height: 24),
                          _buildSummaryRow("Seats", "${widget.seatCount} x ${widget.busDetails['price']}"),
                          const Divider(color: Colors.white10, height: 24),
                          _buildSummaryRow("Tax", "UGX 0"),
                          const Divider(color: Colors.white10, height: 24),
                          
                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount",
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                              ),
                              Text(
                                "UGX ${totalAmount.toString()}", 
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                 // Extra spacing for bottom bar
                 const SizedBox(height: 80),
              ],
            ),
          ),

          // 2. Blur Overlay (When Focused)
           if (_isSummaryFocused)
            GestureDetector(
              onTap: () => setState(() => _isSummaryFocused = false), // Tap outside to dismiss
              child: Container(
                color: Colors.black.withOpacity(0.1), // Dim slightly
                child: BackdropFilter(
                  filter: import_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          
          // 3. Focused Summary Card (Centered)
          if (_isSummaryFocused)
            Center(
              child: GestureDetector(
                onTap: () {}, // Eat taps on card
                child: Hero(
                  tag: 'summary_card', // Matches Hero tag above
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(24), // Larger padding
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF7B1FA2), width: 2), // Purple Border
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B1FA2).withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView( // Safe wrap
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Trip Summary",
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                           _buildSummaryRow("Trip", "Kampala - Busia"), 
                          const Divider(color: Colors.white10, height: 24),
                          _buildSummaryRow("Bus", widget.busDetails['company'] ?? 'Bus'),
                           const Divider(color: Colors.white10, height: 24),
                          _buildSummaryRow("Seats", "${widget.seatCount} x ${widget.busDetails['price']}"),
                           const Divider(color: Colors.white10, height: 24),
                          _buildSummaryRow("Tax", "UGX 0"),
                           const Divider(color: Colors.white10, height: 24),
                          
                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total",
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "UGX ${totalAmount.toString()}", 
                                style: GoogleFonts.poppins(color: const Color(0xFFC6FF00), fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Tap outside to close",
                            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      
      // Bottom Pay Button using SafeArea and Padding
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 60,
            child: _SlideToPayButton(
              onSlideCompleted: () {
                setState(() {
                  _isProcessing = true;
                });
                
                // Simulate Payment Delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    
                    // Navigate to Receipt Screen
                    context.go(
                      '/receipt',
                      extra: {
                        'busCompany': widget.busDetails['company'],
                        'route': "Kampala - Busia", // Should be dynamic
                        'date': "24 Jan 2026", // Should be dynamic
                        'departureTime': widget.busDetails['departure_time'],
                        'totalPrice': totalAmount.toString(),
                        'seatCount': widget.seatCount,
                      },
                    );
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  // ... (Keep existing helpers) ...
  Widget _buildCompactPaymentCard({
    required String id, 
    required String name, 
    required Color color, 
    required Color textColor,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon / Logo Box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: textColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            // Selection Indicator (Dot)
            Container(
              width: 8, 
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Wallet Option with Pulse & Glassmorphism
  Widget _buildWalletPaymentOption() {
    final isSelected = _selectedMethod == "wallet";
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = "wallet"),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              // Purple Gradient with Pulse Opacity
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A148C).withOpacity(0.6),
                  const Color(0xFF7B1FA2).withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFFEA80FC) // Bright Purple Accent when selected
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7B1FA2).withOpacity(0.4 * _pulseAnimation.value), // Pulse Effect
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pay with Wallet",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Balance: UGX 14,890", // Dynamic later
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFFEA80FC))
                else
                  const Icon(Icons.circle_outlined, color: Colors.white24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
     return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SlideToPayButton extends StatefulWidget {
  final VoidCallback onSlideCompleted;

  const _SlideToPayButton({required this.onSlideCompleted});

  @override
  State<_SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<_SlideToPayButton> {
  double _dragValue = 0.0;
  double _maxWidth = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        
        return Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A148C).withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Text Background
              Center(
                child: Text(
                  _submitted ? "Processing..." : "Slide to Pay",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 2. Shimmer/Glass Effect Placeholder (Optional Polishing)
              
              // 3. Draggable Knob
              if (!_submitted)
                Positioned(
                  left: _dragValue,
                  top: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                         // 52 is width of knob (ish)
                        _dragValue = (_dragValue + details.delta.dx).clamp(0.0, _maxWidth - 60);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragValue > _maxWidth * 0.7) {
                        // Success trigger
                        setState(() {
                          _dragValue = _maxWidth - 60;
                          _submitted = true;
                        });
                        widget.onSlideCompleted();
                      } else {
                        // Snap back
                        setState(() {
                          _dragValue = 0.0;
                        });
                      }
                    },
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentMethodCarousel extends StatefulWidget {
  final String selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodCarousel({
    super.key, 
    required this.selectedMethod, 
    required this.onMethodSelected
  });

  @override
  State<PaymentMethodCarousel> createState() => _PaymentMethodCarouselState();
}

class _PaymentMethodCarouselState extends State<PaymentMethodCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1.0); // Full width
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _methods = [
    {"id": "visa", "name": "VISA Card", "color": const Color(0xFF1A1F71), "textColor": Colors.white, "icon": Icons.credit_card, "desc": "0% Fees"},
    {"id": "mtn", "name": "MTN Mobile Money", "color": const Color(0xFFFFCC00), "textColor": Colors.black, "icon": Icons.phone_android, "desc": "Fast & Secure"},
    {"id": "airtel", "name": "Airtel Money", "color": const Color(0xFFFF0000), "textColor": Colors.white, "icon": Icons.wifi_tethering, "desc": "Instant Pay"},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _methods.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100, 
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
             _currentPage = index;
             // If we want selection on scroll, uncomment:
             // widget.onMethodSelected(_methods[index]["id"]);
             // But usually user should tap to select.
          });
        },
        itemCount: _methods.length,
        itemBuilder: (context, index) {
          final method = _methods[index];
          final isSelected = widget.selectedMethod == method["id"];
          final color = method["color"] as Color;
          
          return GestureDetector(
            onTap: () => widget.onMethodSelected(method["id"]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8), 
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1
                ),
                boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
              ),
              child: Row(
                children: [
                   const SizedBox(width: 16),
                   // Icon Circle
                   Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(method["icon"], color: method["textColor"], size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          method["name"],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          method["desc"],
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection Indicator
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.check_circle, color: color),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

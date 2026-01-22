
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _ads = [
    {"color": const Color(0xFFE65100), "title": "Jumia Food", "icon": Icons.fastfood_rounded, "desc": "50% Off Order"},
    {"color": const Color(0xFF1B5E20), "title": "SafeBoda", "icon": Icons.motorcycle_rounded, "desc": "Ride Safe"},
    {"color": const Color(0xFF0D47A1), "title": "MTN MoMo", "icon": Icons.mobile_friendly_rounded, "desc": "Pay Bills"},
    {"color": const Color(0xFFB71C1C), "title": "Airtel", "icon": Icons.wifi_tethering_rounded, "desc": "Data Bundles"},
    {"color": const Color(0xFFF57F17), "title": "Shell", "icon": Icons.local_gas_station_rounded, "desc": "Fuel Rewards"},
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
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _ads.length) {
          nextPage = 0; // Loop back to start
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800), // Smooth slow slide
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
      height: 115, // Reduced height (Sleeker)
      width: 340, 
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return Center(
            child: Container(
              width: 320, 
              height: 95, // Inner Height
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9), // Glassy Black
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: (ad["color"] as Color).withOpacity(0.3), // Glow based on brand color
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row( // Row for Banner Layout
                children: [
                   const SizedBox(width: 16),
                   // Icon Circle
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (ad["color"] as Color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ad["icon"] as IconData,
                      color: ad["color"] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ad["title"] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          ad["desc"] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Indicator
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 14,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

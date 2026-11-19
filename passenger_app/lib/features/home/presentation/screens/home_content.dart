import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/auth/data/auth_repository.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/glass_booking_card.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/promo_carousel.dart';
import 'package:twende_passenger_app/features/home/presentation/widgets/wallet_options_sheet.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  bool _isSearching = false;
  final TextEditingController _fromController =
      TextEditingController(text: 'Kampala');
  final TextEditingController _toController =
      TextEditingController(text: 'Gulu');

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange(bool hasFocus) {
    if (_isSearching != hasFocus) {
      setState(() {
        _isSearching = hasFocus;
      });
    }
  }

  String _greetingPrefix() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, ';
    if (hour < 17) return 'Good Afternoon, ';
    return 'Good Evening, ';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final walletAsync = ref.watch(walletBalanceProvider);

    final String passengerName = profileAsync.maybeWhen(
      data: (data) {
        final String name = (data['full_name'] ?? '').toString().trim();
        return name.isEmpty ? 'Passenger' : name;
      },
      orElse: () => 'Passenger',
    );

    final String walletLabel = walletAsync.maybeWhen(
      data: (data) => AppTokens.formatUgx(data['balance']),
      orElse: () => 'My Wallet',
    );

    return Stack(
      children: [
        // Purple Curved Header Background
        Container(
          height: MediaQuery.of(context).size.height * 0.42,
          decoration: const BoxDecoration(
            color: AppTokens.primaryDark,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(36),
            ),
          ),
        ),

        // Scrollable Content with BouncingScrollPhysics so keyboard opening never overflows
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Header Greeting
                      Center(
                        child: AnimatedSwitcher(
                          duration: AppTokens.normalDuration,
                          child: _isSearching
                              ? Text(
                                  'Where are you travelling today?',
                                  key: const ValueKey('Searching'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : RichText(
                                  key: const ValueKey('Greeting'),
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 19,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      TextSpan(text: _greetingPrefix()),
                                      TextSpan(
                                        text: '$passengerName!',
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
                      const SizedBox(height: 12),

                      // Live Wallet Pill & Wallet Options Row
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/wallet'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        walletLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          fontFeatures:
                                              AppTokens.tabularFigures,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      const WalletOptionsSheet(),
                                );
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Top Up Wallet',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
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

                      // Primary Search & Booking Card
                      GlassBookingCard(
                        onFocusChange: _onSearchFocusChange,
                        fromController: _fromController,
                        toController: _toController,
                      ),
                      const SizedBox(height: 16),

                      // Additional Services (Non-pulsing, no duplicate Pay Ticket button)
                      Text(
                        'Additional Services',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/wallet/deposit'),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTokens.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      color: Color(0xFFFFD740),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Quick Deposit',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Parcel & Cargo Booking Coming Soon!',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.blueGrey,
                                  ),
                                );
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTokens.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_rounded,
                                      color: AppTokens.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Send Cargo',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                      const Spacer(),
                      const Center(
                        child: PromoCarousel(),
                      ),
                      const SizedBox(height: 12),
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

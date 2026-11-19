import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> busDetails;
  final int seatCount;
  final List<int> selectedSeats;

  const PaymentScreen({
    super.key,
    required this.busDetails,
    required this.seatCount,
    this.selectedSeats = const <int>[],
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'WALLET';
  bool _isProcessing = false;
  int _sliderResetSeed = 0;

  List<int> get _resolvedSeats {
    if (widget.selectedSeats.isNotEmpty) {
      final List<int> sorted = List<int>.from(widget.selectedSeats)..sort();
      return sorted;
    }
    final int count = widget.seatCount > 0 ? widget.seatCount : 1;
    return List<int>.generate(count, (index) => index + 1);
  }

  int get _tripId =>
      int.tryParse((widget.busDetails['id'] ?? '1').toString()) ?? 1;

  String _formatDate(dynamic rawIso) {
    if (rawIso == null) return 'Scheduled';
    final DateTime? parsed = DateTime.tryParse(rawIso.toString());
    if (parsed == null) return rawIso.toString();
    final DateTime local = parsed.toLocal();
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  String _formatTime(dynamic rawIso) {
    if (rawIso == null) return 'Scheduled';
    final DateTime? parsed = DateTime.tryParse(rawIso.toString());
    if (parsed == null) return rawIso.toString();
    final DateTime local = parsed.toLocal();
    final int hour12 =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final String amPm = local.hour >= 12 ? 'PM' : 'AM';
    final String min = local.minute.toString().padLeft(2, '0');
    return '$hour12:$min $amPm';
  }

  void _resetSlider() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _sliderResetSeed += 1;
    });
  }

  Future<void> _showInsufficientBalanceDialog({
    required int requiredAmount,
    required int currentBalance,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTokens.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Insufficient Wallet Balance',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          content: Text(
            'This booking costs ${AppTokens.formatUgx(requiredAmount)}, but your wallet balance is ${AppTokens.formatUgx(currentBalance)}. Top up your wallet to complete payment.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/wallet/deposit');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Top Up Wallet',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCheckout({
    required int totalAmount,
    required int walletBalance,
  }) async {
    if (_isProcessing) return;

    if (walletBalance < totalAmount) {
      _resetSlider();
      await _showInsufficientBalanceDialog(
        requiredAmount: totalAmount,
        currentBalance: walletBalance,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final List<int> seats = _resolvedSeats;
      final String backendMethod =
          _selectedMethod == 'WALLET' ? 'WALLET' : 'MOMO';

      final Map<String, dynamic> result =
          await ref.read(bookingRepositoryProvider).createBooking(
                tripId: _tripId,
                seatNumbers: seats,
                paymentMethod: backendMethod,
              );

      ref.invalidate(walletBalanceProvider);
      ref.invalidate(myTripsProvider);

      if (!mounted) return;

      final List<dynamic> createdBookings =
          (result['bookings'] is List) ? (result['bookings'] as List) : <dynamic>[];
      final String busPlate = (widget.busDetails['bus_plate'] ??
              (widget.busDetails['bus'] is Map
                  ? widget.busDetails['bus']['plate']
                  : null) ??
              'UBA 123X')
          .toString();
      final String routeName = (result['route_name'] ??
              widget.busDetails['route_name'] ??
              '${widget.busDetails['origin'] ?? 'Kampala'} - ${widget.busDetails['destination'] ?? 'Gulu'}')
          .toString();

      context.go(
        '/receipt',
        extra: <String, dynamic>{
          'trip_id': _tripId,
          'busCompany': 'Twende Express',
          'bus_plate': busPlate,
          'route': routeName,
          'date': _formatDate(widget.busDetails['departure_time']),
          'departureTime': _formatTime(widget.busDetails['departure_time']),
          'totalPrice': totalAmount,
          'seatCount': seats.length,
          'seat_numbers': seats,
          'bookings': createdBookings,
          if (createdBookings.isNotEmpty && createdBookings.first is Map)
            'qr_code_data': (createdBookings.first as Map)['qr_code_data'],
        },
      );
    } catch (e) {
      _resetSlider();
      if (!mounted) return;
      final String message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTokens.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pricePerSeat = AppTokens.parseUgx(widget.busDetails['price']);
    final List<int> seats = _resolvedSeats;
    final int totalAmount = pricePerSeat * seats.length;

    final walletAsync = ref.watch(walletBalanceProvider);
    final int walletBalance = walletAsync.maybeWhen(
      data: (data) => AppTokens.parseUgx(data['balance']),
      orElse: () => 0,
    );

    final String routeName = (widget.busDetails['route_name'] ??
            '${widget.busDetails['origin'] ?? 'Kampala'} - ${widget.busDetails['destination'] ?? 'Gulu'}')
        .toString();
    final String busPlate = (widget.busDetails['bus_plate'] ??
            (widget.busDetails['bus'] is Map
                ? widget.busDetails['bus']['plate']
                : null) ??
            'Twende Express')
        .toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout & Payment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            // 1. Twende Wallet Card (Static, no pulse, live balance)
            _buildWalletCard(
              walletBalance: walletBalance,
              totalAmount: totalAmount,
              isLoadingBalance: walletAsync.isLoading,
            ),
            const SizedBox(height: 16),

            // 2. Static Selectable Mobile Money Cards (Replaces auto-scrolling carousel)
            Row(
              children: [
                Expanded(
                  child: _buildStaticMethodCard(
                    id: 'MTN',
                    name: 'MTN MoMo',
                    subtitle: 'Instant Wallet Debit',
                    accentColor: const Color(0xFFFFCC00),
                    iconColor: Colors.black,
                    icon: Icons.phone_android_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStaticMethodCard(
                    id: 'AIRTEL',
                    name: 'Airtel Money',
                    subtitle: 'Instant Wallet Debit',
                    accentColor: const Color(0xFFFF1744),
                    iconColor: Colors.white,
                    icon: Icons.wifi_tethering_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 3. Review Summary Card
            Text(
              'Review Summary',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Route', routeName),
                  const Divider(color: Colors.white10, height: 22),
                  _buildSummaryRow('Bus Plate', busPlate),
                  const Divider(color: Colors.white10, height: 22),
                  _buildSummaryRow(
                    'Selected Seats',
                    'Seat ${seats.join(', ')} (${seats.length} x ${AppTokens.formatUgx(pricePerSeat)})',
                  ),
                  const Divider(color: Colors.white10, height: 22),
                  _buildSummaryRow('Platform Fee', 'UGX 0'),
                  const Divider(color: Colors.white10, height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          AppTokens.formatUgx(totalAmount),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFeatures: AppTokens.tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: SizedBox(
            height: 60,
            child: _SlideToPayButton(
              key: ValueKey<int>(_sliderResetSeed),
              isProcessing: _isProcessing,
              label: 'Slide to Pay ${AppTokens.formatUgx(totalAmount)}',
              onSlideCompleted: () => _handleCheckout(
                totalAmount: totalAmount,
                walletBalance: walletBalance,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard({
    required int walletBalance,
    required int totalAmount,
    required bool isLoadingBalance,
  }) {
    final bool isSelected = _selectedMethod == 'WALLET';
    final bool hasEnough = walletBalance >= totalAmount;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = 'WALLET'),
      child: AnimatedContainer(
        duration: AppTokens.fastDuration,
        curve: AppTokens.easeOutCurve,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTokens.primaryDark.withValues(alpha: 0.65),
              AppTokens.primary.withValues(alpha: 0.45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTokens.accent
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Twende Wallet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isLoadingBalance
                        ? 'Loading balance...'
                        : 'Balance: ${AppTokens.formatUgx(walletBalance)}',
                    style: GoogleFonts.poppins(
                      color: hasEnough ? Colors.white70 : Colors.orangeAccent,
                      fontSize: 12,
                      fontFeatures: AppTokens.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasEnough && !isLoadingBalance)
              TextButton(
                onPressed: () => context.push('/wallet/deposit'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Top Up',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isSelected)
              const Icon(Icons.check_circle, color: AppTokens.accent)
            else
              const Icon(Icons.circle_outlined, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticMethodCard({
    required String id,
    required String name,
    required String subtitle,
    required Color accentColor,
    required Color iconColor,
    required IconData icon,
  }) {
    final bool isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: AppTokens.fastDuration,
        curve: AppTokens.easeOutCurve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTokens.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideToPayButton extends StatefulWidget {
  final VoidCallback onSlideCompleted;
  final bool isProcessing;
  final String label;

  const _SlideToPayButton({
    super.key,
    required this.onSlideCompleted,
    required this.isProcessing,
    required this.label,
  });

  @override
  State<_SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<_SlideToPayButton> {
  double _dragValue = 0.0;
  double _maxWidth = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final bool busy = _submitted || widget.isProcessing;

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.primaryDark, AppTokens.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTokens.primaryDark.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Text(
                    busy ? 'Processing Payment...' : widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFeatures: AppTokens.tabularFigures,
                    ),
                  ),
                ),
              ),
              if (!busy)
                Positioned(
                  left: _dragValue,
                  top: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragValue = (_dragValue + details.delta.dx)
                            .clamp(0.0, _maxWidth - 60);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      final double velocity =
                          details.primaryVelocity ?? 0.0;
                      if (_dragValue > _maxWidth * 0.65 || velocity > 650) {
                        setState(() {
                          _dragValue = _maxWidth - 60;
                          _submitted = true;
                        });
                        widget.onSlideCompleted();
                      } else {
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
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTokens.primaryDark,
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

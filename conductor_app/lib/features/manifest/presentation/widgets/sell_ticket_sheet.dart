import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/api/api_client.dart';
import 'package:twende_conductor_app/core/api/api_endpoints.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';
import 'package:twende_conductor_app/features/manifest/presentation/screens/conductor_ticket_receipt_screen.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/seat_selection_modal.dart';

class SellTicketSheet extends StatefulWidget {
  final Map<String, dynamic>? trip;
  final List<dynamic> manifest;
  final VoidCallback onSuccess;
  final int? initialSeatNumber;

  const SellTicketSheet({
    super.key,
    required this.trip,
    required this.manifest,
    required this.onSuccess,
    this.initialSeatNumber,
  });

  @override
  State<SellTicketSheet> createState() => _SellTicketSheetState();
}

class _SellTicketSheetState extends State<SellTicketSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  int? _selectedSeat;
  String _paymentMethod = 'CASH';
  bool _isLoading = false;
  List<int> _availableSeats = <int>[];

  int get _totalSeats =>
      (widget.trip?['total_seats'] as num?)?.toInt() ??
      (widget.manifest.isNotEmpty ? widget.manifest.length : 60);

  @override
  void initState() {
    super.initState();
    _calculateAvailableSeats();
    if (widget.initialSeatNumber != null &&
        _availableSeats.contains(widget.initialSeatNumber)) {
      _selectedSeat = widget.initialSeatNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _calculateAvailableSeats() {
    final Set<int> occupied = <int>{};
    for (final dynamic item in widget.manifest) {
      if (item is Map) {
        final String status = AppTokens.normalizeSeatStatus(item['status']);
        final int? seatNum = (item['seat_number'] as num?)?.toInt();
        if (seatNum != null && status != 'AVAILABLE') {
          occupied.add(seatNum);
        }
      }
    }

    _availableSeats = <int>[];
    for (int i = 1; i <= _totalSeats; i++) {
      if (!occupied.contains(i)) {
        _availableSeats.add(i);
      }
    }
  }

  Future<void> _processSale() async {
    final int? tripId = (widget.trip?['id'] as num?)?.toInt();
    final String passengerName = _nameController.text.trim();
    final String passengerPhone = _phoneController.text.trim();

    if (tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active trip selected.'),
          backgroundColor: AppTokens.danger,
        ),
      );
      return;
    }

    if (_selectedSeat == null || passengerName.isEmpty || passengerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a seat and enter passenger name & phone.'),
          backgroundColor: AppTokens.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.dio.post(
        '${ApiEndpoints.conductorUrl}/sell_ticket',
        data: <String, dynamic>{
          'trip_id': tripId,
          'seat_number': _selectedSeat,
          'passenger_name': passengerName,
          'passenger_phone': passengerPhone,
          'payment_method': _paymentMethod,
        },
      );

      final Map<String, dynamic> data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      if (data['success'] == true) {
        if (!mounted) return;
        final NavigatorState navigator = Navigator.of(context);
        navigator.pop();
        widget.onSuccess();

        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ConductorTicketReceiptScreen(
              ticketDetails: <String, dynamic>{
                'trip_id': tripId,
                'booking_id': data['booking_id'],
                'seat_number': data['seat_number'] ?? _selectedSeat,
                'qr_code_data': data['qr_code_data'],
                'passenger_name': passengerName,
                'passenger_phone': passengerPhone,
                'payment_method': data['payment_method'] ?? _paymentMethod,
                'route_name': widget.trip?['route_name'] ?? 'Scheduled Route',
                'bus_plate': widget.trip?['bus_plate'] ?? 'Twende Bus',
                'travel_date': widget.trip?['departure_time'] ?? 'Today',
                'price': widget.trip?['price'] ?? 30000,
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.extractErrorMessage(
                e,
                fallback: 'Could not complete ticket sale.',
              ),
            ),
            backgroundColor: AppTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSeatPicker() async {
    final List<int> allSeats = List<int>.generate(_totalSeats, (int i) => i + 1);
    final List<int> bookedSeats =
        allSeats.where((int s) => !_availableSeats.contains(s)).toList();

    final int? result = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Seat Selection',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: AppTokens.normalDuration,
      pageBuilder: (
        BuildContext ctx,
        Animation<double> anim1,
        Animation<double> anim2,
      ) {
        return SeatSelectionModal(
          bookedSeats: bookedSeats,
          totalSeats: _totalSeats,
          initiallySelectedSeat: _selectedSeat,
        );
      },
      transitionBuilder: (
        BuildContext ctx,
        Animation<double> anim1,
        Animation<double> anim2,
        Widget child,
      ) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );

    if (result != null && mounted) {
      setState(() => _selectedSeat = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedPrice = AppTokens.formatUgx(
      widget.trip?['price'] ?? 30000,
    );
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sell Walk-In Ticket',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.trip?['route_name'] ?? 'Active Trip'} • ${widget.trip?['bus_plate'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Assigned Seat (${_availableSeats.length} free)',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openSeatPicker,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: AppTokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedSeat != null
                                ? AppTokens.primary
                                : AppTokens.border,
                            width: _selectedSeat != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              _selectedSeat != null
                                  ? 'Seat #$_selectedSeat'
                                  : 'Tap to choose an available seat',
                              style: GoogleFonts.poppins(
                                color: _selectedSeat != null
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontFeatures: AppTokens.tabularFigures,
                              ),
                            ),
                            Icon(
                              Icons.event_seat_rounded,
                              color: _selectedSeat != null
                                  ? AppTokens.accent
                                  : Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Passenger Information',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDeco('Full Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDeco('Phone Number', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Payment Method',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        _paymentOption('CASH', Icons.payments_outlined),
                        const SizedBox(width: 12),
                        _paymentOption('MOMO', Icons.phone_android_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTokens.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTokens.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Ticket Fare',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          Text(
                            formattedPrice,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFeatures: AppTokens.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _processSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          disabledBackgroundColor:
                              AppTokens.primary.withValues(alpha: 0.4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_2_rounded),
                        label: Text(
                          _isLoading
                              ? 'Issuing Ticket...'
                              : 'Confirm Sale & Issue QR',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(String value, IconData icon) {
    final bool selected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTokens.primary : AppTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTokens.accent : AppTokens.border,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white54),
      prefixIcon: Icon(icon, color: AppTokens.accent),
      filled: true,
      fillColor: AppTokens.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.primary, width: 1.5),
      ),
    );
  }
}

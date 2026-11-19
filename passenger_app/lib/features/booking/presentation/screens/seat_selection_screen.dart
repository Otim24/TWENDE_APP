import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';

class SeatSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> busDetails;

  const SeatSelectionScreen({super.key, required this.busDetails});

  @override
  ConsumerState<SeatSelectionScreen> createState() =>
      _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends ConsumerState<SeatSelectionScreen> {
  late Map<String, dynamic> _tripData;
  List<int> _seatLayout = <int>[];
  Set<int> _bookedSeats = <int>{};
  final Set<int> _selectedSeats = <int>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tripData = Map<String, dynamic>.from(widget.busDetails);
    _applyTripPayload(_tripData);
    _fetchLiveSeatMap();
  }

  int get _tripId =>
      int.tryParse((_tripData['id'] ?? widget.busDetails['id'] ?? '1').toString()) ??
      1;

  void _applyTripPayload(Map<String, dynamic> data) {
    final dynamic rawLayout = data['seat_layout'];
    if (rawLayout is List && rawLayout.isNotEmpty) {
      _seatLayout = rawLayout
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((s) => s > 0)
          .toList();
    } else {
      final int total =
          int.tryParse((data['total_seats'] ?? '60').toString()) ?? 60;
      _seatLayout = List<int>.generate(total, (i) => i + 1);
    }

    final dynamic rawBooked = data['booked_seats'];
    if (rawBooked is List) {
      _bookedSeats = rawBooked
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((s) => s > 0)
          .toSet();
    }
    _selectedSeats.removeWhere((s) => _bookedSeats.contains(s));
  }

  Future<void> _fetchLiveSeatMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final Map<String, dynamic> fresh =
          await ref.read(bookingRepositoryProvider).getTripDetails(_tripId);
      if (!mounted) return;
      setState(() {
        _tripData = <String, dynamic>{
          ..._tripData,
          ...fresh,
          if (fresh['bus'] is Map && fresh['bus']['plate'] != null)
            'bus_plate': fresh['bus']['plate'],
        };
        _applyTripPayload(_tripData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggleSeat(int seatNumber) {
    if (_bookedSeats.contains(seatNumber)) return;
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        _selectedSeats.add(seatNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int unitPrice = AppTokens.parseUgx(_tripData['price']);
    final List<int> sortedSelected = _selectedSeats.toList()..sort();
    final int totalAmount = sortedSelected.length * unitPrice;

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
          'Select Seats',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchLiveSeatMap,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Bus Front / Driver Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: double.infinity,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  'Driver / Front • ${(_tripData['bus_plate'] ?? 'Twende Bus')}',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ),

          // 2. Seat Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTokens.primary),
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.white24),
                        right: BorderSide(color: Colors.white24),
                      ),
                    ),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _seatLayout.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final int seatNum = _seatLayout[index];
                        final bool isBooked = _bookedSeats.contains(seatNum);
                        final bool isSelected =
                            _selectedSeats.contains(seatNum);
                        return GestureDetector(
                          onTap: isBooked ? null : () => _toggleSeat(seatNum),
                          child: _buildSeatTile(
                            seatNumber: seatNum,
                            isBooked: isBooked,
                            isSelected: isSelected,
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // 3. Legend, Selected Summary & Checkout Button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(AppTokens.available, 'Available', true),
                    _buildLegendItem(AppTokens.selected, 'Selected', false),
                    _buildLegendItem(AppTokens.booked, 'Booked', false),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sortedSelected.isEmpty
                            ? 'Tap seats above to select'
                            : 'Seats: ${sortedSelected.join(', ')}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFeatures: AppTokens.tabularFigures,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppTokens.formatUgx(totalAmount),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFeatures: AppTokens.tabularFigures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sortedSelected.isEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please select at least one seat'),
                              ),
                            );
                          }
                        : () {
                            context.push(
                              '/payment',
                              extra: <String, dynamic>{
                                'busDetails': _tripData,
                                'seatCount': sortedSelected.length,
                                'selectedSeats': sortedSelected,
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sortedSelected.isEmpty
                          ? Colors.white12
                          : AppTokens.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      sortedSelected.isEmpty
                          ? 'Select a Seat to Continue'
                          : 'Proceed to Pay (${sortedSelected.length} ${sortedSelected.length == 1 ? 'Seat' : 'Seats'})',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatTile({
    required int seatNumber,
    required bool isBooked,
    required bool isSelected,
  }) {
    final Color bgColor = isBooked
        ? AppTokens.booked.withValues(alpha: 0.45)
        : (isSelected ? AppTokens.selected : AppTokens.available);

    return AnimatedContainer(
      duration: AppTokens.fastDuration,
      curve: AppTokens.easeOutCurve,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : (isBooked ? Colors.transparent : Colors.white24),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBooked ? Icons.lock_outline_rounded : Icons.event_seat_rounded,
            color: isBooked
                ? Colors.white38
                : (isSelected ? Colors.white : Colors.white70),
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            '$seatNumber',
            style: GoogleFonts.outfit(
              color: isBooked ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFeatures: AppTokens.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool hasBorder) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.white38) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.outfit(color: Colors.white70)),
      ],
    );
  }
}

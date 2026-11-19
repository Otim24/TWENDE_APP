import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _isUpcoming = true;

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'TBD';
    try {
      final DateTime date = DateTime.parse(isoString).toLocal();
      final DateTime now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'Today';
      }

      final DateTime tomorrow = now.add(const Duration(days: 1));
      if (date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day) {
        return 'Tomorrow';
      }

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
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return 'TBD';
    try {
      final DateTime date = DateTime.parse(isoString).toLocal();
      final int hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final String ampm = date.hour >= 12 ? 'PM' : 'AM';
      final String min = date.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    } catch (_) {
      return isoString;
    }
  }

  void _openBookingReceipt(Map<String, dynamic> booking) {
    final Map<String, dynamic> trip = (booking['trip'] is Map)
        ? (booking['trip'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final String deptIso = (trip['departure_time'] ?? '').toString();
    final String routeName = (trip['route_name'] ??
            '${trip['origin'] ?? 'Kampala'} - ${trip['destination'] ?? 'Gulu'}')
        .toString();
    final int seatNum =
        int.tryParse((booking['seat_number'] ?? '1').toString()) ?? 1;
    final int tripId = int.tryParse((trip['id'] ?? '1').toString()) ?? 1;

    context.push(
      '/receipt',
      extra: <String, dynamic>{
        'id': booking['id'],
        'trip_id': tripId,
        'busCompany': 'Twende Express',
        'bus_plate': (trip['bus_plate'] ?? 'UBA 123X').toString(),
        'route': routeName,
        'date': _formatDate(deptIso),
        'departureTime': _formatTime(deptIso),
        'totalPrice': trip['price'],
        'seatCount': 1,
        'seat_number': seatNum,
        'seat_numbers': <int>[seatNum],
        'qr_code_data': booking['qr_code_data'],
        'bookings': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': booking['id'],
            'trip_id': tripId,
            'seat_number': seatNum,
            'status': booking['status'],
            'qr_code_data': booking['qr_code_data'],
            'price': trip['price'],
          },
        ],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(myTripsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'Your Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () => ref.invalidate(myTripsProvider),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle Switch
            GlassContainer(
              padding: const EdgeInsets.all(4),
              borderRadius: 30,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUpcoming = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isUpcoming
                              ? AppTokens.primaryDark
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            'Upcoming',
                            style: GoogleFonts.poppins(
                              color:
                                  _isUpcoming ? Colors.white : Colors.white54,
                              fontWeight: _isUpcoming
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUpcoming = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isUpcoming
                              ? AppTokens.primaryDark
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            'History',
                            style: GoogleFonts.poppins(
                              color:
                                  !_isUpcoming ? Colors.white : Colors.white54,
                              fontWeight: !_isUpcoming
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  final List<Map<String, dynamic>> filteredTrips = trips
                      .whereType<Map>()
                      .map((e) => e.cast<String, dynamic>())
                      .where((t) {
                    try {
                      final Map<String, dynamic> tripData =
                          (t['trip'] as Map).cast<String, dynamic>();
                      final DateTime deptTime =
                          DateTime.parse(tripData['departure_time'].toString());
                      if (_isUpcoming) {
                        return deptTime.isAfter(
                          DateTime.now().subtract(const Duration(hours: 2)),
                        );
                      } else {
                        return deptTime.isBefore(DateTime.now());
                      }
                    } catch (_) {
                      return true;
                    }
                  }).toList();

                  if (filteredTrips.isEmpty) {
                    return Center(
                      child: Text(
                        _isUpcoming
                            ? 'No upcoming trips booked yet.'
                            : 'No past trips yet.',
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTokens.primary,
                    onRefresh: () async {
                      ref.invalidate(myTripsProvider);
                      await ref.read(myTripsProvider.future);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> booking =
                            filteredTrips[index];
                        final Map<String, dynamic> trip =
                            (booking['trip'] as Map).cast<String, dynamic>();
                        final String deptIso =
                            (trip['departure_time'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: GestureDetector(
                            onTap: () => _openBookingReceipt(booking),
                            child: _buildTripTicket(
                              date: _formatDate(deptIso),
                              time: _formatTime(deptIso),
                              route:
                                  '${trip['origin'] ?? 'Kampala'} ➔ ${trip['destination'] ?? 'Gulu'}',
                              price: AppTokens.formatUgx(trip['price']),
                              seatNumber:
                                  (booking['seat_number'] ?? '').toString(),
                              status: (booking['status'] ?? 'PAID').toString(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(myTripsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTicket({
    required String date,
    required String time,
    required String route,
    required String price,
    required String seatNumber,
    required String status,
  }) {
    final bool isBoarded =
        AppTokens.normalizeSeatStatus(status) == 'OCCUPIED';

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    color: AppTokens.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFeatures: AppTokens.tabularFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(
              width: 1,
              height: 44,
              color: Colors.white24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isBoarded
                              ? AppTokens.occupied.withValues(alpha: 0.3)
                              : AppTokens.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Seat #$seatNumber • ${isBoarded ? 'BOARDED' : 'PAID'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: AppTokens.tabularFigures,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          price,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFeatures: AppTokens.tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

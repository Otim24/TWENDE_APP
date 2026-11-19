import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';

class TicketReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const TicketReceiptScreen({
    super.key,
    required this.bookingDetails,
  });

  @override
  State<TicketReceiptScreen> createState() => _TicketReceiptScreenState();
}

class _TicketReceiptScreenState extends State<TicketReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  int _activeTicketIndex = 0;

  List<Map<String, dynamic>> get _ticketEntries {
    final dynamic rawBookings = widget.bookingDetails['bookings'];
    if (rawBookings is List && rawBookings.isNotEmpty) {
      return rawBookings
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }

    final dynamic rawSeats = widget.bookingDetails['seat_numbers'];
    final List<int> seats = rawSeats is List
        ? rawSeats
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((s) => s > 0)
            .toList()
        : <int>[
            int.tryParse(
                  (widget.bookingDetails['seat_number'] ?? '1').toString(),
                ) ??
                1,
          ];

    final String singleQr =
        (widget.bookingDetails['qr_code_data'] ?? '').toString();
    final int tripId =
        int.tryParse((widget.bookingDetails['trip_id'] ?? '1').toString()) ?? 1;

    return seats
        .map(
          (seat) => <String, dynamic>{
            'id': widget.bookingDetails['id'] ?? seat,
            'trip_id': tripId,
            'seat_number': seat,
            'qr_code_data':
                singleQr.isNotEmpty ? singleQr : 'TICKET-$tripId-$seat',
            'price': widget.bookingDetails['totalPrice'],
          },
        )
        .toList();
  }

  Future<void> _shareTicket({
    required String qrData,
    required String route,
    required String date,
    required String time,
    required String busPlate,
    required String seatLabel,
  }) async {
    final String shareText = '''
Twende Bus E-Ticket

Route: $route
Bus Plate: $busPlate
Date: $date
Departure: $time
Seat(s): $seatLabel
Verification QR: $qrData

Present this QR code to the Twende conductor when boarding.
''';

    await Share.share(shareText, subject: 'Twende Ticket: $route');
  }

  Future<void> _downloadTicket() async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final RenderRepaintBoundary? boundary = _receiptKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes, album: 'Twende Tickets');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ticket saved to Gallery!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save ticket: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTokens.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tickets = _ticketEntries;
    final int safeIndex =
        _activeTicketIndex.clamp(0, tickets.isEmpty ? 0 : tickets.length - 1);
    final Map<String, dynamic> activeTicket =
        tickets.isNotEmpty ? tickets[safeIndex] : <String, dynamic>{};

    final String busCompany =
        (widget.bookingDetails['busCompany'] ?? 'Twende Express').toString();
    final String busPlate =
        (widget.bookingDetails['bus_plate'] ?? 'UBA 123X').toString();
    final String route =
        (widget.bookingDetails['route'] ?? 'Kampala - Gulu').toString();
    final String date =
        (widget.bookingDetails['date'] ?? 'Scheduled').toString();
    final String time =
        (widget.bookingDetails['departureTime'] ?? '08:00 AM').toString();
    final int tripId = int.tryParse(
          (activeTicket['trip_id'] ?? widget.bookingDetails['trip_id'] ?? '1')
              .toString(),
        ) ??
        1;

    final List<String> allSeats = tickets
        .map((t) => (t['seat_number'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    final String allSeatsLabel =
        allSeats.isEmpty ? '1' : allSeats.join(', ');
    final String currentSeat =
        (activeTicket['seat_number'] ?? allSeatsLabel).toString();
    final String qrCodeData = (activeTicket['qr_code_data'] ??
            widget.bookingDetails['qr_code_data'] ??
            'TICKET-$tripId-$currentSeat')
        .toString();
    final String ticketIdLabel = activeTicket['id'] != null
        ? 'TWD-${activeTicket['id']}'
        : 'TWD-$tripId-$currentSeat';
    final String formattedTotal =
        AppTokens.formatUgx(widget.bookingDetails['totalPrice']);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'E-Ticket Receipt',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Multi-seat switcher so every seat's individual HMAC QR code can be scanned
            if (tickets.length > 1) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap seat to view its individual boarding QR (${tickets.length} seats booked):',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final bool selected = idx == safeIndex;
                    final String seatNum =
                        (tickets[idx]['seat_number'] ?? '${idx + 1}')
                            .toString();
                    return GestureDetector(
                      onTap: () => setState(() => _activeTicketIndex = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTokens.selected
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white24,
                          ),
                        ),
                        child: Text(
                          'Seat #$seatNum',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFeatures: AppTokens.tabularFigures,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            RepaintBoundary(
              key: _receiptKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            route,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shareTicket(
                            qrData: qrCodeData,
                            route: route,
                            date: date,
                            time: time,
                            busPlate: busPlate,
                            seatLabel: allSeatsLabel,
                          ),
                          icon: const Icon(
                            Icons.share,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date • $time',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey, thickness: 0.5, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDetailItem('Operator', busCompany),
                        _buildDetailItem('Seat Number', 'Seat #$currentSeat'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDetailItem('Ticket Ref', ticketIdLabel),
                        _buildDetailItem('Bus Plate', busPlate),
                      ],
                    ),
                    if (tickets.length > 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildDetailItem('All Booked Seats', allSeatsLabel),
                          _buildDetailItem(
                            'Active QR',
                            'Seat $currentSeat (${safeIndex + 1}/${tickets.length})',
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey, thickness: 0.5, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid:',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            formattedTotal,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE91E63),
                              fontFeatures: AppTokens.tabularFigures,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.25),
                          ),
                        ),
                        child: QrImageView(
                          data: qrCodeData,
                          version: QrVersions.auto,
                          size: 168.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'HMAC Verified Boarding Pass • Seat #$currentSeat',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this QR code to the conductor when boarding.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            // Track Bus Live CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/tracking',
                    extra: <String, dynamic>{
                      'id': tripId,
                      'route_name': route,
                      'bus_plate': busPlate,
                    },
                  );
                },
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  'Track Bus Live on Map',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.selected,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Actions Row: Done / Home + Save Image
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _downloadTicket,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTokens.primaryDark, AppTokens.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Save Image',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTokens.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class ConductorTicketReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> ticketDetails;
  final GlobalKey _receiptKey = GlobalKey();

  ConductorTicketReceiptScreen({
    super.key,
    required this.ticketDetails,
  });

  String get _bookingId =>
      (ticketDetails['booking_id'] ?? ticketDetails['id'] ?? 'N/A').toString();

  String get _passengerName =>
      (ticketDetails['passenger_name'] ?? 'Walk-in Passenger').toString();

  String get _seatNumber =>
      (ticketDetails['seat_number'] ?? 'N/A').toString();

  String get _routeName =>
      (ticketDetails['route_name'] ?? 'Scheduled Route').toString();

  String get _busPlate =>
      (ticketDetails['bus_plate'] ?? 'Twende Bus').toString();

  String get _paymentMethod =>
      (ticketDetails['payment_method'] ?? 'CASH').toString();

  String get _qrPayload {
    final String raw = (ticketDetails['qr_code_data'] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      return raw;
    }
    return _bookingId;
  }

  Future<void> _shareTicket() async {
    final String formattedPrice = AppTokens.formatUgx(ticketDetails['price']);
    final String shareText = '''
Twende Bus E-Ticket
Booking ID: #$_bookingId
Route: $_routeName ($_busPlate)
Passenger: $_passengerName
Seat: #$_seatNumber
Amount Paid: $formattedPrice ($_paymentMethod)
Verification Code: $_qrPayload
''';

    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Twende Ticket #$_bookingId - $_passengerName',
      ),
    );
  }

  Future<void> _downloadTicket(BuildContext context) async {
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ticket saved to gallery.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTokens.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
    final String formattedPrice = AppTokens.formatUgx(ticketDetails['price']);

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ticket Issued',
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
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
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _routeName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Booking #$_bookingId • $_busPlate',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontFeatures: AppTokens.tabularFigures,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _shareTicket,
                          icon: const Icon(
                            Icons.share_outlined,
                            color: AppTokens.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black12, thickness: 1, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        _buildDetailItem('Passenger', _passengerName),
                        const SizedBox(width: 12),
                        _buildDetailItem('Seat Number', 'Seat #$_seatNumber'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        _buildDetailItem('Amount Paid', formattedPrice),
                        const SizedBox(width: 12),
                        _buildDetailItem('Payment', '$_paymentMethod • PAID'),
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
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        child: QrImageView(
                          data: _qrPayload,
                          version: QrVersions.auto,
                          size: 160.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'HMAC-Signed Boarding QR Code',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadTicket(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      'Save Image',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTokens.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

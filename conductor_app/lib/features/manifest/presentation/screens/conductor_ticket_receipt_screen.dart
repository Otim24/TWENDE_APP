import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class ConductorTicketReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> ticketDetails;
  final GlobalKey _receiptKey = GlobalKey();
  
  ConductorTicketReceiptScreen({
    super.key,
    required this.ticketDetails,
  });

  Future<void> _shareTicket() async {
    final String shareText = '''
🎫 *Twende Bus Ticket* 🎫

*Passenger:* ${ticketDetails['passenger_name']}
*Seat:* ${ticketDetails['seat_number']}
*Route:* ${ticketDetails['route_name'] ?? 'Route Details'}
*Date:* ${ticketDetails['travel_date']}
*Trip ID:* ${ticketDetails['trip_id']}

Scan this QR code to verify.
Safe travels! 🚍
''';

    await Share.share(shareText, subject: 'Twende Ticket: ${ticketDetails['passenger_name']}');
  }

  Future<void> _downloadTicket(BuildContext context) async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      RenderRepaintBoundary? boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes, album: 'Twende Tickets');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ticket saved to Gallery! 📸", style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save ticket: $e", style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data
    final passengerName = ticketDetails['passenger_name'] ?? 'Unknown';
    final seatNumber = ticketDetails['seat_number']?.toString() ?? 'N/A';
    final amount = ticketDetails['price']?.toString() ?? '0';
    final ticketId = "TWD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context), 
        ),
        title: Text(
          "Ticket Issued",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Receipt Card
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
                        Text(
                          "Twende Bus",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                         IconButton(
                          onPressed: _shareTicket,
                          icon: const Icon(Icons.share, color: Color(0xFFE91E63)), 
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ticket ID: $ticketId",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, thickness: 0.5, height: 1),
                    const SizedBox(height: 20),
                    
                    // Details Grid
                    Row(
                      children: [
                        _buildDetailItem("Passenger", passengerName),
                        _buildDetailItem("Seat Number", seatNumber),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildDetailItem("Price", "UGX $amount"),
                        _buildDetailItem("Status", "PAID"),
                      ],
                    ),
                    
                    const SizedBox(height: 32),

                    // QR Code
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: QrImageView(
                          data: ticketId, // In real app, this would be a verifiable hash
                          version: QrVersions.auto,
                          size: 150.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                     Center(
                       child: Text(
                        "Scan to Verify",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
                      ),
                     ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      "New Sale",
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Download Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _downloadTicket(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4A148C),
                            Color(0xFF7B1FA2),
                          ],
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
                      alignment: Alignment.center,
                      child: Text(
                        "Download",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

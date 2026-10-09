import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class TicketReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;
  final GlobalKey _receiptKey = GlobalKey(); // Key for capturing image
  
  TicketReceiptScreen({
    super.key,
    required this.bookingDetails,
  });

  Future<void> _shareTicket(BuildContext context, String ticketId, String route, String date, String time, String busCompany, String seatNumbers) async {
    final String shareText = '''
🎫 *Twende Bus Ticket* 🎫

*Route:* $route
*Bus:* $busCompany
*Date:* $date
*Time:* $time
*Seat(s):* $seatNumbers
*Ticket ID:* $ticketId

Show this message or the QR code to the conductor when boarding.
Safe travels! 🚍
''';

    await Share.share(shareText, subject: 'Twende Ticket: $route');
  }

  Future<void> _downloadTicket(BuildContext context) async {
    try {
      // 1. Check Permissions (Gal handles mostly, but good to be safe)
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 2. Capture Image from RepaintBoundary
      RenderRepaintBoundary? boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // Higher pixel ratio for better quality
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 3. Save to Gallery
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
    // Extract data with fallbacks
    final busCompany = bookingDetails['busCompany'] ?? 'Twende Bus';
    final route = bookingDetails['route'] ?? 'Kampala - Busia';
    final date = bookingDetails['date'] ?? '24 Jan 2026';
    final time = bookingDetails['departureTime'] ?? '08:00 AM';
    final totalPrice = bookingDetails['totalPrice'] ?? '50000';
    // Generate a consistent pseudo-random ticket ID based on time or passed data
    final ticketId = "TWD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    final seatNumbers = "04, 05"; // Placeholder for now

    return Scaffold(
      backgroundColor: Colors.black, // Dark background as requested
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          "Reservation Details",
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
            // 1. Details Card (Wrapped in RepaintBoundary for Capture)
            RepaintBoundary(
              key: _receiptKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Paper receipt look
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Wrap content
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          route,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        // Don't show Share icon in the downloaded image ideally, but acceptable for now. 
                        // Or we can hide it conditionally. For simplicity, we keep it.
                         IconButton(
                          onPressed: () => _shareTicket(context, ticketId, route, date, time, busCompany, seatNumbers),
                          icon: const Icon(Icons.share, color: Color(0xFFE91E63)), 
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$date, $time",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, thickness: 0.5, height: 1),
                    const SizedBox(height: 20),
                    
                    // Details Grid
                    Row(
                      children: [
                        _buildDetailItem("Bus Name", busCompany),
                        _buildDetailItem("Seat Number", seatNumbers),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildDetailItem("Ticket ID", ticketId),
                        _buildDetailItem("Bus Number", "UBK 123Z"), // Placeholder
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildDetailItem("Arrival", time),
                        _buildDetailItem("Drop", "12:00 PM"),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, thickness: 0.5, height: 1),
                    const SizedBox(height: 16),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total:",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "UGX $totalPrice",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE91E63), // Pink accent
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),

                    // 2. Embed QR Code inside the capture for the image logic
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: QrImageView(
                          data: ticketId,
                          version: QrVersions.auto,
                          size: 150.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                     Center(
                       child: Text(
                        "Scannable E-Ticket",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                                           ),
                     ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              "Note: Just show your QR code while boarding the bus.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70, // Start white for dark bg
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 3. Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white), // White border
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Download Button (Call _downloadTicket)
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
                        borderRadius: BorderRadius.circular(30), // Pill shape
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
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.black, 
              fontSize: 14, 
              fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }
}

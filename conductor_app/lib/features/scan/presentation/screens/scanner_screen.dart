import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );
  
  bool _isScanning = true;
  bool _isProcessing = false;
  String? _statusMessage;
  bool? _isSuccess;
  Timer? _resetTimer;
  
  // Backend URL (Emulator or Physical Device)
  // For physical device, replace 10.0.2.2 with actual IP e.g., 192.168.1.5
  final String _baseUrl = 'http://10.0.2.2:8000/api/v1'; 

  @override
  void dispose() {
    _controller.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyTicket(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _isScanning = false; // Pause scanning visual feedback if needed
    });

    try {
      // Dio Call
      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/conductor/verify_ticket', 
        data: {'ticket_data': code}
      );

      final valid = response.data['valid'] as bool;
      final message = response.data['message'] as String;
      
      _showResult(valid, message);

    } catch (e) {
      _showResult(false, "Network Error: ${e.toString()}");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResult(bool success, String message) {
    setState(() {
      _isSuccess = success;
      _statusMessage = message;
    });

    // Auto-dismiss after 3 seconds
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSuccess = null;
          _statusMessage = null;
          _isScanning = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (!_isScanning || _isProcessing || _isSuccess != null) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _verifyTicket(barcodes.first.rawValue!);
              }
            },
          ),

          // 2. Overlay (Semi-transparent Black with Cutout)
          // Simplified implementation using Containers around a center transparent box
          Column(
            children: [
              Expanded(child: Container(color: Colors.black54)),
              Row(
                children: [
                  Expanded(child: Container(color: Colors.black54)),
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      // transparent center
                    ),
                    child: Center(
                       // Pulse effect or red line can go here
                       child: _isProcessing 
                         ? const CircularProgressIndicator(color: Colors.white)
                         : Container(
                             width: 260, height: 2, color: Colors.red.withOpacity(0.5)
                           ),
                    ),
                  ),
                  Expanded(child: Container(color: Colors.black54)),
                ],
              ),
              Expanded(child: Container(
                color: Colors.black54,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Place QR Code within the frame",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    // Flashlight Toggle
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: _controller.torchState,
                        builder: (context, state, child) {
                          return Icon(
                            state == TorchState.on ? Icons.flash_on : Icons.flash_off, 
                            color: Colors.white, size: 30
                          );
                        },
                      ),
                      onPressed: () => _controller.toggleTorch(),
                    ),
                  ],
                ),
              )),
            ],
          ),
          
          // 3. Status Alert Overlay (Green/Red)
          if (_isSuccess != null)
            Container(
              color: _isSuccess! ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C), // Strong Green or Red
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSuccess! ? Icons.check_circle_outline : Icons.error_outline,
                    color: Colors.white,
                    size: 100,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isSuccess! ? "ALLOWED" : "STOP",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? "",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

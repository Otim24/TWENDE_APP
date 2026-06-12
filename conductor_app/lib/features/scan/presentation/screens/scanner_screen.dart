import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/features/manifest/presentation/screens/conductor_home_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );
  
  late AnimationController _animController;
  late Animation<double> _animation;
  
  bool _isScanning = true;
  bool _isProcessing = false;
  
  // Feedback
  String? _feedbackMessage;
  bool? _feedbackSuccess;
  Timer? _feedbackTimer;
  
  // Using ADB Reverse Tunnel for reliability
  final String _baseUrl = 'http://172.20.11.181:8000/api/v1'; 

  @override
  void initState() {
    super.initState();
    // Laser Animation
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: 280).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _animController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyTicket(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/conductor/verify_ticket', 
        data: {'ticket_data': code} // Sending as string
      );

      final valid = response.data['valid'] as bool;
      final message = response.data['message'] as String;
      
      _showFeedback(valid, message);

    } catch (e) {
      _showFeedback(false, "Network Error: ${e.toString()}");
    } finally {
      setState(() {
        _isProcessing = false;
        // Keep stopped for a moment if success? No, continues scanning but delays next scan via logic
      });
    }
  }

  void _showFeedback(bool success, String message) {
    setState(() {
      _feedbackSuccess = success;
      _feedbackMessage = message;
      // Pause laser
      _animController.stop(); 
    });

    // Vibration/Sound could happen here

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _feedbackSuccess = null;
          _feedbackMessage = null;
          _animController.repeat(reverse: true); // Resume laser
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
              if (_isProcessing || _feedbackSuccess != null) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _verifyTicket(barcodes.first.rawValue!);
              }
            },
          ),

          // 2. Dark Overlay with Cutout
          Container(
            decoration: ShapeDecoration(
              shape: OverlayShape(cutoutSize: 280),
            ),
          ),
          
          // 3. Laser Animation
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // Corners (You could add corner images here)
                  
                  // Moving Laser Line
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      if (_feedbackSuccess != null) return const SizedBox.shrink(); // Hide laser on result
                      return Positioned(
                        top: _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.redAccent.withOpacity(0.8), Colors.transparent]
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                            ]
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Processing Indicator
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ],
              ),
            ),
          ),

          // 4. Feedback Banner (Top Dropdown)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            top: _feedbackSuccess != null ? 50 : -150, // Slide in/out
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _feedbackSuccess == true ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Icon(
                    _feedbackSuccess == true ? Icons.check_circle : Icons.error_outline,
                    color: Colors.white, size: 32
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _feedbackSuccess == true ? "ALLOWED" : "STOP",
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          _feedbackMessage ?? "",
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Align QR Code within the frame",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, state, child) {
                        return Icon(
                          state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white, size: 30
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                    onPressed: () {
                         Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the Cutout Overlay
class OverlayShape extends ShapeBorder {
  final double cutoutSize;
  const OverlayShape({required this.cutoutSize});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: rect.center, width: cutoutSize, height: cutoutSize),
          const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path path = Path()..addRect(rect);
    final Path cutout = getInnerPath(rect);
    return Path.combine(PathOperation.difference, path, cutout);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()..color = Colors.black54; // Semi-transparent black
    canvas.drawPath(getOuterPath(rect), paint);
    
    // Draw white border around cutout
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: rect.center, width: cutoutSize, height: cutoutSize),
          const Radius.circular(16)
      ), 
      borderPaint
    );
  }
  
  @override
  ShapeBorder scale(double t) => this;
}

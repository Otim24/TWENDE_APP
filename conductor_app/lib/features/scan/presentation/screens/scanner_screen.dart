import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:twende_conductor_app/core/api/api_client.dart';
import 'package:twende_conductor_app/core/api/api_endpoints.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class ScannerScreen extends StatefulWidget {
  final int? tripId;

  const ScannerScreen({
    super.key,
    this.tripId,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  late final AnimationController _animController;
  late final Animation<double> _animation;

  bool _isProcessing = false;
  String? _feedbackMessage;
  bool? _feedbackSuccess;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 280).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
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
      final Map<String, dynamic> payload = <String, dynamic>{
        'ticket_data': code.trim(),
      };
      if (widget.tripId != null) {
        payload['trip_id'] = widget.tripId;
      }

      final response = await ApiClient.dio.post(
        '${ApiEndpoints.conductorUrl}/verify_ticket',
        data: payload,
      );

      final Map<String, dynamic> data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final bool valid = data['valid'] == true;
      final Map<String, dynamic>? details = data['booking_details'] is Map
          ? Map<String, dynamic>.from(data['booking_details'] as Map)
          : null;
      final String seatInfo =
          details != null && details['seat_number'] != null
              ? ' (Seat #${details['seat_number']} • ${details['passenger'] ?? ''})'
              : '';
      final String message =
          '${data['message'] ?? 'Ticket Verified.'}$seatInfo';

      _showFeedback(valid, message);
    } catch (e) {
      final String detail = ApiClient.extractErrorMessage(
        e,
        fallback: 'Invalid or unverifiable ticket.',
      );
      _showFeedback(false, detail);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showFeedback(bool success, String message) {
    if (!mounted) return;
    setState(() {
      _feedbackSuccess = success;
      _feedbackMessage = message;
      _animController.stop();
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _feedbackSuccess = null;
          _feedbackMessage = null;
          _animController.repeat(reverse: true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              if (_isProcessing || _feedbackSuccess != null) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _verifyTicket(barcodes.first.rawValue!);
              }
            },
          ),
          Container(
            decoration: const ShapeDecoration(
              shape: OverlayShape(cutoutSize: 280),
            ),
          ),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (BuildContext context, Widget? child) {
                      if (_feedbackSuccess != null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Colors.transparent,
                                AppTokens.accent.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppTokens.accent.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: AppTokens.normalDuration,
            curve: AppTokens.easeOutCurve,
            top: _feedbackSuccess != null ? 56 : -160,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _feedbackSuccess == true
                    ? AppTokens.success
                    : AppTokens.danger,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _feedbackSuccess == true
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _feedbackSuccess == true ? 'ALLOWED' : 'STOP',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _feedbackMessage ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Align passenger QR ticket inside the frame',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _controller.toggleTorch(),
                          icon: ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _controller,
                            builder: (
                              BuildContext context,
                              MobileScannerState state,
                              Widget? child,
                            ) {
                              return Icon(
                                state.torchState == TorchState.on
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: Colors.white,
                                size: 28,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OverlayShape extends ShapeBorder {
  final double cutoutSize;
  const OverlayShape({required this.cutoutSize});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutoutSize,
            height: cutoutSize,
          ),
          const Radius.circular(16),
        ),
      )
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
    final Paint paint = Paint()..color = Colors.black54;
    canvas.drawPath(getOuterPath(rect), paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutoutSize,
          height: cutoutSize,
        ),
        const Radius.circular(16),
      ),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

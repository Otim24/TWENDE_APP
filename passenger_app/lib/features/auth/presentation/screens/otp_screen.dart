
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:twende_passenger_app/features/auth/data/auth_repository.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  Future<void> _verifyOtp(String pin) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
        phone: widget.phone, 
        code: pin
      );
      // Success - Navigate to Splash Screen
      if (mounted) {
        context.go('/splash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        _pinController.clear(); // Clear on error
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Square glass tiles
        border: Border.all(color: Colors.white24),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow gradient to go behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.mail_lock_rounded, size: 60, color: Color(0xFFFFD740)),
                  const SizedBox(height: 24),
                  Text(
                    "Verify Number",
                    style: GoogleFonts.poppins(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter code sent via SMS to ${widget.phone}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  
                  const SizedBox(height: 48),

                  Pinput(
                    controller: _pinController,
                    focusNode: _focusNode,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: const Color(0xFF7C4DFF)),
                      ),
                    ),
                    onCompleted: _verifyOtp,
                    androidSmsAutofillMethod: AndroidSmsAutofillMethod.smsUserConsentApi,
                  ),

                  const SizedBox(height: 40),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                    
                  const Spacer(),
                  
                  TextButton(
                    onPressed: () {
                      // TODO: Resend OTP
                    },
                    child: const Text("Resend Code in 30s", style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

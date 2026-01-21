
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:twende_passenger_app/features/auth/data/auth_repository.dart';
import 'package:twende_passenger_app/core/widgets/glass_pill_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    final phone = "+256${_phoneController.text.trim()}"; // Ideally validate length
    if (_phoneController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone: phone);
      if (mounted) {
        context.push('/otp', extra: phone);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                  const Spacer(flex: 2),
                  
                  // Icon
                  const Icon(Icons.phone_iphone_rounded, size: 64, color: Color(0xFFFFD740))
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    "Enter Your Phone Number",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 48),

                  // Glass Pill Input
                  GlassPillInput(
                    controller: _phoneController,
                    hintText: "784 811 929",
                    icon: Icons.edit,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const Spacer(flex: 3),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A), // Deep Rich Purple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "CONTINUE",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white // If Purple bg, White text.
                            ),
                          ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  
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

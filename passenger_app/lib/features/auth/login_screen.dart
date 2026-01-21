
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (or Image)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E1E), // Dark background
                  Color(0xFF2A0B4E), // Subtle purple tint
                  Color(0xFF1E1E1E),
                ],
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title
                  Text(
                    "TWENDE",
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.5, end: 0),
                  
                  const SizedBox(height: 10),
                  Text(
                    "Move Freely.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 48),

                  // Glass Form
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Welcome Back",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        
                        // Phone Input
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            prefixText: "+256 ",
                            prefixIcon: Icon(Icons.phone, color: Colors.white54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        // Password Input
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock, color: Colors.white54),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement Login Logic
                            },
                            child: const Text("LOGIN"),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Create Account Link
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to Signup
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "New to Twende? ",
                        style: TextStyle(color: Colors.white60),
                        children: [
                          TextSpan(
                            text: "Create Account",
                            style: TextStyle(
                              color: Color(0xFF7C4DFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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

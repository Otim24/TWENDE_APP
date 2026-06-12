import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:twende_conductor_app/features/scan/presentation/screens/scanner_screen.dart';
import 'package:twende_conductor_app/features/manifest/presentation/screens/conductor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  // LAN Connection (Firewall Unblocked)
  final String _baseUrl = 'http://192.168.1.65:8000/api/v1/auth';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = Dio();
      final response = await dio.post('$_baseUrl/login', data: {
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        if (mounted) {
           Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => ConductorHomeScreen(
              userName: response.data['user_name'] ?? "Twende Crew",
            ))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is DioException && e.response != null) {
            _error = e.response?.data['detail'] ?? "Login failed";
          } else {
             // Show the RAW error to debug
             _error = "Err: ${e.toString()}";
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Title
                      Text(
                        "Twende Conductor",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white, 
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Gatekeeper Access",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white54, 
                        ),
                      ),
                      const SizedBox(height: 48), // Gap
                      
                      // Phone Input
                      TextField(
                        controller: _phoneController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          labelStyle: GoogleFonts.poppins(color: Colors.white70),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFE040FB)), 
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E), 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Input
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Password / PIN",
                          labelStyle: GoogleFonts.poppins(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFFE040FB)),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30), 
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 1.5),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (_error != null)
                        Text(
                          _error!,
                          style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        
                      const SizedBox(height: 32),
                      
                      Center(
                        child: SizedBox(
                          width: 200, 
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B1FA2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 5,
                              shadowColor: const Color(0xFF7B1FA2).withOpacity(0.5),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : Text("Login", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      
                      // Extra padding at bottom to bias center slightly upwards or ensure spacing
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

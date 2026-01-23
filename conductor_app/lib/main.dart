import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const TwendeConductorApp());
}

class TwendeConductorApp extends StatelessWidget {
  const TwendeConductorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twende Conductor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B1FA2)), // Purple base
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use Future.delayed to trigger navigation after animation
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        // Replace with Home Screen
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Black Bundle
      body: Center(
        child: Animate(
          effects: const [
            FadeEffect(duration: Duration(milliseconds: 1000), curve: Curves.easeIn),
            ScaleEffect(duration: Duration(milliseconds: 1000), curve: Curves.easeOutBack),
          ],
          child: Container(
             padding: const EdgeInsets.all(20),
             child: Image.asset(
               'assets/images/logo.jpg',
               width: 250, // Nice and big
             ),
          ),
        ),
      ),
    );
  }
}

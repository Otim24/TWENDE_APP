import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twende_passenger_app/core/storage/storage_service.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    _bootTimer = Timer(const Duration(milliseconds: 600), _checkAuthAndRoute);
  }

  Future<void> _checkAuthAndRoute() async {
    if (!mounted) return;
    String? token;
    try {
      token = await ref.read(storageServiceProvider).getToken();
    } catch (_) {
      token = null;
    }
    if (!mounted) return;
    if (token != null && token.trim().isNotEmpty) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Animate(
          effects: const [
            FadeEffect(
              duration: Duration(milliseconds: 300),
              curve: AppTokens.easeOutCurve,
            ),
            ScaleEffect(
              begin: Offset(0.95, 0.95),
              end: Offset(1.0, 1.0),
              duration: Duration(milliseconds: 300),
              curve: AppTokens.easeOutCurve,
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 220,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_bus_filled_rounded,
                size: 96,
                color: AppTokens.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twende_passenger_app/config/theme.dart';
import 'package:twende_passenger_app/features/auth/login_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TwendePassengerApp(),
    ),
  );
}

// Router Configuration
final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Add more routes here
  ],
);

class TwendePassengerApp extends ConsumerWidget {
  const TwendePassengerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Twende',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twende_passenger_app/config/theme.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/login_screen.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:twende_passenger_app/features/home/presentation/screens/home_wrapper.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/search_results_screen.dart';
import 'package:twende_passenger_app/features/wallet/presentation/screens/deposit_screen.dart';

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
      path: '/',
      redirect: (_, __) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String;
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeWrapper(),
    ),
    GoRoute(
      path: '/wallet/deposit',
      builder: (context, state) => const DepositScreen(),
    ),
    GoRoute(
      path: '/search_results',
      builder: (context, state) {
        final extras = state.extra as Map<String, String>;
        return SearchResultsScreen(
          fromLocation: extras['from'] ?? 'Unknown',
          toLocation: extras['to'] ?? 'Unknown',
        );
      },
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

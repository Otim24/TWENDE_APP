
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twende_passenger_app/config/theme.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/login_screen.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:twende_passenger_app/features/home/presentation/screens/home_wrapper.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/search_results_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/bus_details_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/seat_selection_screen.dart';
import 'package:twende_passenger_app/features/wallet/presentation/screens/deposit_screen.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:twende_passenger_app/features/payment/presentation/screens/payment_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/ticket_receipt_screen.dart';
import 'package:twende_passenger_app/features/wallet/presentation/screens/wallet_dashboard_screen.dart';

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
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800), // Smooth Cross-fade
      ),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletDashboardScreen(),
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
    GoRoute(
      path: '/bus_details',
      builder: (context, state) {
        final bus = state.extra as Map<String, dynamic>;
        return BusDetailsScreen(bus: bus);
      },
    ),
    GoRoute(
      path: '/seat_selection',
      builder: (context, state) {
        final busDetails = state.extra as Map<String, dynamic>;
        return SeatSelectionScreen(busDetails: busDetails);
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return PaymentScreen(
          busDetails: extras['busDetails'],
          seatCount: extras['seatCount'],
        );
      },
    ),
    GoRoute(
      path: '/receipt',
      builder: (context, state) {
        final bookingDetails = state.extra as Map<String, dynamic>;
        return TicketReceiptScreen(bookingDetails: bookingDetails);
      },
    ),
    // Add more routes here
    GoRoute(
      path: '/profile',
      builder: (context, state) => const Scaffold(body: Center(child: Text("Profile Settings"))),
    ),
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

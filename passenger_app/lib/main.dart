import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twende_passenger_app/config/theme.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/account/presentation/screens/account_screen.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/login_screen.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/bus_details_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/search_results_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/seat_selection_screen.dart';
import 'package:twende_passenger_app/features/booking/presentation/screens/ticket_receipt_screen.dart';
import 'package:twende_passenger_app/features/home/presentation/screens/home_wrapper.dart';
import 'package:twende_passenger_app/features/payment/presentation/screens/payment_screen.dart';
import 'package:twende_passenger_app/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:twende_passenger_app/features/wallet/presentation/screens/deposit_screen.dart';
import 'package:twende_passenger_app/features/wallet/presentation/screens/wallet_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  final String dsn = ApiEndpoints.sentryDsn;
  if (dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.sendDefaultPii = false;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(
        SentryWidget(
          child: const ProviderScope(
            child: TwendePassengerApp(),
          ),
        ),
      ),
    );
  } else {
    runApp(
      const ProviderScope(
        child: TwendePassengerApp(),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final String phone = (state.extra ?? '').toString();
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppTokens.easeOutCurve,
            ),
            child: child,
          );
        },
        transitionDuration: AppTokens.normalDuration,
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
        final Map<String, dynamic> extras = state.extra is Map
            ? (state.extra as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return SearchResultsScreen(
          fromLocation: (extras['from'] ?? 'Kampala').toString(),
          toLocation: (extras['to'] ?? 'Gulu').toString(),
          initialDate: extras['date']?.toString(),
        );
      },
    ),
    GoRoute(
      path: '/bus_details',
      builder: (context, state) {
        final Map<String, dynamic> bus = state.extra is Map
            ? (state.extra as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return BusDetailsScreen(bus: bus);
      },
    ),
    GoRoute(
      path: '/seat_selection',
      builder: (context, state) {
        final Map<String, dynamic> busDetails = state.extra is Map
            ? (state.extra as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return SeatSelectionScreen(busDetails: busDetails);
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final Map<String, dynamic> extras = state.extra is Map
            ? (state.extra as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final Map<String, dynamic> busDetails = extras['busDetails'] is Map
            ? (extras['busDetails'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final List<int> selectedSeats = (extras['selectedSeats'] is List)
            ? (extras['selectedSeats'] as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .where((s) => s > 0)
                .toList()
            : <int>[];
        final int seatCount = selectedSeats.isNotEmpty
            ? selectedSeats.length
            : (int.tryParse((extras['seatCount'] ?? '1').toString()) ?? 1);
        return PaymentScreen(
          busDetails: busDetails,
          seatCount: seatCount,
          selectedSeats: selectedSeats,
        );
      },
    ),
    GoRoute(
      path: '/receipt',
      builder: (context, state) {
        final Map<String, dynamic> bookingDetails = state.extra is Map
            ? (state.extra as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return TicketReceiptScreen(bookingDetails: bookingDetails);
      },
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) {
        final Map<String, dynamic> tripData = state.extra is Map
            ? (state.extra as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return TrackingScreen(tripData: tripData);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const AccountScreen(isStandalone: true),
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

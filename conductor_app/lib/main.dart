import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';
import 'package:twende_conductor_app/features/auth/presentation/screens/login_screen.dart';
import 'package:twende_conductor_app/features/manifest/presentation/screens/conductor_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow app to fall back to default ApiEndpoints if .env asset is absent in tests
  }

  final String sentryDsn = dotenv.isInitialized
      ? (dotenv.env['SENTRY_DSN'] ?? '').trim()
      : '';

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (SentryFlutterOptions options) {
        options.dsn = sentryDsn;
        options.sendDefaultPii = false;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(
        SentryWidget(
          child: const ProviderScope(
            child: TwendeConductorApp(),
          ),
        ),
      ),
    );
  } else {
    runApp(
      const ProviderScope(
        child: TwendeConductorApp(),
      ),
    );
  }
}

class TwendeConductorApp extends StatelessWidget {
  const TwendeConductorApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          final String userName = state.extra is String
              ? state.extra as String
              : 'Twende Crew';
          return ConductorHomeScreen(userName: userName);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData baseDark = ThemeData.dark(useMaterial3: true);
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Twende Conductor',
      debugShowCheckedModeBanner: false,
      theme: baseDark.copyWith(
        scaffoldBackgroundColor: AppTokens.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTokens.primary,
          brightness: Brightness.dark,
          surface: AppTokens.surface,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(baseDark.textTheme),
      ),
    );
  }
}

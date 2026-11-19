import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String _readEnv(String key, String fallback) {
    if (!dotenv.isInitialized) {
      return fallback;
    }
    final String? value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value.trim();
  }

  static String get baseUrl =>
      _readEnv('BASE_URL', 'http://192.168.1.71:8000/api/v1');

  static String get authUrl => '$baseUrl/auth';

  static String get conductorUrl => '$baseUrl/conductor';

  static String get wsUrl =>
      _readEnv('WS_URL', 'ws://192.168.1.71:8000/api/v1/tracking');

  static String get sentryDsn => _readEnv('SENTRY_DSN', '');
}

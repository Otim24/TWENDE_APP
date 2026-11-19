import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String get wsUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['WS_URL'] ?? 'ws://127.0.0.1:8000/api/v1/tracking';
    }
    return 'ws://127.0.0.1:8000/api/v1/tracking';
  }

  static String get sentryDsn {
    if (dotenv.isInitialized) {
      return (dotenv.env['SENTRY_DSN'] ?? '').trim();
    }
    return '';
  }

  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String otpRequest = '/auth/otp/request';
  static const String otpVerify = '/auth/otp/verify';
  static const String usersMe = '/users/me';
  static const String walletBalance = '/wallet/balance';
  static const String walletDeposit = '/wallet/deposit';
  static const String bookings = '/bookings';
  static const String bookingsSearch = '/bookings/search';
  static const String bookingsMyTrips = '/bookings/my-trips';
}

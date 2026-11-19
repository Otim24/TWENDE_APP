import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/api/api_client.dart';
import 'package:twende_passenger_app/core/storage/storage_service.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';
import 'package:twende_passenger_app/main.dart';

class _FakeStorageService extends StorageService {
  String? _token;

  _FakeStorageService([this._token]);

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTokens Decimal Currency & Seat Status Helpers', () {
    test('parseUgx safely parses Decimal strings without 100x regex bug', () {
      expect(AppTokens.parseUgx('30000.00'), 30000);
      expect(AppTokens.parseUgx('15000.00'), 15000);
      expect(AppTokens.parseUgx('UGX 30,000'), 30000);
      expect(AppTokens.parseUgx(45000), 45000);
      expect(AppTokens.parseUgx(45000.0), 45000);
      expect(AppTokens.parseUgx(null), 0);
      expect(AppTokens.parseUgx(''), 0);
    });

    test('formatUgx formats currency with commas and prefix', () {
      expect(AppTokens.formatUgx('30000.00'), 'UGX 30,000');
      expect(AppTokens.formatUgx(1250000), 'UGX 1,250,000');
      expect(
        AppTokens.formatUgx('30000.00', includePrefix: false),
        '30,000',
      );
    });

    test('multi-seat fare total math preserves exact integer UGX', () {
      final int unitPrice = AppTokens.parseUgx('30000.00');
      final List<int> selectedSeats = <int>[4, 5, 12];
      final int total = unitPrice * selectedSeats.length;
      expect(total, 90000);
      expect(AppTokens.formatUgx(total), 'UGX 90,000');
    });

    test('normalizeSeatStatus maps backend states consistently', () {
      expect(AppTokens.normalizeSeatStatus('USED'), 'OCCUPIED');
      expect(AppTokens.normalizeSeatStatus('OCCUPIED'), 'OCCUPIED');
      expect(AppTokens.normalizeSeatStatus('PAID'), 'BOOKED');
      expect(AppTokens.normalizeSeatStatus('BOOKED'), 'BOOKED');
      expect(AppTokens.normalizeSeatStatus('AVAILABLE'), 'AVAILABLE');
    });
  });

  group('ApiClient & BookingRepository Helpers', () {
    test('ApiClient.redactSensitive redacts tokens and QR secrets', () {
      final Map<String, dynamic> payload = <String, dynamic>{
        'access_token': 'secret-jwt',
        'user_name': 'Sarah',
        'nested': <String, dynamic>{
          'qr_code_data': 'TICKET-1-4:hmac',
          'seat_number': 4,
        },
      };
      final Map<dynamic, dynamic> redacted =
          ApiClient.redactSensitive(payload) as Map<dynamic, dynamic>;
      expect(redacted['access_token'], '[REDACTED]');
      expect(redacted['user_name'], 'Sarah');
      expect((redacted['nested'] as Map)['qr_code_data'], '[REDACTED]');
      expect((redacted['nested'] as Map)['seat_number'], 4);
    });

    test('BookingRepository.formatYyyyMmDd formats dates cleanly', () {
      final DateTime date = DateTime(2026, 3, 7);
      expect(BookingRepository.formatYyyyMmDd(date), '2026-03-07');
    });
  });

  testWidgets(
      'TwendePassengerApp boots into SplashScreen and routes to LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(_FakeStorageService(null)),
        ],
        child: const TwendePassengerApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();

    expect(find.text('Enter Your Phone Number'), findsOneWidget);
  });
}

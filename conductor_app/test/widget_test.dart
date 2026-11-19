import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_conductor_app/core/api/api_client.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';
import 'package:twende_conductor_app/main.dart';

void main() {
  group('AppTokens currency & status helpers', () {
    test('parseUgx and formatUgx handle backend Decimal strings without merging decimals', () {
      expect(AppTokens.parseUgx('30000.00'), 30000);
      expect(AppTokens.formatUgx('30000.00'), 'UGX 30,000');
      expect(AppTokens.formatUgx(35000), 'UGX 35,000');
      expect(AppTokens.formatUgx('UGX 14,890.00'), 'UGX 14,890');
      expect(AppTokens.formatUgx('0.00'), 'UGX 0');
    });

    test('normalizeSeatStatus maps legacy and backend statuses consistently', () {
      expect(AppTokens.normalizeSeatStatus('AVAILABLE'), 'AVAILABLE');
      expect(AppTokens.normalizeSeatStatus('BOOKED'), 'BOOKED');
      expect(AppTokens.normalizeSeatStatus('PAID'), 'BOOKED');
      expect(AppTokens.normalizeSeatStatus('OCCUPIED'), 'OCCUPIED');
      expect(AppTokens.normalizeSeatStatus('USED'), 'OCCUPIED');
    });

    test('AuthSession stores and clears conductor JWT session cleanly', () {
      AuthSession.clearSession();
      expect(AuthSession.isAuthenticated, isFalse);

      AuthSession.saveSession(
        accessToken: 'jwt-token-123',
        userName: 'John Conductor',
        role: 'CONDUCTOR',
      );
      expect(AuthSession.isAuthenticated, isTrue);
      expect(AuthSession.token, 'jwt-token-123');
      expect(AuthSession.userName, 'John Conductor');

      AuthSession.clearSession();
      expect(AuthSession.isAuthenticated, isFalse);
      expect(AuthSession.token, isNull);
    });
  });

  testWidgets('TwendeConductorApp boots to LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TwendeConductorApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Twende Conductor'), findsOneWidget);
    expect(find.text('Sign In to Shift'), findsOneWidget);
  });
}

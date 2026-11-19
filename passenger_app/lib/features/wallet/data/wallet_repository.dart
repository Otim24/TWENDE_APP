import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_passenger_app/core/api/api_client.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(apiClientProvider));
});

final walletBalanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(walletRepositoryProvider).getBalance();
});

class WalletRepository {
  final Dio _dio;

  WalletRepository(this._dio);

  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _dio.get(ApiEndpoints.walletBalance);
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(e, fallback: 'Failed to load wallet balance'),
      );
    }
  }

  Future<Map<String, dynamic>> deposit({
    required int amount,
    String provider = 'MOMO',
    String? reference,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.walletDeposit,
        data: <String, dynamic>{
          'amount': amount,
          'provider': provider,
          if (reference != null && reference.trim().isNotEmpty)
            'reference': reference.trim(),
        },
      );
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(e, fallback: 'Wallet deposit failed'),
      );
    }
  }
}

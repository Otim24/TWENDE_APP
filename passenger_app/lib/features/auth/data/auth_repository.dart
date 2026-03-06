
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_passenger_app/core/api/api_client.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';
import 'package:twende_passenger_app/core/storage/storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(storageServiceProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  AuthRepository(this._dio, this._storage);

  Future<void> requestOtp({required String phone}) async {
    try {
      await _dio.post(
        "/auth/otp/request",
        data: {"phone": phone},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw AuthException(e.response?.data['detail'] ?? "OTP Req Failed");
      }
      throw AuthException(e.message ?? "Connection error");
    }
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    try {
      final response = await _dio.post(
        "/auth/otp/verify",
        data: {"phone": phone, "code": code},
      );

      final token = response.data['access_token'];
      if (token != null) {
        await _storage.saveToken(token);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw AuthException(e.response?.data['detail'] ?? "Invalid OTP");
      }
      throw AuthException(e.message ?? "Connection error");
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

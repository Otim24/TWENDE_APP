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

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(authRepositoryProvider).getMe();
});

class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  AuthRepository(this._dio, this._storage);

  Future<void> requestOtp({required String phone}) async {
    try {
      await _dio.post(
        ApiEndpoints.otpRequest,
        data: <String, dynamic>{'phone': phone},
      );
    } on DioException catch (e) {
      throw AuthException(ApiClient.extractErrorMessage(e, fallback: 'OTP request failed'));
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.otpVerify,
        data: <String, dynamic>{'phone': phone, 'code': code},
      );

      final Map<String, dynamic> data =
          (response.data as Map).cast<String, dynamic>();
      final String? token = data['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _storage.saveToken(token);
      }
      return data;
    } on DioException catch (e) {
      throw AuthException(ApiClient.extractErrorMessage(e, fallback: 'Invalid OTP'));
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.usersMe);
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw AuthException(
        ApiClient.extractErrorMessage(e, fallback: 'Failed to load profile'),
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile(String fullName) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.usersMe,
        data: <String, dynamic>{'full_name': fullName.trim()},
      );
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw AuthException(
        ApiClient.extractErrorMessage(e, fallback: 'Failed to update profile'),
      );
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

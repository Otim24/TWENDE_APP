import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:twende_conductor_app/core/api/api_endpoints.dart';

class AuthSession {
  AuthSession._();

  static String? _token;
  static String _userName = 'Twende Crew';
  static String _role = 'CONDUCTOR';
  static VoidCallback? onUnauthorized;

  static String? get token => _token;
  static String get userName => _userName;
  static String get role => _role;
  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static void saveSession({
    required String accessToken,
    String? userName,
    String? role,
  }) {
    _token = accessToken.trim();
    if (userName != null && userName.trim().isNotEmpty) {
      _userName = userName.trim();
    }
    if (role != null && role.trim().isNotEmpty) {
      _role = role.trim();
    }
  }

  static void clearSession() {
    _token = null;
    _userName = 'Twende Crew';
    _role = 'CONDUCTOR';
    onUnauthorized?.call();
  }
}

class ApiClient {
  ApiClient._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final Dio client = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          options.baseUrl = ApiEndpoints.baseUrl;
          final String? token = AuthSession.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          if (e.response?.statusCode == 401) {
            AuthSession.clearSession();
          }
          handler.next(e);
        },
      ),
    );

    return client;
  }

  static String extractErrorMessage(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        final dynamic detail = data['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
        if (detail is List && detail.isNotEmpty) {
          final dynamic first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.join(', ');
        }
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Cannot reach Twende server (${ApiEndpoints.baseUrl}). Check Wi-Fi connection.';
      }
    }
    return fallback;
  }
}

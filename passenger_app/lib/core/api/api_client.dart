import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';
import 'package:twende_passenger_app/core/storage/storage_service.dart';

class ApiClient {
  ApiClient._();

  static const Set<String> _redactedKeys = <String>{
    'access_token',
    'token',
    'password',
    'code',
    'authorization',
    'secret',
    'qr_code_data',
  };

  /// Recursively redacts sensitive fields before debug logging.
  static dynamic redactSensitive(dynamic value) {
    if (value is Map) {
      return value.map((key, val) {
        final String keyStr = key.toString().toLowerCase();
        if (_redactedKeys.contains(keyStr)) {
          return MapEntry(key, '[REDACTED]');
        }
        return MapEntry(key, redactSensitive(val));
      });
    }
    if (value is List) {
      return value.map(redactSensitive).toList();
    }
    return value;
  }

  /// Extracts a human-readable error message from a FastAPI DioException.
  static String extractErrorMessage(Object error, {String fallback = 'Request failed'}) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        final dynamic detail = data['detail'];
        if (detail is List && detail.isNotEmpty) {
          final dynamic first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
        return detail.toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Cannot reach Twende server (${ApiEndpoints.baseUrl}). Check Wi-Fi connection.';
      }
      return error.message ?? fallback;
    }
    return error.toString();
  }
}

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.read(storageServiceProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        final String? token = await storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('HTTP [${options.method}] ${options.path}');
        return handler.next(options);
      },
      onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
        debugPrint(
          'HTTP [${response.statusCode}] ${response.requestOptions.path} -> ${ApiClient.redactSensitive(response.data)}',
        );
        return handler.next(response);
      },
      onError: (DioException e, ErrorInterceptorHandler handler) async {
        if (e.response?.statusCode == 401) {
          await storage.deleteToken();
        }
        debugPrint(
          'HTTP Error [${e.response?.statusCode}] ${e.requestOptions.path}: ${ApiClient.extractErrorMessage(e)}',
        );
        return handler.next(e);
      },
    ),
  );

  return dio;
});

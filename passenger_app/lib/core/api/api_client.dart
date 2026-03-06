
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final logger = Logger();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        logger.i("Request: [${options.method}] ${options.path}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        logger.d("Response: [${response.statusCode}] ${response.data}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        logger.e("Error: [${e.response?.statusCode}] ${e.message}");
        return handler.next(e);
      },
    ),
  );

  return dio;
});

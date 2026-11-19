import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_passenger_app/core/api/api_client.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(apiClientProvider));
});

final myTripsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(bookingRepositoryProvider).getMyTrips();
});

class BookingRepository {
  final Dio _dio;

  BookingRepository(this._dio);

  static String formatYyyyMmDd(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<Map<String, dynamic>>> searchTrips({
    required String from,
    required String to,
    required String date,
  }) async {
    try {
      final String normalizedDate = date.contains(' ')
          ? date.split(' ').first
          : (date.contains('T') ? date.split('T').first : date.trim());

      final response = await _dio.get(
        ApiEndpoints.bookingsSearch,
        queryParameters: <String, dynamic>{
          'from': from.trim(),
          'to': to.trim(),
          'date': normalizedDate,
        },
      );

      final List<dynamic> rawList = response.data as List<dynamic>;
      return rawList
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(e, fallback: 'Failed to search trips'),
      );
    }
  }

  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.bookings}/$tripId');
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(e, fallback: 'Failed to load trip details'),
      );
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int tripId,
    required List<int> seatNumbers,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.bookings,
        data: <String, dynamic>{
          'trip_id': tripId,
          'seat_numbers': seatNumbers,
          'payment_method': paymentMethod.toUpperCase(),
        },
      );
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(e, fallback: 'Booking failed'),
      );
    }
  }

  Future<List<dynamic>> getMyTrips() async {
    try {
      final response = await _dio.get(ApiEndpoints.bookingsMyTrips);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(e, fallback: 'Failed to fetch your trips'),
      );
    }
  }
}

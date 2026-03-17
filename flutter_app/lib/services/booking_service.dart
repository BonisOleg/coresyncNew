import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  final ApiClient _client;

  BookingService(this._client);

  Future<List<Booking>> getBookings() async {
    try {
      final response = await _client.get(ApiConfig.bookings);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Booking?> getBooking(int id) async {
    try {
      final response = await _client.get(ApiConfig.bookingDetail(id));
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createBooking(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.post(ApiConfig.bookings, data: data);
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<List<BookingSlot>> getSlots({String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      final response = await _client.get(
        ApiConfig.bookingSlots,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => BookingSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>?> checkIn(int bookingId) async {
    try {
      final response = await _client.post(ApiConfig.bookingCheckin(bookingId));
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> checkOut(int bookingId) async {
    try {
      final response = await _client.post(ApiConfig.bookingCheckout(bookingId));
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<Booking?> getActiveBooking() async {
    try {
      final response = await _client.get(ApiConfig.bookingActive);
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSessionTimer() async {
    try {
      final response = await _client.get(ApiConfig.bookingSession);
      return response.data as Map<String, dynamic>?;
    } on DioException {
      return null;
    }
  }
}

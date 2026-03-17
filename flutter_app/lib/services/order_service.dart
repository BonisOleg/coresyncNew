import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _client;

  OrderService(this._client);

  Future<List<Product>> getProducts({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      final response = await _client.get(
        ApiConfig.products,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _client.get(ApiConfig.orders);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Order?> getOrder(int id) async {
    try {
      final response = await _client.get(ApiConfig.orderDetail(id));
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<Order?> createOrder(
    List<Map<String, dynamic>> items,
    String message, {
    int? bookingId,
  }) async {
    try {
      final body = <String, dynamic>{
        'items': items,
        'message': message,
      };
      if (bookingId != null) body['booking_id'] = bookingId;
      final response = await _client.post(ApiConfig.ordersCreate, data: body);
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}

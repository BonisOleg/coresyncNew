import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/wallet.dart';
import 'api_client.dart';

class WalletService {
  final ApiClient _client;

  WalletService(this._client);

  Future<WalletBalance?> getBalance() async {
    try {
      final response = await _client.get(ApiConfig.wallet);
      return WalletBalance.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createSetupIntent() async {
    try {
      final response = await _client.post(ApiConfig.walletSetupIntent);
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _client.get(ApiConfig.walletPaymentMethods);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<PaymentMethod?> savePaymentMethod(String paymentMethodId) async {
    try {
      final response = await _client.post(
        ApiConfig.walletPaymentMethodsSave,
        data: {'payment_method_id': paymentMethodId},
      );
      return PaymentMethod.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(int id) async {
    try {
      await _client.delete(ApiConfig.walletPaymentMethod(id));
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> topUp(
    String amount,
    int paymentMethodId,
  ) async {
    try {
      final response = await _client.post(
        ApiConfig.walletTopUp,
        data: {'amount': amount, 'payment_method_id': paymentMethodId},
      );
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _client.get(ApiConfig.walletTransactions);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>?> pay(
    String amount, {
    int? orderId,
  }) async {
    try {
      final body = <String, dynamic>{'amount': amount};
      if (orderId != null) body['order_id'] = orderId;
      final response = await _client.post(ApiConfig.walletPay, data: body);
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }
}

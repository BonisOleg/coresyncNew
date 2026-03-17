import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/guest.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<Map<String, dynamic>?> login(String phone) async {
    try {
      final response = await _client.post(
        ApiConfig.login,
        data: {'phone': phone},
      );
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    try {
      final response = await _client.post(
        ApiConfig.verify,
        data: {'phone': phone, 'otp': otp},
      );
      final data = response.data as Map<String, dynamic>;
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access != null && refresh != null) {
        await _client.saveTokens(access, refresh);
      }
      return data;
    } on DioException {
      rethrow;
    }
  }

  Future<Guest?> getProfile() async {
    try {
      final response = await _client.get(ApiConfig.guestProfile);
      final data = response.data as Map<String, dynamic>;
      return Guest.fromJson(data);
    } on DioException {
      return null;
    }
  }

  Future<Guest?> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConfig.guestProfile,
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;
      return Guest.fromJson(responseData);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _client.delete(ApiConfig.guestProfile);
      await _client.clearTokens();
    } on DioException {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _client.clearTokens();
  }
}

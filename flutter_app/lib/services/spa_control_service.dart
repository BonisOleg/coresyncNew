import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/device.dart';
import 'api_client.dart';

class SpaControlService {
  final ApiClient _client;

  SpaControlService(this._client);

  Future<List<Device>> getDevices() async {
    try {
      final response = await _client.get(ApiConfig.devices);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => Device.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>?> controlDevice(
    int id,
    Map<String, dynamic> state,
  ) async {
    try {
      final response = await _client.post(
        ApiConfig.deviceControl(id),
        data: state,
      );
      return response.data as Map<String, dynamic>?;
    } on DioException {
      rethrow;
    }
  }

  Future<List<GuestPreset>> getPresets() async {
    try {
      final response = await _client.get(ApiConfig.presets);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => GuestPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }
}

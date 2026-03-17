import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/scent.dart';
import 'api_client.dart';

class ScentService {
  final ApiClient _client;

  ScentService(this._client);

  Future<List<ScentProfile>> getScentProfiles() async {
    try {
      final response = await _client.get(ApiConfig.scents);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => ScentProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<ActiveScent?> activateScent(int scentProfileId, int intensity) async {
    try {
      final response = await _client.post(
        ApiConfig.scentsActivate,
        data: {'scent_profile_id': scentProfileId, 'intensity': intensity},
      );
      return ActiveScent.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<ActiveScent?> getActiveScent() async {
    try {
      final response = await _client.get(ApiConfig.scentsActive);
      return ActiveScent.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<ActiveScent?> updateIntensity(int intensity) async {
    try {
      final response = await _client.patch(
        ApiConfig.scentsActive,
        data: {'intensity': intensity},
      );
      return ActiveScent.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deactivateScent() async {
    try {
      await _client.delete(ApiConfig.scentsActive);
    } on DioException {
      rethrow;
    }
  }
}

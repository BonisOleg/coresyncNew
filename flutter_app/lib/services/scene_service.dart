import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/scene.dart';
import 'api_client.dart';

class SceneService {
  final ApiClient _client;

  SceneService(this._client);

  Future<List<Scene>> getScenes() async {
    try {
      final response = await _client.get(ApiConfig.scenes);
      final data = response.data;
      final List<dynamic> results =
          data is Map<String, dynamic> ? data['results'] as List<dynamic> : data as List<dynamic>;
      return results
          .map((e) => Scene.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<ActiveRoomScene?> activateScene(
    int sceneId, {
    bool musicEnabled = true,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.scenesActivate,
        data: {'scene_id': sceneId, 'music_enabled': musicEnabled},
      );
      return ActiveRoomScene.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<ActiveRoomScene?> getActiveScene() async {
    try {
      final response = await _client.get(ApiConfig.scenesActive);
      return ActiveRoomScene.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<void> deactivateScene() async {
    try {
      await _client.delete(ApiConfig.scenesActive);
    } on DioException {
      rethrow;
    }
  }
}

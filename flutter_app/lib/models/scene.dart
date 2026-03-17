class SceneMusic {
  final int id;
  final String title;
  final String artist;
  final String audioUrl;
  final int durationSeconds;

  const SceneMusic({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.durationSeconds,
  });

  factory SceneMusic.fromJson(Map<String, dynamic> json) {
    return SceneMusic(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
    };
  }
}

class Scene {
  final int id;
  final String name;
  final String description;
  final String category;
  final String screenVideoUrl;
  final String thumbnailUrl;
  final bool isActive;
  final int order;
  final List<SceneMusic> tracks;

  const Scene({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.screenVideoUrl,
    required this.thumbnailUrl,
    required this.isActive,
    required this.order,
    required this.tracks,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      screenVideoUrl: json['screen_video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => SceneMusic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'screen_video_url': screenVideoUrl,
      'thumbnail_url': thumbnailUrl,
      'is_active': isActive,
      'order': order,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }
}

class ActiveRoomScene {
  final int id;
  final Scene scene;
  final bool musicEnabled;
  final SceneMusic? currentTrack;
  final DateTime activatedAt;

  const ActiveRoomScene({
    required this.id,
    required this.scene,
    required this.musicEnabled,
    this.currentTrack,
    required this.activatedAt,
  });

  factory ActiveRoomScene.fromJson(Map<String, dynamic> json) {
    return ActiveRoomScene(
      id: json['id'] as int,
      scene: Scene.fromJson(json['scene'] as Map<String, dynamic>),
      musicEnabled: json['music_enabled'] as bool? ?? false,
      currentTrack: json['current_track'] != null
          ? SceneMusic.fromJson(json['current_track'] as Map<String, dynamic>)
          : null,
      activatedAt: DateTime.parse(
        json['activated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scene': scene.toJson(),
      'music_enabled': musicEnabled,
      'current_track': currentTrack?.toJson(),
      'activated_at': activatedAt.toIso8601String(),
    };
  }
}

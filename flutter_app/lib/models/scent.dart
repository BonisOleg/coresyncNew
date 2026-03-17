class ScentProfile {
  final int id;
  final String name;
  final String description;
  final String category;
  final int intensityDefault;
  final int intensityMin;
  final int intensityMax;
  final String iconUrl;
  final bool isActive;

  const ScentProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.intensityDefault,
    required this.intensityMin,
    required this.intensityMax,
    required this.iconUrl,
    required this.isActive,
  });

  factory ScentProfile.fromJson(Map<String, dynamic> json) {
    return ScentProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      intensityDefault: json['intensity_default'] as int? ?? 50,
      intensityMin: json['intensity_min'] as int? ?? 0,
      intensityMax: json['intensity_max'] as int? ?? 100,
      iconUrl: json['icon_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'intensity_default': intensityDefault,
      'intensity_min': intensityMin,
      'intensity_max': intensityMax,
      'icon_url': iconUrl,
      'is_active': isActive,
    };
  }
}

class ActiveScent {
  final int id;
  final ScentProfile scentProfile;
  final int intensity;
  final DateTime activatedAt;

  const ActiveScent({
    required this.id,
    required this.scentProfile,
    required this.intensity,
    required this.activatedAt,
  });

  factory ActiveScent.fromJson(Map<String, dynamic> json) {
    return ActiveScent(
      id: json['id'] as int,
      scentProfile: ScentProfile.fromJson(
        json['scent_profile'] as Map<String, dynamic>,
      ),
      intensity: json['intensity'] as int? ?? 50,
      activatedAt: DateTime.parse(
        json['activated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scent_profile': scentProfile.toJson(),
      'intensity': intensity,
      'activated_at': activatedAt.toIso8601String(),
    };
  }
}

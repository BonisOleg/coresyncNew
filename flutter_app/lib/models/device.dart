class DeviceType {
  final int id;
  final String name;
  final List<String> capabilities;

  const DeviceType({
    required this.id,
    required this.name,
    required this.capabilities,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capabilities': capabilities,
    };
  }
}

class Device {
  final int id;
  final DeviceType deviceType;
  final String name;
  final String room;
  final Map<String, dynamic> currentState;
  final bool isOnline;

  const Device({
    required this.id,
    required this.deviceType,
    required this.name,
    required this.room,
    required this.currentState,
    required this.isOnline,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      deviceType:
          DeviceType.fromJson(json['device_type'] as Map<String, dynamic>),
      name: json['name'] as String? ?? '',
      room: json['room'] as String? ?? '',
      currentState: (json['current_state'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_type': deviceType.toJson(),
      'name': name,
      'room': room,
      'current_state': currentState,
      'is_online': isOnline,
    };
  }
}

class GuestPreset {
  final int id;
  final String name;
  final Map<String, dynamic> settings;
  final DateTime createdAt;

  const GuestPreset({
    required this.id,
    required this.name,
    required this.settings,
    required this.createdAt,
  });

  factory GuestPreset.fromJson(Map<String, dynamic> json) {
    return GuestPreset(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      settings:
          (json['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

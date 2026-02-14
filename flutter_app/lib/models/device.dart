/// SPA device model matching the Django Device model.
class DeviceType {
  final String id;
  final String name;
  final Map<String, dynamic> capabilities;

  DeviceType({
    required this.id,
    required this.name,
    this.capabilities = const {},
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      capabilities: json['capabilities'] ?? {},
    );
  }
}

class Device {
  final String id;
  final DeviceType deviceType;
  final String name;
  final String room;
  final Map<String, dynamic> currentState;
  final bool isOnline;

  Device({
    required this.id,
    required this.deviceType,
    required this.name,
    this.room = '',
    this.currentState = const {},
    this.isOnline = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      deviceType: DeviceType.fromJson(json['device_type'] ?? {}),
      name: json['name'] ?? '',
      room: json['room'] ?? '',
      currentState: Map<String, dynamic>.from(json['current_state'] ?? {}),
      isOnline: json['is_online'] ?? false,
    );
  }
}

class GuestPreset {
  final String id;
  final String name;
  final Map<String, dynamic> settings;

  GuestPreset({
    required this.id,
    required this.name,
    this.settings = const {},
  });

  factory GuestPreset.fromJson(Map<String, dynamic> json) {
    return GuestPreset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      settings: json['settings'] ?? {},
    );
  }
}

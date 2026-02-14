import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/device.dart';
import 'api_service.dart';

/// Service for SPA device control.
class SpaControlService extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Device> _devices = [];
  List<GuestPreset> _presets = [];
  bool _isLoading = false;

  List<Device> get devices => _devices;
  List<GuestPreset> get presets => _presets;
  bool get isLoading => _isLoading;

  /// Fetch all devices.
  Future<void> fetchDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.devicesUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        _devices = (results as List).map((d) => Device.fromJson(d)).toList();
      }
    } catch (_) {
      // Fetch failed
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Send control command to a device.
  Future<bool> controlDevice(String deviceId, Map<String, dynamic> state) async {
    try {
      final response = await _api.post(
        ApiConfig.deviceControlUrl(deviceId),
        body: {'state': state},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update local device state
        final index = _devices.indexWhere((d) => d.id == deviceId);
        if (index >= 0) {
          _devices[index] = Device.fromJson(data);
          notifyListeners();
        }
        return true;
      }
    } catch (_) {
      // Control failed
    }
    return false;
  }

  /// Fetch presets.
  Future<void> fetchPresets() async {
    try {
      final response = await _api.get(ApiConfig.presetsUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        _presets = (results as List).map((p) => GuestPreset.fromJson(p)).toList();
        notifyListeners();
      }
    } catch (_) {
      // Fetch failed
    }
  }

  /// Save a preset.
  Future<bool> savePreset(String name, Map<String, dynamic> settings) async {
    try {
      final response = await _api.post(
        ApiConfig.presetsUrl,
        body: {'name': name, 'settings': settings},
      );
      if (response.statusCode == 201) {
        await fetchPresets();
        return true;
      }
    } catch (_) {
      // Save failed
    }
    return false;
  }
}

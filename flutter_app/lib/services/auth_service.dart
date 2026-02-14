import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/guest.dart';
import 'api_service.dart';

/// Handles phone + OTP authentication and guest profile.
class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();

  Guest? _guest;
  bool _isLoading = false;
  String? _error;

  Guest? get guest => _guest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _guest != null;

  /// Check if user is already logged in (has stored tokens).
  Future<bool> checkLoginStatus() async {
    final loggedIn = await _api.isLoggedIn();
    if (loggedIn) {
      await fetchProfile();
      return _guest != null;
    }
    return false;
  }

  /// Request OTP for the given phone number.
  Future<bool> requestOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.postPublic(
        ApiConfig.loginUrl,
        body: {'phone': phone},
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to send verification code.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and store tokens.
  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.postPublic(
        ApiConfig.verifyOtpUrl,
        body: {'phone': phone, 'otp': otp},
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _api.saveTokens(
          access: data['access'],
          refresh: data['refresh'],
          guestId: data['guest_id'],
        );
        await fetchProfile();
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid or expired code.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Fetch guest profile.
  Future<void> fetchProfile() async {
    try {
      final response = await _api.get(ApiConfig.profileUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _guest = Guest.fromJson(data);
        notifyListeners();
      }
    } catch (_) {
      // Profile fetch failed silently
    }
  }

  /// Update guest profile.
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _api.patch(ApiConfig.profileUrl, body: updates);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _guest = Guest.fromJson(data);
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Update failed
    }
    return false;
  }

  /// Logout — clear tokens and state.
  Future<void> logout() async {
    await _api.clearTokens();
    _guest = null;
    _error = null;
    notifyListeners();
  }
}

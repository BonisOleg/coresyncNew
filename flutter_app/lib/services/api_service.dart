import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// HTTP client for the CoreSync Django REST API.
/// Handles JWT token management and request/response serialization.
class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _guestIdKey = 'guest_id';

  /// Save JWT tokens after login.
  Future<void> saveTokens({
    required String access,
    required String refresh,
    required String guestId,
  }) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _guestIdKey, value: guestId);
  }

  /// Get stored access token.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessKey);
  }

  /// Get stored guest ID.
  Future<String?> getGuestId() async {
    return _storage.read(key: _guestIdKey);
  }

  /// Check if user is logged in.
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored tokens (logout).
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  /// Build headers with JWT authorization.
  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request with auth.
  Future<http.Response> get(String url) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    // If 401, try refreshing token
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        return http.get(Uri.parse(url), headers: newHeaders);
      }
    }

    return response;
  }

  /// POST request with auth.
  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        return http.post(
          Uri.parse(url),
          headers: newHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// PATCH request with auth.
  Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        return http.patch(
          Uri.parse(url),
          headers: newHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// POST without auth (for login/verify).
  Future<http.Response> postPublic(String url, {Map<String, dynamic>? body}) async {
    return http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Refresh the access token using the refresh token.
  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${Uri.parse((await _authHeaders())['Authorization'] ?? '').origin}/api/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _accessKey, value: data['access']);
        if (data['refresh'] != null) {
          await _storage.write(key: _refreshKey, value: data['refresh']);
        }
        return true;
      }
    } catch (_) {
      // Refresh failed
    }

    await clearTokens();
    return false;
  }
}

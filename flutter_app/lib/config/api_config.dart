/// API configuration for the CoreSync Private backend.
class ApiConfig {
  /// Base URL for the Django REST API.
  /// Change to your Render deployment URL in production.
  static const String baseUrl = 'http://localhost:8000';

  // Auth endpoints
  static const String loginUrl = '$baseUrl/api/auth/login/';
  static const String verifyOtpUrl = '$baseUrl/api/auth/verify/';
  static const String refreshUrl = '$baseUrl/api/auth/refresh/';

  // Guest profile
  static const String profileUrl = '$baseUrl/api/guest/profile/';

  // Bookings
  static const String bookingsUrl = '$baseUrl/api/bookings/';

  // Concierge
  static const String conciergeMessageUrl = '$baseUrl/api/concierge/message/';
  static const String conciergeHistoryUrl = '$baseUrl/api/concierge/history/';

  // SPA control
  static const String devicesUrl = '$baseUrl/api/spa/devices/';
  static const String presetsUrl = '$baseUrl/api/spa/presets/';

  // Admin
  static const String adminGuestsUrl = '$baseUrl/api/admin/guests/';
  static const String adminBookingsUrl = '$baseUrl/api/admin/bookings/';
  static const String adminCallsUrl = '$baseUrl/api/admin/calls/';
  static const String adminDashboardUrl = '$baseUrl/api/admin/dashboard/';

  /// Build device control URL for a specific device.
  static String deviceControlUrl(String deviceId) =>
      '$baseUrl/api/spa/devices/$deviceId/control/';

  /// Build booking detail URL.
  static String bookingDetailUrl(String bookingId) =>
      '$baseUrl/api/bookings/$bookingId/';
}

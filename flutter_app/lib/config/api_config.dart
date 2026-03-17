import 'env.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl => Env.baseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login/';
  static const String verify = '/api/auth/verify/';
  static const String refresh = '/api/auth/refresh/';

  // ── Guest ─────────────────────────────────────────────────────────────
  static const String guestProfile = '/api/guest/profile/';

  // ── Bookings ──────────────────────────────────────────────────────────
  static const String bookings = '/api/bookings/';
  static const String bookingSlots = '/api/bookings/slots/';
  static const String bookingActive = '/api/bookings/active/';
  static const String bookingSession = '/api/bookings/session/';

  static String bookingDetail(int id) => '/api/bookings/$id/';
  static String bookingCheckin(int id) => '/api/bookings/$id/checkin/';
  static String bookingCheckout(int id) => '/api/bookings/$id/checkout/';

  // ── SPA Devices ───────────────────────────────────────────────────────
  static const String devices = '/api/spa/devices/';
  static String deviceControl(int id) => '/api/spa/devices/$id/control/';
  static const String presets = '/api/spa/presets/';

  // ── Scenes ────────────────────────────────────────────────────────────
  static const String scenes = '/api/spa/scenes/';
  static const String scenesActivate = '/api/spa/scenes/activate/';
  static const String scenesActive = '/api/spa/scenes/active/';

  // ── Scents ────────────────────────────────────────────────────────────
  static const String scents = '/api/spa/scents/';
  static const String scentsActivate = '/api/spa/scents/activate/';
  static const String scentsActive = '/api/spa/scents/active/';

  // ── Orders ────────────────────────────────────────────────────────────
  static const String products = '/api/orders/products/';
  static const String orders = '/api/orders/';
  static const String ordersCreate = '/api/orders/create/';
  static String orderDetail(int id) => '/api/orders/$id/';

  // ── Wallet ────────────────────────────────────────────────────────────
  static const String wallet = '/api/wallet/';
  static const String walletSetupIntent = '/api/wallet/setup-intent/';
  static const String walletPaymentMethods = '/api/wallet/payment-methods/';
  static const String walletPaymentMethodsSave =
      '/api/wallet/payment-methods/save/';
  static String walletPaymentMethod(int id) =>
      '/api/wallet/payment-methods/$id/';
  static const String walletTopUp = '/api/wallet/top-up/';
  static const String walletTransactions = '/api/wallet/transactions/';
  static const String walletPay = '/api/wallet/pay/';

  // ── Concierge ─────────────────────────────────────────────────────────
  static const String conciergeMessage = '/api/concierge/message/';
  static const String conciergeHistory = '/api/concierge/history/';
}

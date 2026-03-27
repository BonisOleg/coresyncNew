// For local dev: --dart-define=BASE_URL=http://localhost:8000
class Env {
  Env._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://coresync-private.onrender.com',
  );
}

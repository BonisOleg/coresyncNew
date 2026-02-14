import 'package:local_auth/local_auth.dart';

/// Face ID / biometric authentication service.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric auth is available on this device.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types.
  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate using biometrics.
  Future<bool> authenticate({String reason = 'Authenticate to access CoreSync'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

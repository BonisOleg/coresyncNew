import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

/// Splash screen — checks auth status and biometric availability.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final authService = context.read<AuthService>();
    final isLoggedIn = await authService.checkLoginStatus();

    if (!mounted) return;

    if (isLoggedIn) {
      // Try biometric auth if available
      final bio = BiometricService();
      final bioAvailable = await bio.isAvailable();

      if (bioAvailable) {
        final authenticated = await bio.authenticate();
        if (!mounted) return;
        if (!authenticated) {
          return; // Stay on splash, user can retry
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CORESYNC',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'PRIVATE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: CoreSyncTheme.textMuted,
                    letterSpacing: 4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

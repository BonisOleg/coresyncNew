import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/biometric_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final apiClient = ref.read(apiClientProvider);
    final wasLoggedIn = await apiClient.isLoggedIn();
    if (!mounted) return;

    if (wasLoggedIn) {
      final bio = BiometricService();
      final bioAvailable = await bio.isAvailable();

      if (bioAvailable) {
        final authenticated = await bio.authenticate();
        if (!mounted) return;
        if (!authenticated) {
          context.go('/auth');
          return;
        }
      }

      await ref.read(authStateProvider.notifier).checkAuth();
      if (!mounted) return;

      final authState = ref.read(authStateProvider);
      context.go(authState.isAuthenticated ? '/home' : '/auth');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CORESYNC',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      letterSpacing: 8,
                      fontWeight: FontWeight.w200,
                      color: CoreSyncColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'PRIVATE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: CoreSyncColors.textMuted,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

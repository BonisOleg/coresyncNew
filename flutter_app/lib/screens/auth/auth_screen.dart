import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return;

    final phone = '+$raw';

    await ref.read(authStateProvider.notifier).login(phone);
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.error == null) {
      context.go('/auth/otp', extra: phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text(
                  'CORESYNC',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w200,
                        color: CoreSyncColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your phone number',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: CoreSyncColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    prefixText: '+  ',
                    prefixStyle: TextStyle(
                      color: CoreSyncColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  style: const TextStyle(
                    color: CoreSyncColors.textPrimary,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      authState.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.withAlpha(200),
                        fontSize: 14,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CoreSyncColors.bg,
                            ),
                          )
                        : const Text(
                            'CONTINUE',
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoreSyncColors.textMuted,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: CoreSyncColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse(
                                    'https://coresync-private.onrender.com/terms/'),
                                mode: LaunchMode.externalApplication,
                              ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: CoreSyncColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse(
                                    'https://coresync-private.onrender.com/privacy/'),
                                mode: LaunchMode.externalApplication,
                              ),
                      ),
                    ],
                  ),
                ),
                Spacer(flex: bottomInset > 0 ? 1 : 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

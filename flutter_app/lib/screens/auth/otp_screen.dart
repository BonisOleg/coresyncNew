import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _isVerifying = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _otpFocus.addListener(_onFocusChanged);
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.removeListener(_onFocusChanged);
    _otpFocus.dispose();
    _resendTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _isVerifying) return;

    setState(() => _isVerifying = true);

    await ref.read(authStateProvider.notifier).verifyOtp(widget.phone, otp);
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    _otpController.clear();
    setState(() {});
    await ref.read(authStateProvider.notifier).login(widget.phone);
    if (mounted) _startResendTimer();
  }

  Widget _buildDigitBox(int index) {
    final hasValue = index < _otpController.text.length;
    final isActive = index == _otpController.text.length && _otpFocus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 48,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: hasValue ? CoreSyncColors.glass : CoreSyncColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? CoreSyncColors.accent : CoreSyncColors.glassBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        hasValue ? _otpController.text[index] : '',
        style: const TextStyle(
          color: CoreSyncColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading || _isVerifying;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/auth'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'Verify your number',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: CoreSyncColors.textPrimary,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Code sent to ${widget.phone}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CoreSyncColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, _buildDigitBox),
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _otpController,
                            focusNode: _otpFocus,
                            maxLength: 6,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            showCursor: false,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() {});
                              if (value.length == 6) _verify();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CoreSyncColors.accent,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: _resendCountdown > 0 ? null : _resendCode,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend code in ${_resendCountdown}s'
                        : 'Resend code',
                    style: TextStyle(
                      color: _resendCountdown > 0
                          ? CoreSyncColors.textMuted
                          : CoreSyncColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

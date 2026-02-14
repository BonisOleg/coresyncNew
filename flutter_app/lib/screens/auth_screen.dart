import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// Phone + OTP authentication screen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    final auth = context.read<AuthService>();
    final success = await auth.requestOtp(phone);
    if (success && mounted) {
      setState(() => _otpSent = true);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (phone.isEmpty || otp.isEmpty) return;

    final auth = context.read<AuthService>();
    final success = await auth.verifyOtp(phone, otp);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Consumer<AuthService>(
            builder: (context, auth, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CORESYNC',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          letterSpacing: 6,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PRIVATE',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: CoreSyncTheme.textMuted,
                          letterSpacing: 4,
                        ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                      prefixIcon: Icon(Icons.phone, size: 20),
                    ),
                    enabled: !_otpSent,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: 'Verification code',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                        counterText: '',
                      ),
                      autofocus: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : (_otpSent ? _verifyOtp : _requestOtp),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _otpSent ? 'VERIFY' : 'CONTINUE',
                          ),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        });
                      },
                      child: const Text('Change phone number'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

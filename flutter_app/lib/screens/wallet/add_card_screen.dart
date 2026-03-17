import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  bool _cardComplete = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _saveCard() async {
    if (!_cardComplete || _isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final walletService = ref.read(walletServiceProvider);
      final setupData = await walletService.createSetupIntent();
      final clientSecret = setupData?['client_secret'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Unable to initialise secure card setup');
      }

      final result = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      final paymentMethodId = result.paymentMethodId;
      if (paymentMethodId.isEmpty) {
        throw Exception('Card verification failed');
      }

      await walletService.savePaymentMethod(paymentMethodId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage =
            e.error.localizedMessage ?? 'Card was declined. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(title: const Text('Add Card')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CARD DETAILS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CardField(
                enablePostalCode: false,
                style: const TextStyle(
                  color: CoreSyncColors.textPrimary,
                  fontSize: 16,
                ),
                onCardChanged: (details) {
                  setState(() => _cardComplete = details?.complete ?? false);
                },
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              GlassPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.lock_outlined,
                    size: 14, color: CoreSyncColors.textMuted),
                SizedBox(width: 6),
                Text(
                  'Card details are securely handled by Stripe',
                  style: TextStyle(
                    fontSize: 12,
                    color: CoreSyncColors.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _cardComplete && !_isSaving ? _saveCard : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoreSyncColors.bg,
                        ),
                      )
                    : const Text(
                        'Save Card',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

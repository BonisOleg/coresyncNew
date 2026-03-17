import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/wallet.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  static const _presetAmounts = [25, 50, 100, 200];

  int? _selectedPreset;
  bool _customMode = false;
  final _customController = TextEditingController();
  List<PaymentMethod> _paymentMethods = [];
  int? _selectedPaymentMethodId;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    final walletService = ref.read(walletServiceProvider);
    final methods = await walletService.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
      final defaultPm = methods.where((m) => m.isDefault).firstOrNull;
      _selectedPaymentMethodId = defaultPm?.id ?? methods.firstOrNull?.id;
      _isLoading = false;
    });
  }

  String get _effectiveAmount {
    if (_customMode) return _customController.text.trim();
    if (_selectedPreset != null) return '$_selectedPreset';
    return '';
  }

  bool get _canTopUp {
    final amount = double.tryParse(_effectiveAmount);
    return amount != null &&
        amount > 0 &&
        _selectedPaymentMethodId != null &&
        !_isProcessing;
  }

  Future<void> _topUp() async {
    if (!_canTopUp) return;
    setState(() => _isProcessing = true);

    try {
      final walletService = ref.read(walletServiceProvider);
      final result = await walletService.topUp(
        _effectiveAmount,
        _selectedPaymentMethodId!,
      );

      if (!mounted) return;
      final newBalance = result?['balance']?.toString() ?? _effectiveAmount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallet topped up. New balance: \$$newBalance'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Top up failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(title: const Text('Top Up')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncColors.accent,
                strokeWidth: 1.5,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'SELECT AMOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _buildAmountGrid(),
                const SizedBox(height: 16),
                if (_customMode) ...[
                  GlassPanel(
                    child: TextField(
                      controller: _customController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style:
                          const TextStyle(color: CoreSyncColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Enter amount',
                        prefixText: '\$ ',
                        prefixStyle:
                            TextStyle(color: CoreSyncColors.textSecondary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 12),
                const Text(
                  'PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canTopUp ? _topUp : null,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CoreSyncColors.bg,
                            ),
                          )
                        : Text(
                            _effectiveAmount.isNotEmpty
                                ? 'Top Up \$$_effectiveAmount'
                                : 'Top Up',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAmountGrid() {
    final items = [
      ..._presetAmounts.map((a) => _AmountOption(amount: a)),
      const _AmountOption(amount: -1, label: 'Custom'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((opt) {
        final isCustom = opt.amount == -1;
        final selected =
            isCustom ? _customMode : (!_customMode && _selectedPreset == opt.amount);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isCustom) {
                _customMode = true;
                _selectedPreset = null;
              } else {
                _customMode = false;
                _selectedPreset = opt.amount;
                _customController.clear();
              }
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 70) / 3,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: selected ? CoreSyncColors.accent : CoreSyncColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? null
                  : Border.all(color: CoreSyncColors.glassBorder),
            ),
            child: Center(
              child: Text(
                isCustom ? 'Custom' : '\$${opt.amount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? CoreSyncColors.bg
                      : CoreSyncColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelector() {
    if (_paymentMethods.isEmpty) {
      return GlassPanel(
        child: Row(
          children: [
            const Icon(Icons.credit_card_off_outlined,
                size: 20, color: CoreSyncColors.textMuted),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No saved cards',
                style: TextStyle(
                  fontSize: 14,
                  color: CoreSyncColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/wallet/add-card'),
              child: const Text('Add Card'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _paymentMethods.map((pm) {
        final selected = _selectedPaymentMethodId == pm.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () =>
                setState(() => _selectedPaymentMethodId = pm.id),
            child: GlassPanel(
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? CoreSyncColors.accent
                            : CoreSyncColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: CoreSyncColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.credit_card, size: 22,
                      color: CoreSyncColors.textPrimary),
                  const SizedBox(width: 10),
                  Text(
                    '${pm.cardBrand} ····${pm.cardLast4}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (pm.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CoreSyncColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 10,
                          color: CoreSyncColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AmountOption {
  final int amount;
  final String? label;

  const _AmountOption({required this.amount, this.label});
}

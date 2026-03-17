import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/wallet.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  WalletBalance? _wallet;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final walletService = ref.read(walletServiceProvider);

    final results = await Future.wait([
      walletService.getBalance(),
      walletService.getPaymentMethods(),
    ]);

    if (!mounted) return;
    setState(() {
      _wallet = results[0] as WalletBalance?;
      _paymentMethods = results[1] as List<PaymentMethod>;
      _isLoading = false;
    });
  }

  Future<void> _deletePaymentMethod(PaymentMethod pm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CoreSyncColors.surface,
        title: const Text('Remove Card',
            style: TextStyle(color: CoreSyncColors.textPrimary)),
        content: Text(
          'Remove ${pm.cardBrand} ····${pm.cardLast4}?',
          style: const TextStyle(color: CoreSyncColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final walletService = ref.read(walletServiceProvider);
      await walletService.deletePaymentMethod(pm.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove card: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncColors.accent,
                strokeWidth: 1.5,
              ),
            )
          : RefreshIndicator(
              color: CoreSyncColors.accent,
              backgroundColor: CoreSyncColors.surface,
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildBalanceCard(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 28),
                        _buildPaymentMethodsSection(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'WALLET',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: CoreSyncColors.accent,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: CoreSyncColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _wallet?.balance ?? '0.00';
    final currency = _wallet?.currency ?? 'EUR';

    return GlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: CoreSyncColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _currencySymbol(currency),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                balance,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: CoreSyncColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/wallet/top-up'),
              child: const Text('Top Up'),
            ),
          ),
        ],
      ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      default:
        return currency;
    }
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'Top Up',
            onTap: () => context.go('/wallet/top-up'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            onTap: () => context.go('/wallet/transactions'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PAYMENT METHODS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/wallet/add-card'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: CoreSyncColors.accent),
                  SizedBox(width: 4),
                  Text(
                    'Add Card',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_paymentMethods.isEmpty)
          GlassPanel(
            child: Row(
              children: const [
                Icon(
                  Icons.credit_card_outlined,
                  size: 20,
                  color: CoreSyncColors.textMuted,
                ),
                SizedBox(width: 12),
                Text(
                  'No saved cards',
                  style: TextStyle(
                    fontSize: 14,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ..._paymentMethods.map((pm) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(pm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                  ),
                  confirmDismiss: (_) async {
                    await _deletePaymentMethod(pm);
                    return false;
                  },
                  child: GlassPanel(
                    child: Row(
                      children: [
                        Icon(
                          _brandIcon(pm.cardBrand),
                          size: 28,
                          color: CoreSyncColors.textPrimary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pm.cardBrand.isNotEmpty ? pm.cardBrand : 'Card'} ····${pm.cardLast4}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: CoreSyncColors.textPrimary,
                                ),
                              ),
                              if (pm.isDefault)
                                const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CoreSyncColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (pm.isDefault)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  IconData _brandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card_outlined;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: CoreSyncColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CoreSyncColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: CoreSyncColors.accent),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CoreSyncColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

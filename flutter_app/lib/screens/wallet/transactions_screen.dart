import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/wallet.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final walletService = ref.read(walletServiceProvider);
    final transactions = await walletService.getTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(title: const Text('Transactions')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncColors.accent,
                strokeWidth: 1.5,
              ),
            )
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: CoreSyncColors.accent,
                  backgroundColor: CoreSyncColors.surface,
                  onRefresh: _loadTransactions,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _TransactionTile(transaction: _transactions[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: CoreSyncColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: CoreSyncColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  _TxStyle get _style {
    switch (transaction.type.toLowerCase()) {
      case 'top_up':
      case 'topup':
        return _TxStyle(
          icon: Icons.arrow_downward_rounded,
          color: Colors.greenAccent,
          prefix: '+',
        );
      case 'payment':
      case 'charge':
        return _TxStyle(
          icon: Icons.arrow_upward_rounded,
          color: Colors.redAccent,
          prefix: '-',
        );
      case 'refund':
        return _TxStyle(
          icon: Icons.replay_rounded,
          color: Colors.lightBlueAccent,
          prefix: '+',
        );
      default:
        return _TxStyle(
          icon: Icons.swap_horiz_rounded,
          color: CoreSyncColors.textSecondary,
          prefix: '',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final dateStr =
        DateFormat('MMM d, yyyy · h:mm a').format(transaction.createdAt);

    return GlassPanel(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: s.color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, size: 20, color: s.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty
                      ? transaction.description
                      : _readableType(transaction.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CoreSyncColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CoreSyncColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.prefix}\$${transaction.amount}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: s.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: \$${transaction.balanceAfter}',
                style: const TextStyle(
                  fontSize: 11,
                  color: CoreSyncColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _readableType(String type) {
    switch (type.toLowerCase()) {
      case 'top_up':
      case 'topup':
        return 'Top Up';
      case 'payment':
      case 'charge':
        return 'Payment';
      case 'refund':
        return 'Refund';
      default:
        return type;
    }
  }
}

class _TxStyle {
  final IconData icon;
  final Color color;
  final String prefix;

  const _TxStyle({
    required this.icon,
    required this.color,
    required this.prefix,
  });
}

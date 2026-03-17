import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  int? _expandedOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orderService = ref.read(orderServiceProvider);
    final orders = await orderService.getOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(title: const Text('Order History')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncColors.accent,
                strokeWidth: 1.5,
              ),
            )
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: CoreSyncColors.accent,
                  backgroundColor: CoreSyncColors.surface,
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final expanded = _expandedOrderId == order.id;
                      return _OrderCard(
                        order: order,
                        expanded: expanded,
                        onTap: () {
                          setState(() {
                            _expandedOrderId = expanded ? null : order.id;
                          });
                        },
                      );
                    },
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
            'No orders yet',
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

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool expanded;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.expanded,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.greenAccent;
      case 'pending':
      case 'preparing':
        return Colors.amberAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return CoreSyncColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt);
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CoreSyncColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${order.totalAmount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CoreSyncColors.accent,
                  ),
                ),
              ],
            ),
            if (order.message.isNotEmpty && !expanded) ...[
              const SizedBox(height: 8),
              Text(
                order.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: CoreSyncColors.textMuted,
                ),
              ),
            ],
            if (expanded) ...[
              const SizedBox(height: 14),
              const Divider(color: CoreSyncColors.glassBorder),
              const SizedBox(height: 10),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CoreSyncColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CoreSyncColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '\$${item.subtotal}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CoreSyncColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (order.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.message_outlined,
                      size: 14,
                      color: CoreSyncColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.message,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: CoreSyncColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: CoreSyncColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

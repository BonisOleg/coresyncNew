import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => double.parse(product.price) * quantity;
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final List<CartItem> _items = [];
  final _messageController = TextEditingController();
  bool _isPlacing = false;
  bool _payFromWallet = false;
  String? _walletBalance;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final walletService = ref.read(walletServiceProvider);
    final wallet = await walletService.getBalance();
    if (!mounted) return;
    setState(() {
      _walletBalance = wallet?.balance;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0.0, (s, item) => s + item.subtotal);

  void _increment(int index) {
    setState(() => _items[index].quantity++);
  }

  void _decrement(int index) {
    setState(() {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) return;
    setState(() => _isPlacing = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final itemsData = _items
          .map((c) => {
                'product_id': c.product.id,
                'quantity': c.quantity,
              })
          .toList();
      final order = await orderService.createOrder(
        itemsData,
        _messageController.text.trim(),
      );

      if (order != null && _payFromWallet) {
        final walletService = ref.read(walletServiceProvider);
        await walletService.pay(order.totalAmount, orderId: order.id);
      }

      if (!mounted) return;
      setState(() {
        _items.clear();
        _messageController.clear();
        _isPlacing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(title: const Text('Cart')),
      body: _items.isEmpty ? _buildEmptyCart() : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 56,
            color: CoreSyncColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: CoreSyncColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse products and add items',
            style: TextStyle(
              fontSize: 14,
              color: CoreSyncColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._items.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemTile(
                      item: e.value,
                      onIncrement: () => _increment(e.key),
                      onDecrement: () => _decrement(e.key),
                      onRemove: () => _removeItem(e.key),
                    ),
                  )),
              const SizedBox(height: 8),
              GlassPanel(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: CoreSyncColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Personal message (e.g. Happy Birthday!)',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(
                      Icons.message_outlined,
                      size: 20,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (_walletBalance != null) ...[
                const SizedBox(height: 12),
                GlassPanel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: CoreSyncColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pay from Wallet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: CoreSyncColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Balance: \$$_walletBalance',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CoreSyncColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _payFromWallet,
                        onChanged: (v) => setState(() => _payFromWallet = v),
                        activeTrackColor: CoreSyncColors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: CoreSyncColors.surface,
        border: Border(
          top: BorderSide(color: CoreSyncColors.glassBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CoreSyncColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPlacing ? null : _placeOrder,
                child: _isPlacing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoreSyncColors.bg,
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.product.imageUrl.isNotEmpty
                  ? Image.network(
                      item.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CoreSyncColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.product.price} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: onDecrement,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CoreSyncColors.textPrimary,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: onIncrement,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CoreSyncColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: CoreSyncColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: CoreSyncColors.surface,
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: CoreSyncColors.textMuted,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoreSyncColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 16, color: CoreSyncColors.textPrimary),
        ),
      ),
    );
  }
}

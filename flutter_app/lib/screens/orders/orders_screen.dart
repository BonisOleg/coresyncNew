import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class _CartItem {
  final Product product;
  int quantity;

  _CartItem({required this.product, this.quantity = 1});

  double get subtotal => double.parse(product.price) * quantity;
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  static const _categories = ['All', 'Drinks', 'Flowers', 'Food', 'Gifts'];

  String _selectedCategory = 'All';
  List<Product> _products = [];
  final List<_CartItem> _cart = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final orderService = ref.read(orderServiceProvider);
    final category =
        _selectedCategory == 'All' ? null : _selectedCategory.toLowerCase();
    final products = await orderService.getProducts(category: category);
    if (!mounted) return;
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.indexWhere((c) => c.product.id == product.id);
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(_CartItem(product: product));
      }
    });
  }

  int get _totalCartItems =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(
        title: const Text('Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, size: 22),
            onPressed: () => context.go('/orders/history'),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                onPressed: () => context.go('/orders/cart'),
              ),
              if (_totalCartItems > 0)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_totalCartItems',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CoreSyncColors.bg,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CoreSyncColors.accent,
                      strokeWidth: 1.5,
                    ),
                  )
                : _products.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: CoreSyncColors.accent,
                        backgroundColor: CoreSyncColors.surface,
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) =>
                              _ProductCard(
                                product: _products[index],
                                cartQty: _cartQtyFor(_products[index].id),
                                onAdd: () => _addToCart(_products[index]),
                              ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  int _cartQtyFor(int productId) {
    final idx = _cart.indexWhere((c) => c.product.id == productId);
    return idx >= 0 ? _cart[idx].quantity : 0;
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
              _loadProducts();
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? CoreSyncColors.accent : CoreSyncColors.glass,
                borderRadius: BorderRadius.circular(24),
                border: selected
                    ? null
                    : Border.all(color: CoreSyncColors.glassBorder),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? CoreSyncColors.bg : CoreSyncColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.room_service_outlined,
            size: 48,
            color: CoreSyncColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No products available',
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final int cartQty;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.cartQty,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CoreSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.accent,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: Material(
                      color: cartQty > 0
                          ? CoreSyncColors.accent
                          : CoreSyncColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onAdd,
                        child: Center(
                          child: Text(
                            cartQty > 0 ? 'Added ($cartQty)' : 'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cartQty > 0
                                  ? CoreSyncColors.bg
                                  : CoreSyncColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: CoreSyncColors.surface,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: CoreSyncColors.textMuted,
        ),
      ),
    );
  }
}

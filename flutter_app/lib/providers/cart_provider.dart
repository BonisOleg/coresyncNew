import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product) {
    final idx = state.indexWhere((c) => c.product.id == product.id);
    if (idx >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) state[i].copyWith(quantity: state[i].quantity + 1)
          else state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void increment(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(quantity: state[i].quantity + 1)
        else state[i],
    ];
  }

  void decrement(int index) {
    if (state[index].quantity > 1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(quantity: state[i].quantity - 1)
          else state[i],
      ];
    } else {
      removeItem(index);
    }
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
  }

  void clear() {
    state = [];
  }

  int totalItems() {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  int quantityFor(int productId) {
    final idx = state.indexWhere((c) => c.product.id == productId);
    return idx >= 0 ? state[idx].quantity : 0;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

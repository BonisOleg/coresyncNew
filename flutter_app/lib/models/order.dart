import 'product.dart';

class OrderItem {
  final int id;
  final Product product;
  final int quantity;
  final String unitPrice;
  final String subtotal;

  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: json['unit_price']?.toString() ?? '0.00',
      subtotal: json['subtotal']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class Order {
  final int id;
  final int bookingId;
  final String status;
  final String totalAmount;
  final String message;
  final String notes;
  final List<OrderItem> items;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.totalAmount,
    required this.message,
    required this.notes,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int? ?? json['booking'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0.00',
      message: json['message'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'status': status,
      'total_amount': totalAmount,
      'message': message,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

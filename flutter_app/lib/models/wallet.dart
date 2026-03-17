class WalletBalance {
  final int id;
  final String balance;
  final String currency;
  final int? defaultPaymentMethod;

  const WalletBalance({
    required this.id,
    required this.balance,
    required this.currency,
    this.defaultPaymentMethod,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      id: json['id'] as int,
      balance: json['balance']?.toString() ?? '0.00',
      currency: json['currency'] as String? ?? 'EUR',
      defaultPaymentMethod: json['default_payment_method'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'currency': currency,
      'default_payment_method': defaultPaymentMethod,
    };
  }
}

class PaymentMethod {
  final int id;
  final String stripePaymentMethodId;
  final String cardBrand;
  final String cardLast4;
  final String type;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.stripePaymentMethodId,
    required this.cardBrand,
    required this.cardLast4,
    required this.type,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      stripePaymentMethodId:
          json['stripe_payment_method_id'] as String? ?? '',
      cardBrand: json['card_brand'] as String? ?? '',
      cardLast4: json['card_last4'] as String? ?? '',
      type: json['type'] as String? ?? 'card',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stripe_payment_method_id': stripePaymentMethodId,
      'card_brand': cardBrand,
      'card_last4': cardLast4,
      'type': type,
      'is_default': isDefault,
    };
  }
}

class Transaction {
  final int id;
  final String type;
  final String amount;
  final String balanceAfter;
  final String description;
  final int? orderId;
  final int? bookingId;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.orderId,
    this.bookingId,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      balanceAfter: json['balance_after']?.toString() ?? '0.00',
      description: json['description'] as String? ?? '',
      orderId: json['order_id'] as int?,
      bookingId: json['booking_id'] as int?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'balance_after': balanceAfter,
      'description': description,
      'order_id': orderId,
      'booking_id': bookingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

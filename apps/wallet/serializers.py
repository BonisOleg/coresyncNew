"""Serializers for wallet, payment methods, and transactions."""

from __future__ import annotations

from decimal import Decimal

from rest_framework import serializers

from .models import PaymentMethod, Transaction, WalletBalance


class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = ("id", "stripe_payment_method_id", "card_brand", "card_last4", "type", "is_default", "created_at")
        read_only_fields = ("id", "created_at")


class WalletBalanceSerializer(serializers.ModelSerializer):
    default_payment_method = serializers.SerializerMethodField()

    class Meta:
        model = WalletBalance
        fields = ("id", "balance", "currency", "default_payment_method", "updated_at")

    def get_default_payment_method(self, obj: WalletBalance) -> dict | None:
        pm = PaymentMethod.objects.filter(guest=obj.guest, is_default=True).first()
        if pm:
            return PaymentMethodSerializer(pm).data
        return None


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = (
            "id", "type", "amount", "balance_after", "description",
            "stripe_payment_intent_id", "order", "booking", "created_at",
        )


class SetupIntentSerializer(serializers.Serializer):
    client_secret = serializers.CharField(read_only=True)
    customer_id = serializers.CharField(read_only=True)


class TopUpSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal("1.00"))
    payment_method_id = serializers.CharField()


class WalletPaySerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal("0.01"))
    description = serializers.CharField(required=False, default="")
    order_id = serializers.UUIDField(required=False, allow_null=True, default=None)
    booking_id = serializers.UUIDField(required=False, allow_null=True, default=None)


class SavePaymentMethodSerializer(serializers.Serializer):
    stripe_payment_method_id = serializers.CharField()

"""Serializers for orders and products."""

from __future__ import annotations

from rest_framework import serializers

from .models import Order, OrderItem, Product


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ("id", "name", "description", "price", "category", "image_url", "is_available", "order")


class OrderItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = OrderItem
        fields = ("id", "product", "quantity", "unit_price", "subtotal")


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = (
            "id", "booking", "status", "total_amount",
            "message", "notes", "items", "created_at", "updated_at",
        )
        read_only_fields = ("id", "total_amount", "created_at", "updated_at")


class OrderItemCreateSerializer(serializers.Serializer):
    product_id = serializers.UUIDField()
    quantity = serializers.IntegerField(min_value=1, default=1)


class OrderCreateSerializer(serializers.Serializer):
    items = OrderItemCreateSerializer(many=True, min_length=1)
    message = serializers.CharField(required=False, default="", allow_blank=True)
    booking_id = serializers.UUIDField(required=False, allow_null=True, default=None)

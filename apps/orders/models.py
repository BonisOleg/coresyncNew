"""
Order system for in-room add-ons (drinks, flowers, food, gifts).
All items are physical goods delivered to the guest's room.
"""

from __future__ import annotations

import uuid
from decimal import Decimal

from django.db import models


class Product(models.Model):
    """A purchasable physical add-on (whiskey, flowers, etc.)."""

    class Category(models.TextChoices):
        DRINKS = "drinks", "Drinks"
        FLOWERS = "flowers", "Flowers"
        FOOD = "food", "Food"
        GIFTS = "gifts", "Gifts"
        OTHER = "other", "Other"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.OTHER)
    image_url = models.URLField(max_length=500, blank=True, default="")
    is_available = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["category", "order", "name"]

    def __str__(self) -> str:
        return f"{self.name} — ${self.price}"


class Order(models.Model):
    """A guest's order for physical add-ons."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"
        DELIVERED = "delivered", "Delivered"
        CANCELLED = "cancelled", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey("guests.Guest", on_delete=models.CASCADE, related_name="orders")
    booking = models.ForeignKey(
        "bookings.Booking",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="orders",
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0.00"))
    message = models.TextField(blank=True, default="", help_text="Personal message (e.g. 'Happy Birthday!')")
    notes = models.TextField(blank=True, default="")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Order {self.id!s:.8} — {self.guest} (${self.total_amount})"

    def recalculate_total(self) -> None:
        self.total_amount = sum(
            item.subtotal for item in self.items.all()
        )
        self.save(update_fields=["total_amount"])


class OrderItem(models.Model):
    """A line item within an order."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="order_items")
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["product__name"]

    def __str__(self) -> str:
        return f"{self.product.name} x{self.quantity}"

    @property
    def subtotal(self) -> Decimal:
        return self.unit_price * self.quantity

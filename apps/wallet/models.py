"""
Payment wallet — prepaid balance for physical spa services.
Stripe integration for saved cards, Apple Pay, Google Pay.
"""

from __future__ import annotations

import uuid
from decimal import Decimal

from django.db import models


class StripeCustomer(models.Model):
    """Links a Guest to their Stripe Customer record."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.OneToOneField("guests.Guest", on_delete=models.CASCADE, related_name="stripe_customer")
    stripe_customer_id = models.CharField(max_length=255, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"{self.guest} — {self.stripe_customer_id}"


class PaymentMethod(models.Model):
    """A saved payment method (card / Apple Pay / Google Pay)."""

    class Type(models.TextChoices):
        CARD = "card", "Card"
        APPLE_PAY = "apple_pay", "Apple Pay"
        GOOGLE_PAY = "google_pay", "Google Pay"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey("guests.Guest", on_delete=models.CASCADE, related_name="payment_methods")
    stripe_payment_method_id = models.CharField(max_length=255, unique=True)
    card_brand = models.CharField(max_length=50, blank=True, default="")
    card_last4 = models.CharField(max_length=4, blank=True, default="")
    type = models.CharField(max_length=20, choices=Type.choices, default=Type.CARD)
    is_default = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_default", "-created_at"]

    def __str__(self) -> str:
        label = f"{self.card_brand} ****{self.card_last4}" if self.card_last4 else self.type
        return f"{self.guest} — {label}"


class WalletBalance(models.Model):
    """Prepaid balance for spa services (physical goods and services only)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.OneToOneField("guests.Guest", on_delete=models.CASCADE, related_name="wallet")
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0.00"))
    currency = models.CharField(max_length=3, default="USD")
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"{self.guest} — {self.currency} {self.balance}"


class Transaction(models.Model):
    """Wallet transaction log."""

    class Type(models.TextChoices):
        TOP_UP = "top_up", "Top Up"
        PAYMENT = "payment", "Payment"
        REFUND = "refund", "Refund"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey("guests.Guest", on_delete=models.CASCADE, related_name="transactions")
    type = models.CharField(max_length=20, choices=Type.choices)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    balance_after = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.CharField(max_length=255, blank=True, default="")
    stripe_payment_intent_id = models.CharField(max_length=255, blank=True, default="")
    order = models.ForeignKey(
        "orders.Order", on_delete=models.SET_NULL, null=True, blank=True, related_name="transactions",
    )
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.SET_NULL, null=True, blank=True, related_name="transactions",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.type} {self.amount} — {self.guest}"

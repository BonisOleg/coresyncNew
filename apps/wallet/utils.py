"""Stripe helpers for the wallet app."""

from __future__ import annotations

from typing import TYPE_CHECKING

import stripe
from django.conf import settings

from .models import StripeCustomer

if TYPE_CHECKING:
    from apps.guests.models import Guest

stripe.api_key = settings.STRIPE_SECRET_KEY


def get_or_create_stripe_customer(guest: Guest) -> str:
    """Return the Stripe Customer ID for a guest, creating one if needed."""
    try:
        sc = guest.stripe_customer
        return sc.stripe_customer_id
    except StripeCustomer.DoesNotExist:
        pass

    customer = stripe.Customer.create(
        phone=guest.phone,
        email=guest.email or None,
        name=guest.full_name or None,
        metadata={"guest_id": str(guest.id)},
    )

    StripeCustomer.objects.create(guest=guest, stripe_customer_id=customer.id)
    return customer.id

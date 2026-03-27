"""
Stripe helpers for concierge booking payments.
Reuses the wallet app's customer management.
"""

from __future__ import annotations

import logging
from typing import Any, TYPE_CHECKING

import stripe
from django.conf import settings

from apps.wallet.utils import get_or_create_stripe_customer

if TYPE_CHECKING:
    from apps.guests.models import Guest

stripe.api_key = settings.STRIPE_SECRET_KEY
logger = logging.getLogger(__name__)


def create_booking_payment_intent(
    guest: Guest,
    amount: int,
    booking_id: str,
) -> dict[str, Any]:
    """
    Create a Stripe PaymentIntent for a booking.
    Amount is in dollars — converted to cents for Stripe.
    """
    customer_id = get_or_create_stripe_customer(guest)

    intent = stripe.PaymentIntent.create(
        amount=amount * 100,
        currency="usd",
        customer=customer_id,
        metadata={
            "booking_id": booking_id,
            "guest_id": str(guest.id),
            "type": "booking",
        },
        automatic_payment_methods={"enabled": True},
    )

    logger.info(
        "Created PaymentIntent %s for booking %s ($%s)",
        intent.id, booking_id, amount,
    )

    return {
        "id": intent.id,
        "client_secret": intent.client_secret,
        "amount": amount,
    }


def create_membership_payment_intent(
    guest: Guest,
    amount: int,
    guest_membership_id: str,
) -> dict[str, Any]:
    """
    Create a Stripe PaymentIntent for a membership activation.
    Amount is in dollars — converted to cents for Stripe.
    """
    customer_id = get_or_create_stripe_customer(guest)

    intent = stripe.PaymentIntent.create(
        amount=amount * 100,
        currency="usd",
        customer=customer_id,
        metadata={
            "guest_membership_id": guest_membership_id,
            "guest_id": str(guest.id),
            "type": "membership",
        },
        automatic_payment_methods={"enabled": True},
    )

    logger.info(
        "Created PaymentIntent %s for membership %s ($%s)",
        intent.id, guest_membership_id, amount,
    )

    return {
        "id": intent.id,
        "client_secret": intent.client_secret,
        "amount": amount,
    }


def confirm_booking_payment(payment_intent_id: str) -> bool:
    """Check whether a PaymentIntent has succeeded."""
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        return intent.status == "succeeded"
    except stripe.error.StripeError as exc:
        logger.warning("Failed to verify PaymentIntent %s: %s", payment_intent_id, exc)
        return False

"""
Stripe webhook handler for booking payment events.
Verifies webhook signature and processes payment_intent events.
"""

from __future__ import annotations

import logging

import stripe
from django.conf import settings
from django.http import HttpRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from .models import Booking

logger = logging.getLogger(__name__)

stripe.api_key = settings.STRIPE_SECRET_KEY


@csrf_exempt
@require_POST
def stripe_webhook(request: HttpRequest) -> HttpResponse:
    """Handle Stripe webhook events for booking payments."""
    payload = request.body
    sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
    webhook_secret = settings.STRIPE_WEBHOOK_SECRET

    if not webhook_secret:
        logger.warning("STRIPE_WEBHOOK_SECRET not configured — rejecting webhook")
        return HttpResponse("Webhook secret not configured", status=500)

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
    except ValueError:
        logger.warning("Invalid Stripe webhook payload")
        return HttpResponse("Invalid payload", status=400)
    except stripe.error.SignatureVerificationError:
        logger.warning("Invalid Stripe webhook signature")
        return HttpResponse("Invalid signature", status=400)

    event_type = event.get("type", "")
    data_object = event.get("data", {}).get("object", {})

    if event_type == "payment_intent.succeeded":
        _handle_payment_succeeded(data_object)
    elif event_type == "payment_intent.payment_failed":
        _handle_payment_failed(data_object)

    return HttpResponse("OK", status=200)


def _handle_payment_succeeded(payment_intent: dict) -> None:
    """Confirm booking after successful payment."""
    booking_id = payment_intent.get("metadata", {}).get("booking_id")
    pi_id = payment_intent.get("id", "")

    if not booking_id:
        logger.warning("payment_intent.succeeded without booking_id in metadata: %s", pi_id)
        return

    try:
        booking = Booking.objects.get(id=booking_id)
    except Booking.DoesNotExist:
        logger.error("Booking %s not found for PaymentIntent %s", booking_id, pi_id)
        return

    if booking.payment_status == Booking.PaymentStatus.PAID:
        logger.info("Booking %s already marked as paid", booking_id)
        return

    booking.payment_status = Booking.PaymentStatus.PAID
    booking.status = Booking.Status.CONFIRMED
    if not booking.confirmation_number:
        booking.generate_confirmation_number()
    booking.save(update_fields=["payment_status", "status", "confirmation_number"])

    logger.info("Booking %s confirmed via Stripe webhook (PI: %s)", booking_id, pi_id)


def _handle_payment_failed(payment_intent: dict) -> None:
    """Cancel booking after failed payment."""
    booking_id = payment_intent.get("metadata", {}).get("booking_id")
    pi_id = payment_intent.get("id", "")

    if not booking_id:
        logger.warning("payment_intent.payment_failed without booking_id: %s", pi_id)
        return

    try:
        booking = Booking.objects.get(id=booking_id)
    except Booking.DoesNotExist:
        logger.error("Booking %s not found for failed PaymentIntent %s", booking_id, pi_id)
        return

    if booking.status == Booking.Status.CANCELLED:
        return

    booking.status = Booking.Status.CANCELLED
    booking.notes += f"\nPayment failed (PI: {pi_id})"
    booking.save(update_fields=["status", "notes"])

    logger.warning("Booking %s cancelled due to payment failure (PI: %s)", booking_id, pi_id)

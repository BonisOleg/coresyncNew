"""
SMS utilities for the concierge booking flow.
Uses Twilio for delivery; falls back to logging in dev.
"""

from __future__ import annotations

import logging
import random
from datetime import timedelta
from typing import TYPE_CHECKING

from django.conf import settings
from django.utils import timezone

if TYPE_CHECKING:
    from apps.bookings.models import Booking
    from apps.guests.models import Guest

logger = logging.getLogger(__name__)


def _get_twilio_client():
    """Lazy-load the Twilio client only when actually sending."""
    try:
        from twilio.rest import Client

        sid = getattr(settings, "TWILIO_ACCOUNT_SID", "")
        token = getattr(settings, "TWILIO_AUTH_TOKEN", "")
        if not sid or not token:
            return None
        return Client(sid, token)
    except ImportError:
        logger.warning("twilio package not installed — SMS will be logged only")
        return None


def _send_sms(to: str, body: str) -> bool:
    """Send an SMS via Twilio or log it in dev."""
    client = _get_twilio_client()
    from_number = getattr(settings, "TWILIO_PHONE_NUMBER", "")

    if not client or not from_number:
        logger.info("SMS (dev fallback) to %s: %s", to, body)
        return True

    try:
        message = client.messages.create(
            body=body,
            from_=from_number,
            to=to,
        )
        logger.info("SMS sent to %s: sid=%s", to, message.sid)
        return True
    except Exception as exc:
        logger.error("SMS send failed to %s: %s", to, exc)
        return False


def send_otp(guest: Guest) -> str:
    """Generate a 6-digit OTP, save to guest, and send via SMS."""
    code = f"{random.randint(100000, 999999)}"
    guest.otp_code = code
    guest.otp_expires_at = timezone.now() + timedelta(minutes=10)
    guest.save(update_fields=["otp_code", "otp_expires_at"])

    _send_sms(
        guest.phone,
        f"Your CoreSync verification code is {code}. It expires in 10 minutes.",
    )
    return code


def send_booking_confirmation(guest: Guest, booking: Booking) -> bool:
    """Send a booking confirmation SMS."""
    date_str = booking.date.strftime("%B %d, %Y")
    time_str = booking.time_start.strftime("%-I:%M %p")

    return _send_sms(
        guest.phone,
        (
            f"Your CoreSync Private session is confirmed.\n"
            f"Date: {date_str}\n"
            f"Time: {time_str}\n"
            f"Confirmation: {booking.confirmation_number}\n\n"
            f"We look forward to welcoming you."
        ),
    )


def send_pre_session_reminder(guest: Guest, booking: Booking) -> bool:
    """Send a pre-session SMS 1-2 hours before the session."""
    site_url = getattr(settings, "SITE_URL", "https://coresync.com")

    return _send_sms(
        guest.phone,
        (
            f"Your CoreSync session begins soon.\n"
            f"Would you like to set your environment?\n\n"
            f"{site_url}?context=pre_session"
        ),
    )

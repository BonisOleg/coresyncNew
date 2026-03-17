"""
SMS helpers called from the booking flow steps.
Thin wrappers around the main sms module.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from apps.guests.models import Guest


def send_booking_otp(guest: Guest) -> str:
    """Send OTP during booking flow."""
    from apps.concierge.sms import send_otp

    return send_otp(guest)
